import * as functions from "firebase-functions/v2/https";
import * as scheduler from "firebase-functions/v2/scheduler";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions/v2";
import * as admin from "firebase-admin";
import axios from "axios";

admin.initializeApp();

const GROQ_BASE_URL = "https://api.groq.com/openai/v1/chat/completions";
const DEFAULT_MODEL = "llama-3.1-8b-instant";
const ALLOWED_MODELS = new Set([DEFAULT_MODEL]);
const MAX_PROMPT_CHARS = 6000;
const MAX_MESSAGES = 40;
const MAX_MESSAGE_CHARS = 4000;
const RATE_LIMIT_WINDOW_MS = 60_000;
const RATE_LIMIT_MAX_CALLS = 20;

function resolveModel(requested?: string): string {
  if (!requested || !ALLOWED_MODELS.has(requested)) {
    return DEFAULT_MODEL;
  }
  return requested;
}

const XP_RATE_LIMIT_MAX = 30;
const JOIN_RATE_LIMIT_MAX = 10;
const ACTION_RATE_WINDOW_MS = 60_000;

/** Generic per-user action rate limit (Firestore). */
async function assertActionRateLimit(
  uid: string,
  action: string,
  maxCalls: number,
  windowMs: number = ACTION_RATE_WINDOW_MS
): Promise<void> {
  const ref = admin.firestore().collection("action_rate_limits").doc(`${uid}_${action}`);
  const now = Date.now();
  await admin.firestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.data();
    let windowStart = typeof data?.windowStart === "number" ? data.windowStart : now;
    let count = typeof data?.count === "number" ? data.count : 0;
    if (now - windowStart >= windowMs) {
      windowStart = now;
      count = 0;
    }
    if (count >= maxCalls) {
      throw new functions.HttpsError(
        "resource-exhausted",
        "Çok fazla istek. Lütfen biraz bekleyin."
      );
    }
    tx.set(
      ref,
      { windowStart, count: count + 1, updatedAt: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true }
    );
  });
}

/** Durable per-user rate limit (Firestore), survives cold starts. */
async function assertRateLimit(uid: string): Promise<void> {
  const ref = admin.firestore().collection("nova_rate_limits").doc(uid);
  const now = Date.now();
  await admin.firestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.data();
    let windowStart = typeof data?.windowStart === "number" ? data.windowStart : now;
    let count = typeof data?.count === "number" ? data.count : 0;
    if (now - windowStart >= RATE_LIMIT_WINDOW_MS) {
      windowStart = now;
      count = 0;
    }
    if (count >= RATE_LIMIT_MAX_CALLS) {
      throw new functions.HttpsError(
        "resource-exhausted",
        "Çok fazla istek gönderildi. Lütfen biraz bekleyin."
      );
    }
    tx.set(
      ref,
      { windowStart, count: count + 1, updatedAt: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true }
    );
  });
}

function validateMessages(messages: unknown): asserts messages is Array<Record<string, unknown>> {
  if (!Array.isArray(messages) || messages.length === 0) {
    throw new functions.HttpsError("invalid-argument", "messages gerekli.");
  }
  if (messages.length > MAX_MESSAGES) {
    throw new functions.HttpsError("invalid-argument", "Mesaj sayısı limiti aşıldı.");
  }

  for (const m of messages) {
    const content = typeof m?.content === "string" ? m.content : "";
    if (content.length > MAX_MESSAGE_CHARS) {
      throw new functions.HttpsError("invalid-argument", "Mesaj içeriği çok uzun.");
    }
  }
}

/**
 * Fetches the Groq API key from Firestore (server-side only).
 * The key is stored in 'config/nova' and is NEVER exposed to clients.
 */
