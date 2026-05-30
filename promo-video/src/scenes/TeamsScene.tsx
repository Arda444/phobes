import React from 'react';
import {
  useCurrentFrame,
  useVideoConfig,
  spring,
  interpolate,
  Easing,
} from 'remotion';
import { SceneFrame } from '../components/SceneFrame';
import { PhoneFrame } from '../components/PhoneFrame';
import { colors, fonts, moduleThemes, statsModuleColors } from '../theme';
import { moduleSlogans } from '../moduleSlogans';

/**
 * Takım sahnesi — gerçek Phobes Teams UI'ı taklit eder:
 * - Üst hero kartı: gradient bg, takım adı, üye/proje sayısı, avatar yığını,
 *   üstünden kayan shine efekti, hafif breathing.
 * - Yatay sekme barı (Dashboard / Kanban / Aktivite / Kaynaklar / Notlar / Kitap).
 *   Aktif sekme alt çizgisi frame 10-20 arası Dashboard'tan Kanban'a kayar.
 * - Davet kodu chip'i: monospace 8 karakter alfanümerik kod (K7QX3MZP), karakterler
 *   tek tek yazılır, yanıp sönen caret + Kopyala butonu (mor).
 * - Kanban (3 kolon): Yapılacak / Devam / Tamamlandı. Her kolonda 1-2 task kartı
 *   (başlık, etiket renkli chip, atanan kişi avatarı, sol renkli kenarlık + öncelik
 *   noktası). Frame 30-50 arasında "API endpoint listesi" görevi Yapılacak'tan
 *   Devam'a drag-drop animasyonuyla kayar (translateX + scale 1.06 → 1.0 +
 *   hafif rotate + drop shadow). Devam kolonu sınırı drop sırasında parlar,
 *   sayaç badge'leri 2/1 → 1/2 olarak güncellenir.
 * - Alt aktivite paneli: 3 mini olay alttan yukarı stagger ile gelir (kullanıcı
 *   avatarı + aksiyon + detay chip + zaman damgası). Sağ üstte "+1 yeni" rozeti
 *   yeni aktivite bildirimi olarak frame ~48'de pop yapar.
 * - SceneFrame ile sarmalı. Toplam 90 kare.
 */

const TEAM_TINT = statsModuleColors.teams;
const TEAM_GRAD_END = '#0F766E';

// ─── Sabit veriler ──────────────────────────────────────────────────────────
const TEAM = {
  name: 'Phobes Ekibi',
  projects: 4,
  joinCode: 'K7QX3MZP',
};

type Role = 'Sahip' | 'Admin' | 'Üye';

const members: { name: string; avatar: string; color: string; role: Role }[] = [
  { name: 'Ada', avatar: 'A', color: '#8B5CF6', role: 'Sahip' },
  { name: 'Burak', avatar: 'B', color: '#10B981', role: 'Admin' },
  { name: 'Cem', avatar: 'C', color: '#F472B6', role: 'Üye' },
  { name: 'Deniz', avatar: 'D', color: '#06B6D4', role: 'Üye' },
  { name: 'Eda', avatar: 'E', color: '#F59E0B', role: 'Üye' },
];

const tabs: { id: string; label: string; icon: string }[] = [
  { id: 'dashboard', label: 'Dashboard', icon: '◫' },
  { id: 'kanban', label: 'Kanban', icon: '◈' },
  { id: 'activity', label: 'Aktivite', icon: '↺' },
  { id: 'resources', label: 'Kaynaklar', icon: '◔' },
  { id: 'notes', label: 'Notlar', icon: '✎' },
  { id: 'book', label: 'Kitap', icon: '✦' },
];

type Priority = 'low' | 'medium' | 'high';
type TaskTag = 'frontend' | 'backend' | 'tasarım';

type TaskMock = {
  title: string;
  tag: TaskTag;
  assignee: string;
  assigneeColor: string;
  priority: Priority;
};

const tagColor: Record<TaskTag, string> = {
  frontend: '#06B6D4',
  backend: '#10B981',
  'tasarım': '#F472B6',
};

const priorityColor: Record<Priority, string> = {
  low: '#10B981',
  medium: '#F59E0B',
  high: '#EF4444',
};

