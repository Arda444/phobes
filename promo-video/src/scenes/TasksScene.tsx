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
 * Görev sahnesi — 120 kare (4 s @ 30 fps)
 * Kaynak: day_timeline_sheet.dart (_buildConnectedTimelineRow + _buildDetailCard)
 * Renk: statsModuleColors.tasks (#3B82F6)
 *
 * Zaman çizelgesi: 0–20 üst bar + XP kartı · 20–72 BUGÜN satırları · 54–76 tamamlama
 * · 72–92 YAKLAŞAN · 92+ FAB · sahne sonu SceneFrame fade
 */

const TASK_BLUE = statsModuleColors.tasks;
const TASK_BLUE_DARK = moduleThemes.tasks.gradient[1];

type PriorityKey = 'low' | 'medium' | 'high';

const priorityColors: Record<PriorityKey, string> = {
  low: '#10B981',
  medium: '#F59E0B',
  high: '#EF4444',
};

const priorityLabels: Record<PriorityKey, string> = {
  low: 'Düşük',
  medium: 'Orta',
  high: 'Yüksek',
};

type TaskMock = {
  title: string;
  start: string;
  end: string;
  durationMin: number;
  priority: PriorityKey;
  color: string;
  tags?: string[];
  recurring?: string;
  done?: boolean;
  xp?: number;
};

const todayTasks: TaskMock[] = [
  {
    title: 'Tasarım sunumu hazırla',
    start: '09:00',
    end: '09:30',
    durationMin: 30,
    priority: 'high',
    color: '#8B5CF6',
    tags: ['tasarım', 'sunum'],
    xp: 25,
  },
  {
    title: 'Sprint planlama',
    start: '11:30',
    end: '12:15',
    durationMin: 45,
    priority: 'medium',
    color: '#3B82F6',
    tags: ['ekip'],
    recurring: 'Haftalık',
    xp: 20,
  },
  {
    title: 'Spor — koşu',
    start: '17:00',
    end: '18:00',
    durationMin: 60,
    priority: 'low',
    color: '#22C55E',
    recurring: 'Günlük',
    done: true,
    xp: 15,
  },
];

const upcomingTasks: TaskMock[] = [
  {
    title: 'Müşteri demosu',
    start: 'Yarın',
    end: '14:00',
    durationMin: 45,
    priority: 'high',
    color: '#F06292',
    tags: ['müşteri'],
    xp: 30,
  },
];

/** Kare işaretçileri — 120 kare boyunca yayılı */
const F = {
  header: 4,
  xpCard: 10,
  sectionToday: 20,
  todayBase: 26,
  todayStagger: 7,
  complete: 54,
  xpPop: 60,
  xpCountStart: 58,
  xpCountEnd: 76,
  progressBump: 58,
  sectionUpcoming: 72,
  upcomingBase: 78,
  fab: 92,
  nav: 100,
} as const;

const springIn = (
  frame: number,
  start: number,
  fps: number,
  stiff = 120,
) =>
  spring({
    frame: frame - start,
    fps,
    config: { damping: 14, stiffness: stiff },
  });

export const TasksScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();

  const headerEnter = springIn(frame, F.header, fps);
  const xpCardEnter = springIn(frame, F.xpCard, fps);
  const sectionTodayEnter = springIn(frame, F.sectionToday, fps);
  const sectionUpcomingEnter = springIn(frame, F.sectionUpcoming, fps);
  const fabEnter = springIn(frame, F.fab, fps, 160);
  const navEnter = springIn(frame, F.nav, fps);

  const completeTick = spring({
    frame: frame - F.complete,
    fps,
    config: { damping: 10, stiffness: 140 },
  });

  const xpPop = spring({
    frame: frame - F.xpPop,
    fps,
    config: { damping: 9, stiffness: 130 },
  });

  const firstTaskDone = completeTick > 0.45;

  const xpCounter = Math.round(
    interpolate(
      frame,
      [F.xpCountStart, F.xpCountEnd],
      [2340, 2365],
      {
        extrapolateLeft: 'clamp',
        extrapolateRight: 'clamp',
        easing: Easing.out(Easing.cubic),
      },
    ),
  );

  const progressPct = interpolate(
    frame,
    [0, 18, F.progressBump, F.xpCountEnd],
    [40, 56, 56, 67],
    {
      extrapolateRight: 'clamp',
      easing: Easing.out(Easing.cubic),
    },
  );

  const breath = 1 + Math.sin(frame * 0.05) * 0.005;

  const tailFade = interpolate(
    frame,
    [durationInFrames - 12, durationInFrames],
    [1, 0.85],
    {
      extrapolateLeft: 'clamp',
      extrapolateRight: 'clamp',
      easing: Easing.bezier(0.4, 0, 1, 1),
    },
  );

  const xpToNext = Math.max(0, 2500 - xpCounter);

  return (
    <SceneFrame
      tint={TASK_BLUE}
      title={moduleSlogans.tasks.title}
      subtitle={moduleSlogans.tasks.subtitle}
      transition={moduleSlogans.tasks.transition}
      badge="✓"
      chips={['Tekrarlı görevler', 'Öncelik & XP', 'Zaman çizelgesi']}
    >
      <PhoneFrame>
        <div
          style={{
            paddingTop: 64,
            paddingLeft: 16,
            paddingRight: 16,
            paddingBottom: 24,
            height: '100%',
            background: `
              radial-gradient(circle at 50% 0%, ${TASK_BLUE}22 0%, transparent 45%),
              linear-gradient(180deg, ${TASK_BLUE}10 0%, ${colors.surface} 32%)
            `,
            position: 'relative',
            overflow: 'hidden',
            opacity: tailFade,
            transform: `scale(${0.995 + (tailFade - 0.85) * 0.033})`,
            transformOrigin: 'center top',
          }}
        >
          {/* Üst bar */}
          <div
            style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'flex-start',
              marginBottom: 12,
              opacity: headerEnter,
              transform: `translateY(${(1 - headerEnter) * 14}px)`,
            }}
          >
            <div>
              <div
                style={{
                  color: colors.white60,
                  fontFamily: fonts.display,
                  fontSize: 11,
                  fontWeight: 700,
                  letterSpacing: 1.4,
                  textTransform: 'uppercase',
                }}
              >
                Görevlerim
              </div>
              <div
                style={{
                  color: colors.white,
                  fontFamily: fonts.display,
                  fontSize: 26,
                  fontWeight: 800,
                  letterSpacing: -0.5,
                  lineHeight: 1.05,
                  marginTop: 2,
                }}
              >
                Bugün
              </div>
              <div
                style={{
                  color: colors.white60,
                  fontFamily: fonts.display,
                  fontSize: 12,
                  fontWeight: 500,
                  marginTop: 2,
                }}
              >
                Çarşamba · 27 Mayıs
              </div>
            </div>
            <div style={{ display: 'flex', gap: 8 }}>
              <IconButton tint={TASK_BLUE}>⌕</IconButton>
              <IconButton tint={TASK_BLUE}>⏷</IconButton>
            </div>
          </div>

          {/* XP / Level kartı */}
          <div
            style={{
              padding: '12px 14px',
              borderRadius: 16,
              background: `linear-gradient(135deg, ${TASK_BLUE}E8, ${TASK_BLUE_DARK}E8)`,
              boxShadow: `0 12px 28px ${TASK_BLUE}55, inset 0 1px 0 ${colors.white20}`,
              marginBottom: 12,
              display: 'flex',
              alignItems: 'center',
              gap: 12,
              opacity: xpCardEnter,
              transform: `translateY(${(1 - xpCardEnter) * 16}px) scale(${0.96 + xpCardEnter * 0.04}) scale(${breath})`,
            }}
          >
            <div
              style={{
                width: 42,
                height: 42,
                borderRadius: 12,
                background: 'rgba(255,255,255,0.18)',
                border: '1.5px solid rgba(255,255,255,0.28)',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center',
                flexShrink: 0,
              }}
            >
              <div
                style={{
                  color: colors.white60,
                  fontFamily: fonts.display,
                  fontSize: 8,
                  fontWeight: 700,
                  letterSpacing: 0.8,
                }}
              >
                LVL
              </div>
              <div
                style={{
                  color: colors.white,
                  fontFamily: fonts.display,
                  fontSize: 18,
                  fontWeight: 900,
                  lineHeight: 1.1,
                }}
              >
                12
              </div>
            </div>
            <div style={{ flex: 1 }}>
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'baseline',
                  marginBottom: 6,
                }}
              >
                <div
                  style={{
                    color: colors.white,
                    fontFamily: fonts.display,
                    fontSize: 18,
                    fontWeight: 800,
                    letterSpacing: -0.3,
                  }}
                >
                  {xpCounter.toLocaleString('tr-TR')} XP
                </div>
                <div
                  style={{
                    color: colors.white80,
                    fontFamily: fonts.display,
                    fontSize: 10,
                    fontWeight: 600,
                  }}
                >
                  Lv 13'e {xpToNext} XP
                </div>
              </div>
              <div
                style={{
                  height: 7,
                  background: 'rgba(0,0,0,0.25)',
                  borderRadius: 999,
                  overflow: 'hidden',
                  position: 'relative',
                }}
              >
                <div
                  style={{
                    height: '100%',
                    width: `${progressPct}%`,
                    background: `linear-gradient(90deg, #FBBF24, ${colors.accent})`,
                    borderRadius: 999,
                    boxShadow: `0 0 10px ${colors.accent}88`,
                  }}
                />
              </div>
            </div>
          </div>

          <SectionHeader
            label="BUGÜN"
            count={`${todayTasks.length} görev`}
            tint={TASK_BLUE}
            enter={sectionTodayEnter}
          />

          <div style={{ marginTop: 4 }}>
            {todayTasks.map((task, i) => {
              const enter = springIn(
                frame,
                F.todayBase + i * F.todayStagger,
                fps,
              );
              const isCompleting = i === 0;
              const visualDone = isCompleting
                ? firstTaskDone
                : task.done === true;

              return (
                <TimelineRow
                  key={`today-${i}`}
                  task={task}
                  enter={enter}
                  isFirst={i === 0}
                  isLast={i === todayTasks.length - 1}
                  visualDone={visualDone}
                  isCompleting={isCompleting}
                  completeTick={completeTick}
                  breath={1 + Math.sin((frame + i * 8) * 0.05) * 0.005}
                  accent={TASK_BLUE}
                />
              );
            })}
          </div>

          <div style={{ marginTop: 8 }}>
            <SectionHeader
              label="YAKLAŞAN"
              count={`${upcomingTasks.length} görev`}
              tint={TASK_BLUE}
              enter={sectionUpcomingEnter}
            />
          </div>

          {upcomingTasks.map((task, i) => (
            <TimelineRow
              key={`up-${i}`}
              task={task}
              enter={springIn(frame, F.upcomingBase + i * 5, fps)}
              isFirst
              isLast
              visualDone={false}
              isCompleting={false}
              completeTick={0}
              breath={1 + Math.sin((frame + 24) * 0.05) * 0.005}
              accent={TASK_BLUE}
              compactTime
            />
          ))}

          {/* FAB */}
          <div
            style={{
              position: 'absolute',
              right: 16,
              bottom: 78,
              width: 52,
              height: 52,
              borderRadius: 18,
              background: `linear-gradient(135deg, ${TASK_BLUE}, ${TASK_BLUE_DARK})`,
              boxShadow: `0 12px 28px ${TASK_BLUE}88, inset 0 1px 0 ${colors.white20}`,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: colors.white,
              fontFamily: fonts.display,
              fontSize: 30,
              fontWeight: 300,
              opacity: fabEnter,
              transform: `scale(${0.4 + fabEnter * 0.6})`,
            }}
          >
            +
          </div>

          {/* Alt nav */}
          <div
            style={{
              position: 'absolute',
              left: 12,
              right: 12,
              bottom: 12,
              height: 54,
              borderRadius: 22,
              background: 'rgba(20,20,20,0.75)',
              backdropFilter: 'blur(20px)',
              border: `1px solid ${colors.white10}`,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-around',
              padding: '0 14px',
              opacity: interpolate(navEnter, [0, 1], [0, 0.95]),
              transform: `translateY(${(1 - navEnter) * 12}px)`,
            }}
          >
            {['📅', '👥', '✨', '⋯', '👤'].map((icon, idx) => (
              <div
                key={idx}
                style={{
                  fontSize: 18,
                  opacity: idx === 0 ? 1 : 0.45,
                  filter:
                    idx === 0 ? `drop-shadow(0 0 8px ${TASK_BLUE})` : 'none',
                }}
              >
                {icon}
              </div>
            ))}
          </div>

          {/* +25 XP popup */}
          {xpPop > 0.01 && (
            <div
              style={{
                position: 'absolute',
                top: 368,
                left: '50%',
                padding: '10px 16px',
                background: `linear-gradient(135deg, #FBBF24, ${TASK_BLUE})`,
                color: colors.white,
                fontFamily: fonts.display,
                fontWeight: 900,
                fontSize: 22,
                borderRadius: 14,
                boxShadow: `0 14px 36px ${TASK_BLUE}AA`,
                transform: `translateX(-50%) scale(${xpPop}) translateY(${interpolate(xpPop, [0, 1, 1.4], [0, -28, -56], { extrapolateRight: 'clamp' })})px)`,
                opacity: interpolate(xpPop, [0, 0.4, 1, 1.3], [0, 1, 1, 0], {
                  extrapolateRight: 'clamp',
                }),
                display: 'flex',
                alignItems: 'center',
                gap: 8,
                whiteSpace: 'nowrap',
              }}
            >
              <span>⚡</span>
              <span>+25 XP</span>
            </div>
          )}

          {xpPop > 0.2 &&
            Array.from({ length: 8 }).map((_, i) => {
              const angle = (i / 8) * Math.PI * 2;
              const dist = interpolate(xpPop, [0, 1], [0, 48], {
                extrapolateRight: 'clamp',
              });
              const fade = interpolate(xpPop, [0.2, 0.6, 1.2], [0, 1, 0], {
                extrapolateRight: 'clamp',
              });
              return (
                <div
                  key={`p-${i}`}
                  style={{
                    position: 'absolute',
                    top: 380,
                    left: '50%',
                    width: 6,
                    height: 6,
                    borderRadius: '50%',
                    background: i % 2 === 0 ? TASK_BLUE : colors.accent,
                    transform: `translate(${Math.cos(angle) * dist}px, ${Math.sin(angle) * dist}px)`,
                    opacity: fade,
                  }}
                />
              );
            })}
        </div>
      </PhoneFrame>
    </SceneFrame>
  );
};

