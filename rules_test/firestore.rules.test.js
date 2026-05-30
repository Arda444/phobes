/**
 * Firestore security rules unit tests.
 * Run (PowerShell): cd rules_test; npm install; npm test
 */
const fs = require("fs");
const path = require("path");
const { describe, it, before, after, beforeEach } = require("node:test");
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");

const PROJECT_ID = "phobes-rules-test";
const rulesPath = path.join(__dirname, "..", "firestore.rules");
const rules = fs.readFileSync(rulesPath, "utf8");

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

function authedDb(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

describe("teams", () => {
  it("create requires sole member as self", async () => {
    const db = authedDb("user1");
    await assertSucceeds(
      db.collection("teams").add({
        ownerId: "user1",
        memberIds: ["user1"],
        adminIds: ["user1"],
        name: "Team A",
      })
    );
    await assertFails(
      db.collection("teams").add({
        ownerId: "user1",
        memberIds: ["user1", "user2"],
        adminIds: ["user1"],
        name: "Team B",
      })
    );
  });
});

describe("habits", () => {
  it("cannot change userId on update", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection("habits").doc("h1").set({
        userId: "user1",
        title: "Read",
        streak: 1,
        createdAt: new Date(),
      });
    });
    const db = authedDb("user1");
    await assertFails(
      db.collection("habits").doc("h1").update({
        userId: "user2",
        title: "Read",
        streak: 1,
      })
    );
  });
});

describe("budget_accounts", () => {
  it("owner can update balance within delta cap", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection("budget_accounts").doc("acc1").set({
        userId: "user1",
        name: "Cash",
        balance: 100,
      });
    });

    const db = authedDb("user1");
    await assertSucceeds(
      db.collection("budget_accounts").doc("acc1").update({
        userId: "user1",
        balance: 150,
      })
    );
    await assertFails(
      db.collection("budget_accounts").doc("acc1").update({
        userId: "user1",
        balance: 2000000,
      })
    );
  });

  it("other user cannot update account", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection("budget_accounts").doc("acc1").set({
        userId: "user1",
        name: "Cash",
        balance: 100,
      });
    });

    const db = authedDb("user2");
    await assertFails(
      db.collection("budget_accounts").doc("acc1").update({
        userId: "user1",
        balance: 0,
      })
    );
  });
});

describe("surveys", () => {
  it("signed-in user cannot increment responseCount", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection("surveys").doc("s1").set({
        title: "Q",
        status: "active",
        responseCount: 0,
      });
    });

    const db = authedDb("user1");
    await assertFails(
      db.collection("surveys").doc("s1").update({ responseCount: 1 })
    );
  });
});

describe("surveyResponses", () => {
  it("user can create own response doc", async () => {
    const db = authedDb("user1");
    await assertSucceeds(
      db
        .collection("surveyResponses")
        .doc("s1")
        .collection("responses")
        .doc("user1")
        .set({
          userId: "user1",
          answers: { q1: "yes" },
        })
    );
  });
});

describe("tasks", () => {
  it("owner can create personal task", async () => {
    const db = authedDb("user1");
    await assertSucceeds(
      db.collection("tasks").add({
        userId: "user1",
        title: "Test task",
        isCompleted: false,
        assignedTo: [],
      })
    );
  });

  it("cannot create task for another user", async () => {
    const db = authedDb("user1");
    await assertFails(
      db.collection("tasks").add({
        userId: "user2",
        title: "Stolen",
        isCompleted: false,
        assignedTo: [],
      })
    );
  });

  it("other user cannot read private task", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection("tasks").doc("t1").set({
        userId: "user1",
        title: "Private",
        isCompleted: false,
        assignedTo: [],
      });
    });
    const db = authedDb("user2");
    await assertFails(db.collection("tasks").doc("t1").get());
  });
});

describe("notes", () => {
  it("owner can create note", async () => {
    const db = authedDb("user1");
    await assertSucceeds(
      db.collection("notes").add({
        userId: "user1",
        title: "My note",
        content: "",
        allowedUserIds: [],
      })
    );
  });

  it("other user cannot read private note", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection("notes").doc("n1").set({
        userId: "user1",
        title: "Secret",
        content: "",
        allowedUserIds: [],
      });
    });
    const db = authedDb("user2");
    await assertFails(db.collection("notes").doc("n1").get());
  });
});

describe("teams", () => {
  it("member can read team", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection("teams").doc("team1").set({
        ownerId: "user1",
        memberIds: ["user1", "user2"],
        adminIds: ["user1"],
        name: "Squad",
      });
    });
    const db = authedDb("user2");
    await assertSucceeds(db.collection("teams").doc("team1").get());
  });

  it("non-member cannot read team", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection("teams").doc("team1").set({
        ownerId: "user1",
        memberIds: ["user1"],
        adminIds: ["user1"],
        name: "Private team",
      });
    });
    const db = authedDb("user3");
    await assertFails(db.collection("teams").doc("team1").get());
  });
});

describe("users", () => {
  it("owner can delete own profile", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection("users").doc("user1").set({
        name: "Test",
        xp: 0,
        level: 1,
      });
    });

    const db = authedDb("user1");
    await assertSucceeds(db.collection("users").doc("user1").delete());
  });
});