// Yapılacak'tan Devam'a kayan görev (drag-drop animasyonunun konusu)
const movingTask: TaskMock = {
  title: 'API endpoint listesi',
  tag: 'backend',
  assignee: 'B',
  assigneeColor: '#10B981',
  priority: 'high',
};

const columns: {
  title: string;
  color: string;
  staticTasks: TaskMock[];
}[] = [
  {
    title: 'Yapılacak',
    color: '#F59E0B',
    staticTasks: [
      {
        title: 'Logo varyantları',
        tag: 'tasarım',
        assignee: 'A',
        assigneeColor: '#8B5CF6',
        priority: 'medium',
      },
    ],
  },
  {
    title: 'Devam',
    color: '#06B6D4',
    staticTasks: [
      {
        title: 'Onboarding ekranı',
        tag: 'frontend',
        assignee: 'C',
        assigneeColor: '#F472B6',
        priority: 'high',
      },
    ],
  },
  {
    title: 'Tamamlandı',
    color: '#10B981',
    staticTasks: [
      {
        title: 'Login akışı',
        tag: 'frontend',
        assignee: 'D',
        assigneeColor: '#06B6D4',
        priority: 'medium',
      },
      {
        title: 'Marka renkleri',
        tag: 'tasarım',
        assignee: 'A',
        assigneeColor: '#8B5CF6',
        priority: 'low',
      },
    ],
  },
];

type Activity = {
  user: string;
  userColor: string;
  action: string;
  detail: string;
  time: string;
  icon: string;
  accent: string;
};

const activityItems: Activity[] = [
  {
    user: 'Ada',
    userColor: '#8B5CF6',
    action: 'görevi tamamladı',
    detail: 'Marka renkleri',
    time: '2 dk önce',
    icon: '✓',
    accent: '#10B981',
  },
  {
    user: 'Burak',
    userColor: '#10B981',
    action: 'kartı taşıdı',
    detail: 'API listesi → Devam',
    time: 'şimdi',
    icon: '➔',
    accent: '#F59E0B',
  },
  {
    user: 'Cem',
    userColor: '#F472B6',
    action: 'notu güncelledi',
    detail: 'Sprint planı v2',
    time: '5 dk önce',
    icon: '✎',
    accent: '#06B6D4',
  },
];

// Kanban kolon → kolon yatay kayma mesafesi (px). 540 telefon, 16+16 sahne
// padding, 8 grid gap, 3 kolon → kolon ≈ 158.67 px, kolon-kolon mesafesi ≈ 167 px.
const KANBAN_COL_SHIFT = 167;