// ─── Yardımcı bileşenler ───────────────────────────────────────────────────

const IconButton: React.FC<{ tint: string; children: React.ReactNode }> = ({
  tint,
  children,
}) => (
  <div
    style={{
      width: 32,
      height: 32,
      borderRadius: 10,
      background: colors.white05,
      border: `1px solid ${colors.white10}`,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      color: colors.white,
      fontSize: 14,
      boxShadow: `0 0 12px ${tint}22`,
    }}
  >
    {children}
  </div>
);

const SectionHeader: React.FC<{
  label: string;
  count: string;
  tint: string;
  enter: number;
}> = ({ label, count, tint, enter }) => (
  <div
    style={{
      display: 'flex',
      alignItems: 'center',
      gap: 8,
      marginBottom: 4,
      opacity: enter,
      transform: `translateX(${(1 - enter) * 10}px)`,
    }}
  >
    <div
      style={{
        width: 3,
        height: 12,
        borderRadius: 2,
        background: tint,
        boxShadow: `0 0 8px ${tint}`,
      }}
    />
    <div
      style={{
        color: colors.white80,
        fontFamily: fonts.display,
        fontSize: 11,
        fontWeight: 800,
        letterSpacing: 1.5,
      }}
    >
      {label}
    </div>
    <div style={{ flex: 1, height: 1, background: colors.white05 }} />
    <div
      style={{
        color: colors.white40,
        fontFamily: fonts.display,
        fontSize: 10,
        fontWeight: 600,
      }}
    >
      {count}
    </div>
  </div>
);