async function fetchApiKey(): Promise<string | null> {
  try {
    const doc = await admin
      .firestore()
      .collection("config")
      .doc("nova")
      .get();
    if (!doc.exists) return null;
    const data = doc.data()!;
    return (data["groq_api_key"] ?? data["gemini_api_key"] ?? null) as string | null;
  } catch (e) {
    logger.error("[nova_proxy] fetchApiKey error:", e);
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// novaChat: Authenticated HTTPS callable.
// Receives the chat messages + tools from the client, calls Groq on
// the server side, and returns the raw response. The API key never
// leaves the server.
// ─────────────────────────────────────────────────────────────────────────────
export const novaChat = functions.onCall(
  { region: "europe-west1", cors: true },
  async (request) => {
    // ── Auth guard ────────────────────────────────────────────────────────────
    if (!request.auth) {
      throw new functions.HttpsError(
        "unauthenticated",
        "Bu işlem için giriş yapmanız gerekiyor."
      );
    }

    await assertRateLimit(request.auth.uid);

    const { messages, tools, temperature = 0.9, model: requestedModel } =
      request.data as {
        messages: object[];
        tools?: object[];
        temperature?: number;
        model?: string;
      };
    const model = resolveModel(requestedModel);

    validateMessages(messages);

    if (tools != null) {
      if (!Array.isArray(tools) || tools.length > 24) {
        throw new functions.HttpsError(
          "invalid-argument",
          "Araç listesi geçersiz."
        );
      }
    }

    // ── Fetch API key (server-side) ───────────────────────────────────────────
    const apiKey = await fetchApiKey();
    if (!apiKey) {
      throw new functions.HttpsError(
        "not-found",
        "Nova API anahtarı yapılandırılmamış."
      );
    }

    // ── Call Groq ─────────────────────────────────────────────────────────────
    const safeTemp =
      typeof temperature === "number"
        ? Math.min(1.5, Math.max(0, temperature))
        : 0.9;
    const body: Record<string, unknown> = { model, messages, temperature: safeTemp };
    if (tools && tools.length > 0) {
      body.tools = tools;
      body.tool_choice = "auto";
    }

    try {
      const response = await axios.post(GROQ_BASE_URL, body, {
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${apiKey}`,
        },
        timeout: 30_000,
      });
      return response.data;
    } catch (e: unknown) {
      if (axios.isAxiosError(e)) {
        logger.error("[nova_proxy] Groq error:", e.response?.data);
        throw new functions.HttpsError(
          "internal",
          `Groq API hatası: ${e.response?.status ?? "unknown"}`
        );
      }
      throw new functions.HttpsError("internal", "Bilinmeyen hata.");
    }
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// novaSimplePrompt: Single-turn text prompt (for createTaskFromText, etc.)
// ─────────────────────────────────────────────────────────────────────────────
export const novaSimplePrompt = functions.onCall(
  { region: "europe-west1", cors: true },
  async (request) => {
    if (!request.auth) {
      throw new functions.HttpsError("unauthenticated", "Giriş gerekli.");
    }
    await assertRateLimit(request.auth.uid);

    const { prompt, temperature = 0.7, model: requestedModel } =
      request.data as { prompt: string; temperature?: number; model?: string };
    const model = resolveModel(requestedModel);

    if (!prompt) {
      throw new functions.HttpsError("invalid-argument", "prompt gerekli.");
    }
    if (prompt.length > MAX_PROMPT_CHARS) {
      throw new functions.HttpsError("invalid-argument", "Prompt çok uzun.");
    }

    const apiKey = await fetchApiKey();
    if (!apiKey) {
      throw new functions.HttpsError("not-found", "API anahtarı yok.");
    }

    const safeTemp =
      typeof temperature === "number"
        ? Math.min(1.5, Math.max(0, temperature))
        : 0.7;

    try {
      const response = await axios.post(
        GROQ_BASE_URL,
        {
          model,
          messages: [{ role: "user", content: prompt }],
          temperature: safeTemp,
        },
        {
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${apiKey}`,
          },
          timeout: 30_000,
        }
      );
      const content: string =
        response.data?.choices?.[0]?.message?.content ?? "";
      return { content };
    } catch (e: unknown) {
      if (axios.isAxiosError(e)) {
        throw new functions.HttpsError(
          "internal",
          `Groq hatası: ${e.response?.status ?? "unknown"}`
        );
      }
      throw new functions.HttpsError("internal", "Bilinmeyen hata.");
    }
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// purgeDeletedNotes — Scheduled Cloud Function (runs daily at 03:00 UTC).
// Permanently deletes notes soft-deleted more than 30 days ago.
// ─────────────────────────────────────────────────────────────────────────────
const MAX_XP_PER_CALL = 500;
const JOIN_CODE_MIN_LEN = 6;
const JOIN_CODE_MAX_LEN = 12;

// ─────────────────────────────────────────────────────────────────────────────
// addUserXp — Server-side XP/level updates (clients cannot write xp/level).
// ─────────────────────────────────────────────────────────────────────────────
export const addUserXp = functions.onCall(
  { region: "europe-west1", cors: true },
  async (request) => {
    if (!request.auth) {
      throw new functions.HttpsError("unauthenticated", "Giriş gerekli.");
    }
    await assertActionRateLimit(request.auth.uid, "addUserXp", XP_RATE_LIMIT_MAX);
    const { amount, taskId, reason } = request.data as {
      amount?: number;
      taskId?: string;
      reason?: string;
    };
    if (typeof amount !== "number" || !Number.isFinite(amount) || amount <= 0) {
      throw new functions.HttpsError("invalid-argument", "Geçersiz XP miktarı.");
    }

    const uid = request.auth.uid;
    const userRef = admin.firestore().collection("users").doc(uid);
    let newLevel = 1;

    if (reason === "task_complete" && typeof taskId === "string" && taskId.length > 0) {
      if (amount > 50) {
        throw new functions.HttpsError(
          "invalid-argument",
          "Görev tamamlama başına en fazla 50 XP."
        );
      }
      await admin.firestore().runTransaction(async (tx) => {
        const taskRef = admin.firestore().collection("tasks").doc(taskId);
        const taskSnap = await tx.get(taskRef);
        if (!taskSnap.exists) {
          throw new functions.HttpsError("not-found", "Görev bulunamadı.");
        }
        const task = taskSnap.data() ?? {};
        if (task.userId !== uid) {
          throw new functions.HttpsError("permission-denied", "Bu görev size ait değil.");
        }
        if (task.isCompleted !== true && task.status !== "done") {
          throw new functions.HttpsError(
            "failed-precondition",
            "Görev tamamlanmadan XP verilemez."
          );
        }
        if (task.xpGranted === true) {
          const userSnap = await tx.get(userRef);
          const data = userSnap.data() ?? {};
          newLevel = Math.floor(((data.xp as number) ?? 0) / 1000) + 1;
          return;
        }
        const userSnap = await tx.get(userRef);
        if (!userSnap.exists) {
          throw new functions.HttpsError("not-found", "Kullanıcı bulunamadı.");
        }
        const data = userSnap.data() ?? {};
        const currentXp = typeof data.xp === "number" ? data.xp : 0;
        const newXp = currentXp + amount;
        newLevel = Math.floor(newXp / 1000) + 1;
        tx.update(userRef, { xp: newXp, level: newLevel });
        tx.update(taskRef, { xpGranted: true });
      });
      return { level: newLevel };
    }

    if (amount > MAX_XP_PER_CALL) {
      throw new functions.HttpsError(
        "invalid-argument",
        `Tek seferde en fazla ${MAX_XP_PER_CALL} XP eklenebilir.`
      );
    }
    if (amount > 100 && reason !== "focus_complete") {
      throw new functions.HttpsError(
        "invalid-argument",
        "Bu işlem için XP limiti aşıldı."
      );
    }

    await admin.firestore().runTransaction(async (tx) => {
      const snap = await tx.get(userRef);
      if (!snap.exists) {
        throw new functions.HttpsError("not-found", "Kullanıcı bulunamadı.");
      }
      const data = snap.data() ?? {};
      const currentXp = typeof data.xp === "number" ? data.xp : 0;
      const newXp = currentXp + amount;
      newLevel = Math.floor(newXp / 1000) + 1;
      tx.update(userRef, { xp: newXp, level: newLevel });
    });

    return { level: newLevel };
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// joinTeamByCode — Join a team using a join code (Admin SDK bypasses read rules).
// ─────────────────────────────────────────────────────────────────────────────
export const joinTeamByCode = functions.onCall(
  { region: "europe-west1", cors: true },
  async (request) => {
    if (!request.auth) {
      throw new functions.HttpsError("unauthenticated", "Giriş gerekli.");
    }
    await assertActionRateLimit(request.auth.uid, "joinTeamByCode", JOIN_RATE_LIMIT_MAX);
    const { code } = request.data as { code?: string };
    const normalized = (code ?? "").trim().toUpperCase();
    if (
      normalized.length < JOIN_CODE_MIN_LEN ||
      normalized.length > JOIN_CODE_MAX_LEN
    ) {
      throw new functions.HttpsError("invalid-argument", "Geçersiz katılım kodu.");
    }

    const uid = request.auth.uid;
    const db = admin.firestore();
    const teams = await db
      .collection("teams")
      .where("joinCode", "==", normalized)
      .limit(1)
      .get();

    if (teams.empty) {
      throw new functions.HttpsError("not-found", "Kod geçersiz veya süresi dolmuş.");
    }

    const teamDoc = teams.docs[0];
    const teamId = teamDoc.id;
    const memberIds: string[] = teamDoc.data().memberIds ?? [];
    if (memberIds.includes(uid)) {
      return { teamId, alreadyMember: true };
    }

    await db.runTransaction(async (tx) => {
      const teamRef = teamDoc.ref;
      const userRef = db.collection("users").doc(uid);
      tx.update(teamRef, {
        memberIds: admin.firestore.FieldValue.arrayUnion(uid),
      });
      tx.set(
        userRef,
        { joinedTeams: admin.firestore.FieldValue.arrayUnion(teamId) },
        { merge: true }
      );
    });

    return { teamId, alreadyMember: false };
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// kickTeamMember — Remove member; syncs victim joinedTeams via Admin SDK.
// ─────────────────────────────────────────────────────────────────────────────
export const kickTeamMember = functions.onCall(
  { region: "europe-west1", cors: true },
  async (request) => {
    if (!request.auth) {
      throw new functions.HttpsError("unauthenticated", "Giriş gerekli.");
    }
    const { teamId, memberId } = request.data as {
      teamId?: string;
      memberId?: string;
    };
    if (!teamId || !memberId) {
      throw new functions.HttpsError("invalid-argument", "teamId ve memberId gerekli.");
    }

    const uid = request.auth.uid;
    const db = admin.firestore();
    const teamRef = db.collection("teams").doc(teamId);
    const teamSnap = await teamRef.get();
    if (!teamSnap.exists) {
      throw new functions.HttpsError("not-found", "Takım bulunamadı.");
    }
    const team = teamSnap.data()!;
    const isOwner = team.ownerId === uid;
    const isAdmin =
      Array.isArray(team.adminIds) && team.adminIds.includes(uid);
    if (!isOwner && !isAdmin) {
      throw new functions.HttpsError(
        "permission-denied",
        "Bu işlem için takım yöneticisi olmalısınız."
      );
    }
    if (memberId === team.ownerId) {
      throw new functions.HttpsError(
        "failed-precondition",
        "Takım sahibi çıkarılamaz."
      );
    }

    await db.runTransaction(async (tx) => {
      tx.update(teamRef, {
        memberIds: admin.firestore.FieldValue.arrayRemove(memberId),
        adminIds: admin.firestore.FieldValue.arrayRemove(memberId),
      });
      tx.set(
        db.collection("users").doc(memberId),
        { joinedTeams: admin.firestore.FieldValue.arrayRemove(teamId) },
        { merge: true }
      );
    });

    return { ok: true };
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// leaveTeam — Member leaves team (syncs joinedTeams via Admin SDK).
// ─────────────────────────────────────────────────────────────────────────────
export const leaveTeam = functions.onCall(
  { region: "europe-west1", cors: true },
  async (request) => {
    if (!request.auth) {
      throw new functions.HttpsError("unauthenticated", "Giriş gerekli.");
    }
    const { teamId } = request.data as { teamId?: string };
    if (!teamId) {
      throw new functions.HttpsError("invalid-argument", "teamId gerekli.");
    }

    const uid = request.auth.uid;
    const db = admin.firestore();
    const teamRef = db.collection("teams").doc(teamId);
    const teamSnap = await teamRef.get();
    if (!teamSnap.exists) {
      throw new functions.HttpsError("not-found", "Takım bulunamadı.");
    }
    const team = teamSnap.data()!;
    if (team.ownerId === uid) {
      throw new functions.HttpsError(
        "failed-precondition",
        "Takım sahibi ayrılamaz. Önce sahipliği devredin veya takımı silin."
      );
    }
    const memberIds: string[] = team.memberIds ?? [];
    if (!memberIds.includes(uid)) {
      return { ok: true, alreadyLeft: true };
    }

    await db.runTransaction(async (tx) => {
      tx.update(teamRef, {
        memberIds: admin.firestore.FieldValue.arrayRemove(uid),
        adminIds: admin.firestore.FieldValue.arrayRemove(uid),
      });
      tx.set(
        db.collection("users").doc(uid),
        { joinedTeams: admin.firestore.FieldValue.arrayRemove(teamId) },
        { merge: true }
      );
    });

    return { ok: true, alreadyLeft: false };
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// fetchTeamMemberProfiles — Team-scoped public profile fields for UI.
// ─────────────────────────────────────────────────────────────────────────────
export const fetchTeamMemberProfiles = functions.onCall(
  { region: "europe-west1", cors: true },
  async (request) => {
    if (!request.auth) {
      throw new functions.HttpsError("unauthenticated", "Giriş gerekli.");
    }
    const { teamId, userIds } = request.data as {
      teamId?: string;
      userIds?: string[];
    };
    if (!teamId || !Array.isArray(userIds) || userIds.length === 0) {
      throw new functions.HttpsError("invalid-argument", "teamId ve userIds gerekli.");
    }
    if (userIds.length > 30) {
      throw new functions.HttpsError("invalid-argument", "En fazla 30 kullanıcı.");
    }

    const db = admin.firestore();
    const teamSnap = await db.collection("teams").doc(teamId).get();
    if (!teamSnap.exists) {
      throw new functions.HttpsError("not-found", "Takım bulunamadı.");
    }
    const members: string[] = teamSnap.data()?.memberIds ?? [];
    const uid = request.auth.uid;
    if (!members.includes(uid)) {
      throw new functions.HttpsError("permission-denied", "Takım üyesi değilsiniz.");
    }

    const profiles: Array<Record<string, unknown>> = [];
    for (const id of userIds) {
      if (!members.includes(id)) continue;
      const userSnap = await db.collection("users").doc(id).get();
      if (!userSnap.exists) continue;
      const d = userSnap.data() ?? {};
      profiles.push({
        id,
        name: d.name ?? "",
        surname: d.surname ?? "",
        email: d.email ?? "",
        photoUrl: d.photoUrl ?? null,
      });
    }
    return { profiles };
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// checkAccountAccess — Ban + blacklist gate at sign-in (fail-closed server check).
// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// backfillTeamTaskTeamIds — Adds teamId to legacy project-scoped tasks.
// ─────────────────────────────────────────────────────────────────────────────
export const backfillTeamTaskTeamIds = functions.onCall(
  { region: "europe-west1", cors: true },
  async (request) => {
    if (!request.auth) {
      throw new functions.HttpsError("unauthenticated", "Giriş gerekli.");
    }
    const { teamId } = request.data as { teamId?: string };
    if (!teamId) {
      throw new functions.HttpsError("invalid-argument", "teamId gerekli.");
    }

    const uid = request.auth.uid;
    const db = admin.firestore();
    const teamSnap = await db.collection("teams").doc(teamId).get();
    if (!teamSnap.exists) {
      throw new functions.HttpsError("not-found", "Takım bulunamadı.");
    }
    const team = teamSnap.data()!;
    const memberIds = team.memberIds as string[] | undefined;
    if (!Array.isArray(memberIds) || !memberIds.includes(uid)) {
      throw new functions.HttpsError("permission-denied", "Takım üyesi olmalısınız.");
    }

    const projects = await db
      .collection("teams")
      .doc(teamId)
      .collection("projects")
      .get();
    let updated = 0;
    for (const project of projects.docs) {
      const tasks = await db
        .collection("tasks")
        .where("groupId", "==", project.id)
        .get();
      let batch = db.batch();
      let ops = 0;
      for (const task of tasks.docs) {
        const data = task.data();
        const tid = data.teamId as string | undefined;
        const needsFix = !tid || tid !== teamId;
        if (!needsFix) continue;
        batch.update(task.ref, { teamId, groupId: project.id });
        updated++;
        ops++;
        if (ops >= 400) {
          await batch.commit();
          batch = db.batch();
          ops = 0;
        }
      }
      if (ops > 0) await batch.commit();
    }
    return { updated };
  }
);

export const checkAccountAccess = functions.onCall(
  { region: "europe-west1", cors: true },
  async (request) => {
    if (!request.auth) {
      throw new functions.HttpsError("unauthenticated", "Giriş gerekli.");
    }
    const uid = request.auth.uid;
    const email = (request.auth.token.email ?? "").toLowerCase();
    const db = admin.firestore();

    const userSnap = await db.collection("users").doc(uid).get();
    if (userSnap.exists && userSnap.data()?.banned === true) {
      return { allowed: false, reason: "banned" };
    }

    if (email) {
      const emailBan = await db
        .collection("blacklist")
        .where("type", "==", "email")
        .where("value", "==", email)
        .limit(1)
        .get();
      if (!emailBan.empty) return { allowed: false, reason: "blacklist" };
    }

    const uidBan = await db
      .collection("blacklist")
      .where("type", "==", "uid")
      .where("value", "==", uid)
      .limit(1)
      .get();
    if (!uidBan.empty) return { allowed: false, reason: "blacklist" };

    const raw = request.rawRequest;
    const forwarded = raw?.headers?.["x-forwarded-for"];
    const clientIp =
      (typeof forwarded === "string"
        ? forwarded.split(",")[0]?.trim()
        : Array.isArray(forwarded)
          ? String(forwarded[0] ?? "").split(",")[0]?.trim()
          : "") ||
      raw?.ip ||
      "";
    if (clientIp) {
      const ipBan = await db
        .collection("blacklist")
        .where("type", "==", "ip")
        .where("value", "==", clientIp)
        .limit(1)
        .get();
      if (!ipBan.empty) return { allowed: false, reason: "blacklist_ip" };
      await db.collection("users").doc(uid).set(
        { lastIp: clientIp, lastLogin: admin.firestore.FieldValue.serverTimestamp() },
        { merge: true }
      );
    } else {
      await db.collection("users").doc(uid).set(
        { lastLogin: admin.firestore.FieldValue.serverTimestamp() },
        { merge: true }
      );
    }

    return { allowed: true, lastIp: clientIp || null };
  }
);

function assertCallerIsAdmin(request: functions.CallableRequest): void {
  if (!request.auth) {
    throw new functions.HttpsError("unauthenticated", "Giriş gerekli.");
  }
  if (request.auth.token.admin !== true) {
    throw new functions.HttpsError("permission-denied", "Admin yetkisi gerekli.");
  }
}

export const setAdminClaim = functions.onCall(
  { region: "europe-west1", cors: true },
  async (request) => {
    assertCallerIsAdmin(request);
    const { targetUid, isAdmin } = request.data as {
      targetUid?: string;
      isAdmin?: boolean;
    };
    if (!targetUid || typeof isAdmin !== "boolean") {
      throw new functions.HttpsError("invalid-argument", "targetUid ve isAdmin gerekli.");
    }
    if (targetUid === request.auth!.uid && !isAdmin) {
      throw new functions.HttpsError(
        "failed-precondition",
        "Kendi admin yetkinizi kaldıramazsınız."
      );
    }
    await admin.auth().setCustomUserClaims(targetUid, { admin: isAdmin });
    await admin.firestore().collection("users").doc(targetUid).set(
      { role: isAdmin ? "Admin" : "User" },
      { merge: true }
    );
    return { success: true, targetUid, isAdmin };
  }
);

export const adminSendPush = functions.onCall(
  { region: "europe-west1", cors: true },
  async (request) => {
    assertCallerIsAdmin(request);
    const { title, body, token, topic, data } = request.data as {
      title?: string;
      body?: string;
      token?: string;
      topic?: string;
      data?: Record<string, string>;
    };
    if (!title?.trim() || !body?.trim()) {
      throw new functions.HttpsError("invalid-argument", "title ve body gerekli.");
    }
    if (!token?.trim() && !topic?.trim()) {
      throw new functions.HttpsError(
        "invalid-argument",
        "token veya topic gerekli."
      );
    }
    const base = {
      notification: { title: title.trim(), body: body.trim() },
      data: data ?? {},
      android: { priority: "high" as const },
      apns: { payload: { aps: { sound: "default" } } },
    };
    const messageId = token?.trim()
      ? await admin.messaging().send({ ...base, token: token.trim() })
      : await admin.messaging().send({ ...base, topic: topic!.trim() });
    await admin.firestore().collection("pushHistory").add({
      title: title.trim(),
      body: body.trim(),
      token: token?.trim() ?? null,
      topic: topic?.trim() ?? null,
      data: data ?? {},
      messageId,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      sentBy: request.auth!.token.email ?? request.auth!.uid,
    });
    return { success: true, messageId };
  }
);

export const purgeDeletedNotes = scheduler.onSchedule(
  { schedule: "0 3 * * *", region: "europe-west1", timeZone: "UTC" },
  async () => {
    const db = admin.firestore();
    const cutoff = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const cutoffTs = admin.firestore.Timestamp.fromDate(cutoff);

    logger.info(
      `[purgeDeletedNotes] Purging notes deleted before ${cutoff.toISOString()}`
    );

    // Her batch için granüler sayaç — not başına subcollection doküman sayısı
    // öngörülemez olduğundan 490 operasyon limitini aşmamak için
    // her ekleme öncesi kontrol edilir.
    const MAX_OPS = 490;
    let batch = db.batch();
    let opsInBatch = 0;
    let totalDeleted = 0;

    const flushBatch = async () => {
      if (opsInBatch === 0) return;
      await batch.commit();
      logger.info(`[purgeDeletedNotes] Batch committed (${opsInBatch} ops)`);
      batch = db.batch();
      opsInBatch = 0;
    };

    const addDelete = async (ref: FirebaseFirestore.DocumentReference) => {
      if (opsInBatch >= MAX_OPS) await flushBatch();
      batch.delete(ref);
      opsInBatch++;
    };

    // Sayfalı okuma — her seferinde en fazla 100 not işle
    while (true) {
      const snap = await db
        .collection("notes")
        .where("deletedAt", "<", cutoffTs)
        .limit(100)
        .get();

      if (snap.empty) break;

      for (const doc of snap.docs) {
        // Alt koleksiyonları önce sil
        const [historySnap, commentsSnap] = await Promise.all([
          doc.ref.collection("history").get(),
          doc.ref.collection("comments").get(),
        ]);
        for (const h of historySnap.docs) await addDelete(h.ref);
        for (const c of commentsSnap.docs) await addDelete(c.ref);
        // Son olarak notu sil
        await addDelete(doc.ref);
        totalDeleted++;
      }

      if (snap.size < 100) break;
    }

    // Kalan işlemleri commit et
    await flushBatch();

    logger.info(
      `[purgeDeletedNotes] Done — ${totalDeleted} notes permanently deleted.`
    );
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// onSurveyResponseCreated — Increment survey responseCount (admin-only writes).
// ─────────────────────────────────────────────────────────────────────────────
export const onSurveyResponseCreated = onDocumentCreated(
  {
    document: "surveyResponses/{surveyId}/responses/{responseId}",
    region: "europe-west1",
  },
  async (event) => {
    const surveyId = event.params.surveyId;
    if (!surveyId) return;
    try {
      await admin.firestore().collection("surveys").doc(surveyId).update({
        responseCount: admin.firestore.FieldValue.increment(1),
      });
    } catch (e) {
      logger.error("[onSurveyResponseCreated]", e);
    }
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// lookupAppointmentGroupByCode — Public booking lookup without exposing all groups.
// ─────────────────────────────────────────────────────────────────────────────
export const lookupAppointmentGroupByCode = functions.onCall(
  { region: "europe-west1", cors: true },
  async (request) => {
    if (!request.auth) {
      throw new functions.HttpsError("unauthenticated", "Giriş gerekli.");
    }
    const code = String((request.data as { code?: string })?.code ?? "")
      .trim()
      .toUpperCase();
    if (code.length < 6 || code.length > 20) {
      throw new functions.HttpsError("invalid-argument", "Geçersiz kod.");
    }
    const snap = await admin
      .firestore()
      .collection("appointment_groups")
      .where("groupCode", "==", code)
      .limit(1)
      .get();
    if (snap.empty) {
      return { group: null };
    }
    const doc = snap.docs[0];
    const d = doc.data();
    if (d.isActive === false) {
      return { group: null };
    }
    const startTs = d.startDate as admin.firestore.Timestamp | undefined;
    const endTs = d.endDate as admin.firestore.Timestamp | undefined;
    return {
      group: {
        id: doc.id,
        ownerId: d.ownerId,
        title: d.title ?? d.businessName ?? "",
        businessName: d.businessName ?? "",
        groupCode: d.groupCode ?? code,
        durationMinutes: d.durationMinutes ?? 30,
        bufferMinutes: d.bufferMinutes ?? 0,
        startHour: d.startHour ?? 9,
        endHour: d.endHour ?? 17,
        workingDays: d.workingDays ?? [1, 2, 3, 4, 5],
        breaks: d.breaks ?? [],
        startDateMs: startTs?.toMillis?.() ?? Date.now(),
        endDateMs:
          endTs?.toMillis?.() ?? Date.now() + 30 * 24 * 60 * 60 * 1000,
        isActive: d.isActive !== false,
        minCancellationHours: d.minCancellationHours ?? 24,
      },
    };
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// deleteUserAccount — Removes Auth user after client data purge (optional).
// ─────────────────────────────────────────────────────────────────────────────
export const deleteUserAccount = functions.onCall(
  { region: "europe-west1", cors: true },
  async (request) => {
    if (!request.auth) {
      throw new functions.HttpsError("unauthenticated", "Giriş gerekli.");
    }
    const uid = request.auth.uid;
    try {
      await admin.auth().deleteUser(uid);
    } catch (e) {
      logger.warn("[deleteUserAccount] auth delete", e);
      throw new functions.HttpsError(
        "internal",
        "Hesap silinemedi. Lütfen tekrar giriş yapıp deneyin."
      );
    }
    return { success: true };
  }
);