export const TeamsScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const theme = { ...moduleThemes.teams, color: TEAM_TINT };

  // ─── Animasyon zaman çizelgesi (90 kare) ───────────────────────────────────
  const heroEnter = spring({ frame, fps, config: { damping: 14 } });
  const tabEnter = spring({ frame: frame - 5, fps, config: { damping: 14 } });
  // Sekme alt çizgisi Dashboard (0) → Kanban (1)
  const tabSlide = interpolate(frame, [12, 24], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.bezier(0.25, 1, 0.5, 1),
  });
  const inviteEnter = spring({
    frame: frame - 8,
    fps,
    config: { damping: 14 },
  });
  // Davet kodu typing
  const codeLen = Math.floor(
    interpolate(frame, [17, 27], [0, TEAM.joinCode.length], {
      extrapolateLeft: 'clamp',
      extrapolateRight: 'clamp',
    }),
  );
  const visibleCode = TEAM.joinCode.slice(0, codeLen);
  const caretOn = frame % 8 < 4;

  const kanbanEnter = spring({
    frame: frame - 12,
    fps,
    config: { damping: 14 },
  });

  // Drag-drop ilerleme (Yapılacak → Devam)
  const dragProgress = interpolate(frame, [36, 58], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.bezier(0.4, 0, 0.2, 1),
  });
  const taskMoved = dragProgress >= 1;

  // Drag esnasında yüzen kart efektleri
  const dragLift = interpolate(
    dragProgress,
    [0, 0.18, 0.82, 1],
    [0, -10, -10, 0],
    { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' },
  );
  const dragScale = interpolate(
    dragProgress,
    [0, 0.18, 0.82, 1],
    [1, 1.06, 1.06, 1],
    { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' },
  );
  const dragRot = interpolate(
    dragProgress,
    [0, 0.18, 0.82, 1],
    [0, -2.5, -2.5, 0],
    { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' },
  );
  const dragShadow = interpolate(
    dragProgress,
    [0, 0.18, 0.82, 1],
    [0, 1, 1, 0],
    { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' },
  );
  // Drop hedef kolonunun parlaması
  const dropGlow = interpolate(dragProgress, [0.2, 0.85, 1], [0, 1, 0.4], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  // "+1 yeni aktivite" rozeti
  const badgePop = spring({
    frame: frame - 56,
    fps,
    config: { damping: 10 },
  });

  // Hafif breathing
  const breath = 1 + Math.sin(frame * 0.05) * 0.005;

  // Hero kartında soldan sağa kayan shine
  const shineX = interpolate(frame % 60, [0, 50], [-30, 130], {
    extrapolateRight: 'clamp',
  });

  return (
    <SceneFrame
      tint={theme.color}
      title={moduleSlogans.teams.title}
      subtitle={moduleSlogans.teams.subtitle}
      transition={moduleSlogans.teams.transition}
      badge="◍"
      chips={['Kanban', 'Davet kodu', 'Aktivite akışı']}
    >
      <PhoneFrame>
        <div
          style={{
            paddingTop: 64,
            paddingLeft: 16,
            paddingRight: 16,
            paddingBottom: 20,
            height: '100%',
            background: `
              radial-gradient(circle at 50% 0%, ${theme.color}28 0%, transparent 45%),
              linear-gradient(180deg, ${theme.color}10 0%, ${colors.surface} 30%)
            `,
            position: 'relative',
            overflow: 'hidden',
          }}
        >
          {/* ───────── HERO KARTI ───────── */}
          <div
            style={{
              padding: '14px 16px',
              borderRadius: 22,
              background: `linear-gradient(135deg, ${TEAM_TINT}, ${TEAM_GRAD_END})`,
              boxShadow: `0 14px 36px ${theme.color}55, inset 0 1px 0 rgba(255,255,255,0.22)`,
              marginBottom: 10,
              position: 'relative',
              overflow: 'hidden',
              opacity: heroEnter,
              transform: `translateY(${(1 - heroEnter) * 20}px) scale(${breath})`,
            }}
          >
            {/* Shine sweep */}
            <div
              style={{
                position: 'absolute',
                top: 0,
                left: `${shineX}%`,
                width: '30%',
                height: '100%',
                background:
                  'linear-gradient(115deg, transparent 35%, rgba(255,255,255,0.28) 50%, transparent 65%)',
                pointerEvents: 'none',
              }}
            />

            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 12,
                position: 'relative',
              }}
            >
              {/* Takım baş harfi rozeti */}
              <div
                style={{
                  width: 46,
                  height: 46,
                  borderRadius: 14,
                  background: 'rgba(255,255,255,0.18)',
                  border: '1.5px solid rgba(255,255,255,0.28)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  color: colors.white,
                  fontFamily: fonts.display,
                  fontSize: 22,
                  fontWeight: 900,
                  flexShrink: 0,
                }}
              >
                P
              </div>

              <div style={{ flex: 1, minWidth: 0 }}>
                <div
                  style={{
                    color: colors.white,
                    fontFamily: fonts.display,
                    fontSize: 19,
                    fontWeight: 800,
                    letterSpacing: -0.3,
                    lineHeight: 1.1,
                  }}
                >
                  {TEAM.name}
                </div>
                <div
                  style={{
                    display: 'flex',
                    gap: 10,
                    marginTop: 4,
                    color: colors.white80,
                    fontFamily: fonts.display,
                    fontSize: 11,
                    fontWeight: 600,
                  }}
                >
                  <span
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: 4,
                    }}
                  >
                    <span style={{ fontSize: 10 }}>◆</span>
                    {TEAM.projects} proje
                  </span>
                  <span style={{ opacity: 0.5 }}>·</span>
                  <span
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: 4,
                    }}
                  >
                    <span style={{ fontSize: 10 }}>◉</span>
                    {members.length} üye
                  </span>
                </div>
              </div>

              {/* Avatar yığını (yandan tek tek pop-in) */}
              <div style={{ display: 'flex', alignItems: 'center' }}>
                {members.map((m, i) => {
                  const av = spring({
                    frame: frame - 4 - i * 3,
                    fps,
                    config: { damping: 9, stiffness: 140 },
                  });
                  const isOwner = m.role === 'Sahip';
                  return (
                    <div
                      key={m.name}
                      style={{
                        width: 28,
                        height: 28,
                        borderRadius: '50%',
                        background: m.color,
                        marginLeft: i === 0 ? 0 : -8,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        color: colors.white,
                        fontFamily: fonts.display,
                        fontWeight: 800,
                        fontSize: 12,
                        border: isOwner
                          ? '2px solid #FBBF24'
                          : '2px solid rgba(255,255,255,0.85)',
                        boxShadow: isOwner
                          ? `0 0 12px #FBBF24AA, 0 4px 10px ${m.color}66`
                          : `0 4px 10px ${m.color}66`,
                        opacity: av,
                        transform: `translateX(${(1 - av) * 18}px) scale(${0.5 + av * 0.5})`,
                        zIndex: members.length - i,
                      }}
                    >
                      {m.avatar}
                    </div>
                  );
                })}
              </div>
            </div>
          </div>

          {/* ───────── TAB BAR ───────── */}
          <TabBar slide={tabSlide} enter={tabEnter} tint={theme.color} />

          {/* ───────── DAVET KODU CHİP ───────── */}
          <div
            style={{
              padding: '8px 10px',
              borderRadius: 12,
              background: colors.white05,
              border: `1px dashed ${theme.color}88`,
              marginTop: 8,
              marginBottom: 10,
              display: 'flex',
              alignItems: 'center',
              gap: 10,
              opacity: inviteEnter,
              transform: `translateY(${(1 - inviteEnter) * 12}px)`,
            }}
          >
            <div
              style={{
                width: 28,
                height: 28,
                borderRadius: 8,
                background: `${theme.color}22`,
                border: `1px solid ${theme.color}55`,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: theme.color,
                fontSize: 14,
                fontWeight: 800,
                flexShrink: 0,
              }}
            >
              ⌬
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div
                style={{
                  color: colors.white60,
                  fontFamily: fonts.display,
                  fontSize: 9,
                  fontWeight: 700,
                  textTransform: 'uppercase',
                  letterSpacing: 1.4,
                  marginBottom: 1,
                }}
              >
                Davet kodu
              </div>
              <div
                style={{
                  color: colors.white,
                  fontFamily: fonts.mono,
                  fontSize: 16,
                  fontWeight: 700,
                  letterSpacing: 3,
                  lineHeight: 1,
                  display: 'flex',
                  alignItems: 'center',
                  height: 16,
                }}
              >
                {visibleCode}
                {codeLen < TEAM.joinCode.length && (
                  <span
                    style={{
                      display: 'inline-block',
                      width: 2,
                      height: 14,
                      background: theme.color,
                      marginLeft: 2,
                      opacity: caretOn ? 1 : 0,
                      boxShadow: `0 0 6px ${theme.color}`,
                    }}
                  />
                )}
              </div>
            </div>
            <div
              style={{
                padding: '6px 10px',
                borderRadius: 8,
                background: theme.color,
                color: colors.white,
                fontFamily: fonts.display,
                fontSize: 10,
                fontWeight: 800,
                letterSpacing: 0.4,
                display: 'flex',
                alignItems: 'center',
                gap: 4,
                boxShadow: `0 4px 12px ${theme.color}66`,
              }}
            >
              <span style={{ fontSize: 11 }}>⎘</span>
              Kopyala
            </div>
          </div>

          {/* ───────── KANBAN ───────── */}
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(3, 1fr)',
              gap: 8,
              opacity: kanbanEnter,
              transform: `translateY(${(1 - kanbanEnter) * 14}px)`,
            }}
          >
            {columns.map((col, ci) => {
              const isDevam = ci === 1;
              const isYapilacak = ci === 0;
              const count =
                col.staticTasks.length +
                (isYapilacak && !taskMoved ? 1 : 0) +
                (isDevam && taskMoved ? 1 : 0);
              const glowAlpha = isDevam
                ? Math.round(dropGlow * 200)
                    .toString(16)
                    .padStart(2, '0')
                : '00';

              return (
                <div
                  key={col.title}
                  style={{
                    background: colors.white05,
                    border: `1px solid ${
                      isDevam
                        ? `${col.color}${glowAlpha}`
                        : colors.white10
                    }`,
                    borderRadius: 12,
                    padding: 8,
                    display: 'flex',
                    flexDirection: 'column',
                    gap: 6,
                    minHeight: 168,
                    boxShadow:
                      isDevam && dropGlow > 0
                        ? `0 0 ${dropGlow * 24}px ${col.color}${Math.round(
                            dropGlow * 150,
                          )
                            .toString(16)
                            .padStart(2, '0')}`
                        : 'none',
                    position: 'relative',
                  }}
                >
                  {/* Kolon başlığı */}
                  <div
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between',
                      paddingBottom: 6,
                      borderBottom: `1px solid ${col.color}22`,
                      marginBottom: 2,
                    }}
                  >
                    <span
                      style={{
                        color: col.color,
                        fontFamily: fonts.display,
                        fontSize: 10,
                        fontWeight: 800,
                        letterSpacing: 0.6,
                        textTransform: 'uppercase',
                        display: 'flex',
                        alignItems: 'center',
                        gap: 4,
                      }}
                    >
                      <span
                        style={{
                          width: 6,
                          height: 6,
                          borderRadius: '50%',
                          background: col.color,
                          boxShadow: `0 0 6px ${col.color}`,
                        }}
                      />
                      {col.title}
                    </span>
                    <span
                      style={{
                        background: `${col.color}22`,
                        color: col.color,
                        fontFamily: fonts.display,
                        fontSize: 9,
                        fontWeight: 800,
                        padding: '1px 6px',
                        borderRadius: 999,
                        minWidth: 16,
                        textAlign: 'center',
                      }}
                    >
                      {count}
                    </span>
                  </div>

                  {/* Statik kartlar */}
                  {col.staticTasks.map((t, ti) => {
                    const cardEnter = spring({
                      frame: frame - 14 - ci * 3 - ti * 3,
                      fps,
                      config: { damping: 14 },
                    });
                    return (
                      <TaskCard
                        key={t.title}
                        task={t}
                        enter={cardEnter}
                      />
                    );
                  })}

                  {/* Hareket eden kart — sadece Yapılacak kolonunda render,
                      transform ile Devam'a kayar. Kolonun slot 1 boşluğu
                      diğer kolonların min-height'i ile hizalı kalır. */}
                  {isYapilacak && (
                    <div
                      style={{
                        transform: `translate3d(${
                          dragProgress * KANBAN_COL_SHIFT
                        }px, ${dragLift}px, 0) scale(${dragScale}) rotate(${dragRot}deg)`,
                        transformOrigin: '50% 50%',
                        filter:
                          dragShadow > 0
                            ? `drop-shadow(0 ${6 + dragShadow * 8}px ${
                                10 + dragShadow * 16
                              }px rgba(0,0,0,${0.35 + dragShadow * 0.3}))`
                            : 'none',
                        position: 'relative',
                        zIndex: dragProgress > 0 ? 10 : 1,
                      }}
                    >
                      <TaskCard
                        task={movingTask}
                        enter={spring({
                          frame: frame - 16,
                          fps,
                          config: { damping: 14 },
                        })}
                        highlight={dragProgress > 0 && dragProgress < 1}
                        highlightColor={theme.color}
                      />
                    </div>
                  )}
                </div>
              );
            })}
          </div>

          {/* ───────── AKTİVİTE AKIŞI ───────── */}
          <div
            style={{
              marginTop: 10,
              padding: '10px 12px',
              borderRadius: 16,
              background: colors.white05,
              border: `1px solid ${colors.white10}`,
              position: 'relative',
            }}
          >
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                marginBottom: 8,
              }}
            >
              <div
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 6,
                }}
              >
                <div
                  style={{
                    width: 3,
                    height: 12,
                    borderRadius: 2,
                    background: theme.color,
                    boxShadow: `0 0 8px ${theme.color}`,
                  }}
                />
                <span
                  style={{
                    color: colors.white80,
                    fontFamily: fonts.display,
                    fontSize: 11,
                    fontWeight: 800,
                    letterSpacing: 1.4,
                    textTransform: 'uppercase',
                  }}
                >
                  Aktivite
                </span>
              </div>

              {/* +1 yeni aktivite rozeti (yeni bir taşıma olunca) */}
              {badgePop > 0.02 && (
                <div
                  style={{
                    padding: '2px 8px',
                    borderRadius: 999,
                    background: `linear-gradient(135deg, ${TEAM_TINT}, ${TEAM_GRAD_END})`,
                    color: colors.white,
                    fontFamily: fonts.display,
                    fontSize: 10,
                    fontWeight: 900,
                    letterSpacing: 0.3,
                    boxShadow: `0 6px 16px ${theme.color}88`,
                    transform: `scale(${0.6 + Math.min(1, badgePop) * 0.4})`,
                    opacity: Math.min(1, badgePop),
                  }}
                >
                  +1 yeni
                </div>
              )}
            </div>

            {activityItems.map((it, i) => {
              const enter = spring({
                frame: frame - 38 - i * 5,
                fps,
                config: { damping: 14 },
              });
              return (
                <div
                  key={`${it.user}-${i}`}
                  style={{
                    display: 'flex',
                    alignItems: 'flex-start',
                    gap: 8,
                    marginBottom: i === activityItems.length - 1 ? 0 : 8,
                    opacity: enter,
                    transform: `translateY(${(1 - enter) * 18}px)`,
                  }}
                >
                  <div
                    style={{
                      width: 26,
                      height: 26,
                      borderRadius: '50%',
                      background: it.userColor,
                      color: colors.white,
                      fontFamily: fonts.display,
                      fontWeight: 800,
                      fontSize: 11,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      flexShrink: 0,
                      border: '1.5px solid rgba(255,255,255,0.18)',
                      boxShadow: `0 4px 10px ${it.userColor}55`,
                    }}
                  >
                    {it.user[0]}
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div
                      style={{
                        color: colors.white,
                        fontFamily: fonts.display,
                        fontSize: 11.5,
                        fontWeight: 600,
                        lineHeight: 1.25,
                      }}
                    >
                      <span style={{ fontWeight: 800 }}>{it.user}</span>{' '}
                      <span style={{ color: colors.white60 }}>{it.action}</span>
                    </div>
                    <div
                      style={{
                        marginTop: 3,
                        display: 'flex',
                        alignItems: 'center',
                        gap: 6,
                      }}
                    >
                      <span
                        style={{
                          display: 'inline-flex',
                          alignItems: 'center',
                          gap: 4,
                          padding: '2px 7px',
                          background: `${it.accent}1F`,
                          border: `1px solid ${it.accent}44`,
                          color: it.accent,
                          fontFamily: fonts.display,
                          fontSize: 9.5,
                          fontWeight: 700,
                          borderRadius: 6,
                          lineHeight: 1.2,
                          maxWidth: 200,
                          overflow: 'hidden',
                          textOverflow: 'ellipsis',
                          whiteSpace: 'nowrap',
                        }}
                      >
                        <span>{it.icon}</span>
                        <span
                          style={{
                            overflow: 'hidden',
                            textOverflow: 'ellipsis',
                          }}
                        >
                          {it.detail}
                        </span>
                      </span>
                      <span
                        style={{
                          color: colors.white40,
                          fontFamily: fonts.display,
                          fontSize: 9,
                          fontWeight: 500,
                        }}
                      >
                        {it.time}
                      </span>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </PhoneFrame>
    </SceneFrame>
  );
};

// ─── Yardımcı bileşenler ────────────────────────────────────────────────────

const TabBar: React.FC<{
  slide: number;
  enter: number;
  tint: string;
}> = ({ slide, enter, tint }) => {
  const N = tabs.length;
  return (
    <div
      style={{
        display: 'flex',
        alignItems: 'center',
        padding: '4px 0 6px 0',
        background: colors.white05,
        border: `1px solid ${colors.white10}`,
        borderRadius: 14,
        position: 'relative',
        overflow: 'hidden',
        opacity: enter,
        transform: `translateY(${(1 - enter) * 12}px)`,
      }}
    >
      {tabs.map((t, i) => {
        const dist = Math.abs(i - slide);
        const isActive = dist < 0.5;
        const alpha = Math.max(0.45, 1 - dist * 0.5);
        return (
          <div
            key={t.id}
            style={{
              flex: 1,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: 4,
              padding: '6px 0',
              color: `rgba(255,255,255,${alpha})`,
              fontFamily: fonts.display,
              fontSize: 9.5,
              fontWeight: isActive ? 800 : 600,
              letterSpacing: 0.1,
              textShadow: isActive ? `0 0 12px ${tint}77` : 'none',
              whiteSpace: 'nowrap',
              zIndex: 2,
              position: 'relative',
            }}
          >
            <span style={{ fontSize: 11 }}>{t.icon}</span>
            <span>{t.label}</span>
          </div>
        );
      })}

      {/* Aktif sekme alt çizgisi — Dashboard'tan Kanban'a yatay kayar */}
      <div
        style={{
          position: 'absolute',
          bottom: 2,
          left: `calc(${(slide / N) * 100}% + 12px)`,
          width: `calc(${100 / N}% - 24px)`,
          height: 3,
          borderRadius: 999,
          background: `linear-gradient(90deg, ${tint}, ${TEAM_GRAD_END})`,
          boxShadow: `0 0 14px ${tint}AA`,
          zIndex: 1,
        }}
      />
    </div>
  );
};

const TaskCard: React.FC<{
  task: TaskMock;
  enter: number;
  highlight?: boolean;
  highlightColor?: string;
}> = ({ task, enter, highlight, highlightColor }) => {
  const tColor = tagColor[task.tag];
  const pColor = priorityColor[task.priority];
  return (
    <div
      style={{
        background: colors.surface,
        borderRadius: 10,
        padding: '7px 8px',
        border: highlight
          ? `1px solid ${highlightColor ?? tColor}`
          : `1px solid ${colors.white10}`,
        borderLeft: `3px solid ${tColor}`,
        opacity: enter,
        transform: `translateY(${(1 - enter) * 10}px) scale(${0.92 + enter * 0.08})`,
        boxShadow: highlight
          ? `0 6px 18px ${(highlightColor ?? tColor)}77, 0 0 0 1px ${(highlightColor ?? tColor)}55`
          : '0 4px 10px rgba(0,0,0,0.18)',
      }}
    >
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: 4,
          marginBottom: 5,
        }}
      >
        {/* Öncelik göstergesi */}
        <span
          style={{
            width: 5,
            height: 5,
            borderRadius: '50%',
            background: pColor,
            boxShadow: `0 0 5px ${pColor}`,
            flexShrink: 0,
          }}
        />
        <span
          style={{
            color: colors.white,
            fontFamily: fonts.display,
            fontSize: 9.5,
            fontWeight: 700,
            lineHeight: 1.15,
            flex: 1,
            overflow: 'hidden',
            textOverflow: 'ellipsis',
            whiteSpace: 'nowrap',
          }}
        >
          {task.title}
        </span>
      </div>
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          gap: 4,
        }}
      >
        <span
          style={{
            background: `${tColor}26`,
            color: tColor,
            fontFamily: fonts.display,
            fontSize: 8,
            fontWeight: 800,
            padding: '1px 5px',
            borderRadius: 4,
            letterSpacing: 0.3,
            textTransform: 'lowercase',
            border: `1px solid ${tColor}44`,
          }}
        >
          #{task.tag}
        </span>
        <div
          style={{
            width: 16,
            height: 16,
            borderRadius: '50%',
            background: task.assigneeColor,
            color: colors.white,
            fontFamily: fonts.display,
            fontWeight: 800,
            fontSize: 9,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            border: '1.5px solid rgba(255,255,255,0.2)',
            boxShadow: `0 2px 6px ${task.assigneeColor}55`,
          }}
        >
          {task.assignee}
        </div>
      </div>
    </div>
  );
};