type TimelineRowProps = {
  task: TaskMock;
  enter: number;
  isFirst: boolean;
  isLast: boolean;
  visualDone: boolean;
  isCompleting: boolean;
  completeTick: number;
  breath: number;
  accent: string;
  compactTime?: boolean;
};

const TimelineRow: React.FC<TimelineRowProps> = ({
  task,
  enter,
  isFirst,
  isLast,
  visualDone,
  isCompleting,
  completeTick,
  breath,
  accent,
  compactTime,
}) => {
  const pColor = priorityColors[task.priority];
  const pLabel = priorityLabels[task.priority];

  const checkScale = isCompleting
    ? interpolate(completeTick, [0.3, 0.6, 0.9], [1, 1.35, 1], {
        extrapolateLeft: 'clamp',
        extrapolateRight: 'clamp',
      })
    : 1;

  const badgeScale = isCompleting
    ? interpolate(completeTick, [0.5, 1], [0, 1], {
        extrapolateLeft: 'clamp',
        extrapolateRight: 'clamp',
      })
    : 1;

  const dotFilled = visualDone;
  const dotBg = dotFilled ? task.color : task.color;
  const dotBorder = dotFilled
    ? `${task.color}4D`
    : `${task.color}80`;

  return (
    <div
      style={{
        display: 'flex',
        alignItems: 'stretch',
        marginBottom: 6,
        opacity: enter,
        transform: `translateX(${(1 - enter) * 20}px) scale(${breath})`,
        transformOrigin: 'left center',
      }}
    >
      {/* Saat — day_timeline_sheet: width 44 */}
      <div
        style={{
          width: 44,
          paddingTop: 16,
          textAlign: 'right',
          paddingRight: 4,
          flexShrink: 0,
        }}
      >
        <div
          style={{
            color: visualDone ? colors.white40 : accent,
            fontFamily: fonts.display,
            fontSize: 12,
            fontWeight: 700,
            lineHeight: 1.1,
          }}
        >
          {task.start}
        </div>
        {task.end && !compactTime && (
          <div
            style={{
              color: colors.white40,
              fontFamily: fonts.display,
              fontSize: 9,
              marginTop: 1,
            }}
          >
            {task.end}
          </div>
        )}
        {compactTime && task.end && (
          <div
            style={{
              color: colors.white40,
              fontFamily: fonts.display,
              fontSize: 9,
              marginTop: 1,
            }}
          >
            {task.end}
          </div>
        )}
      </div>

      <div style={{ width: 10 }} />

      {/* Dikey çizgi + dot — width 24 */}
      <div
        style={{
          width: 24,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          flexShrink: 0,
        }}
      >
        <div
          style={{
            width: 2,
            height: 18,
            background: isFirst ? 'transparent' : `${task.color}33`,
            borderRadius: 2,
          }}
        />
        <div
          style={{
            width: 16,
            height: 16,
            borderRadius: '50%',
            background: dotFilled ? `${task.color}33` : dotBg,
            border: `2px solid ${dotBorder}`,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: colors.white,
            fontSize: 10,
            fontWeight: 900,
            boxShadow: dotFilled
              ? 'none'
              : `0 0 8px ${task.color}4D, 0 0 1px ${task.color}99`,
            transform: `scale(${checkScale})`,
          }}
        >
          {dotFilled && '✓'}
        </div>
        <div
          style={{
            flex: 1,
            minHeight: 8,
            width: 2,
            background: isLast ? 'transparent' : `${task.color}1F`,
          }}
        />
      </div>

      <div style={{ width: 10 }} />

      {/* Kart — _buildDetailCard */}
      <div
        style={{
          flex: 1,
          marginBottom: 4,
          padding: 14,
          background: colors.white05,
          borderRadius: 16,
          borderLeft: `3px solid ${task.color}`,
        }}
      >
        <div style={{ display: 'flex', alignItems: 'flex-start', gap: 10 }}>
          <div
            style={{
              width: 34,
              height: 34,
              borderRadius: 10,
              background: `${task.color}1A`,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              flexShrink: 0,
              color: task.color,
              fontSize: 16,
              fontWeight: 700,
            }}
          >
            ✓
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              {visualDone && (
                <span style={{ color: '#22C55E', fontSize: 14 }}>✓</span>
              )}
              <div
                style={{
                  flex: 1,
                  color: visualDone ? colors.white60 : colors.white,
                  fontFamily: fonts.display,
                  fontSize: 14,
                  fontWeight: 600,
                  textDecoration: visualDone ? 'line-through' : 'none',
                  overflow: 'hidden',
                  textOverflow: 'ellipsis',
                  whiteSpace: 'nowrap',
                }}
              >
                {task.title}
              </div>
              {visualDone ? (
                <span
                  style={{
                    padding: '2px 6px',
                    borderRadius: 4,
                    background: 'rgba(34,197,94,0.1)',
                    border: '1px solid rgba(34,197,94,0.2)',
                    color: '#22C55E',
                    fontFamily: fonts.display,
                    fontSize: 9,
                    fontWeight: 800,
                    transform: `scale(${badgeScale})`,
                  }}
                >
                  TAMAM
                </span>
              ) : (
                <span style={{ color: colors.white40, fontSize: 14 }}>⋮</span>
              )}
            </div>

            {/* Zaman chip — schedule row */}
            {!compactTime && task.end && (
              <div
                style={{
                  marginTop: 8,
                  marginLeft: 44,
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: 6,
                  padding: '4px 8px',
                  borderRadius: 8,
                  background: colors.white05,
                }}
              >
                <span style={{ fontSize: 11, opacity: 0.5 }}>⏱</span>
                <span
                  style={{
                    fontFamily: fonts.display,
                    fontSize: 11,
                    fontWeight: 500,
                    color: colors.white60,
                  }}
                >
                  {task.start} – {task.end}
                </span>
                <span
                  style={{
                    width: 3,
                    height: 3,
                    borderRadius: '50%',
                    background: colors.white20,
                  }}
                />
                <span
                  style={{
                    fontFamily: fonts.display,
                    fontSize: 11,
                    fontWeight: 600,
                    color: `${accent}99`,
                  }}
                >
                  {task.durationMin} dk
                </span>
              </div>
            )}

            {/* Meta chip'ler */}
            <div
              style={{
                display: 'flex',
                flexWrap: 'wrap',
                alignItems: 'center',
                gap: 6,
                marginTop: 8,
                marginLeft: compactTime ? 0 : 44,
              }}
            >
              <Chip>
                <span style={{ opacity: 0.6, marginRight: 3 }}>⏱</span>
                {task.durationMin} dk
              </Chip>
              <Chip bg={`${pColor}22`} border={`${pColor}55`} color={pColor}>
                <span
                  style={{
                    width: 5,
                    height: 5,
                    borderRadius: '50%',
                    background: pColor,
                    display: 'inline-block',
                    marginRight: 4,
                  }}
                />
                {pLabel}
              </Chip>
              {task.recurring && (
                <Chip bg={`${accent}1C`} border={`${accent}55`} color={accent}>
                  ↻ {task.recurring}
                </Chip>
              )}
              {task.tags?.slice(0, 2).map((tag) => (
                <Chip key={tag}>#{tag}</Chip>
              ))}
              <div style={{ flex: 1 }} />
              {task.xp !== undefined && (
                <span
                  style={{
                    color: visualDone ? '#FBBF24' : accent,
                    fontFamily: fonts.display,
                    fontSize: 10.5,
                    fontWeight: 800,
                  }}
                >
                  ⚡ +{task.xp} XP
                </span>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

const Chip: React.FC<{
  children: React.ReactNode;
  bg?: string;
  border?: string;
  color?: string;
}> = ({
  children,
  bg = colors.white05,
  border = colors.white10,
  color = colors.white60,
}) => (
  <span
    style={{
      padding: '2px 7px',
      borderRadius: 6,
      background: bg,
      border: `1px solid ${border}`,
      color,
      fontFamily: fonts.display,
      fontSize: 9.5,
      fontWeight: 700,
      display: 'inline-flex',
      alignItems: 'center',
    }}
  >
    {children}
  </span>
);
