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
 * Alışkanlık sahnesi — lib/screens/habit/habit_screen.dart
 * PhobesModuleHeader + _buildHabitCard (48×48 ateş, streak rozeti, 34×34 tamamla).
 * Promo: hero streak kartı, heatmap dalga, tamamlama konfeti. 90 kare @ 30fps.
 */

const HABIT_GREEN = statsModuleColors.habits; // #22C55E
const FLAME_ORANGE = '#F97316';
const FLAME_AMBER = '#F59E0B';
const FLAME_GREY = '#9CA3AF';

const CONFETTI = [
  '#22C55E',
  '#3B82F6',
  '#F472B6',
  '#F97316',
  '#A855F7',
] as const;

type HabitRow = {
  title: string;
  streak: number;
  done: boolean;
  subtitle: string;
};

const habits: HabitRow[] = [
  { title: 'Sabah meditasyonu', streak: 14, done: false, subtitle: 'Zinciri kırma!' },
  { title: 'Su iç (2L)', streak: 23, done: false, subtitle: 'Zinciri kırma!' },
  { title: 'Kitap oku', streak: 47, done: true, subtitle: 'Harika gidiyorsun!' },
];

const COMPLETE_INDEX = 0;
const HERO_TARGET = 47;

const HEATMAP_W = 7;
const HEATMAP_H = 7;

const heatmap: number[][] = Array.from({ length: HEATMAP_W }, (_, w) =>
  Array.from({ length: HEATMAP_H }, (_, d) => {
    const r = (w * 7 + d) % 11;
    if (w >= 5) return r % 5 === 0 ? 0 : 1 + ((w + d) % 3);
    if (r === 0) return 0;
    return (w + d * 2) % 4;
  }),
);
heatmap[HEATMAP_W - 1][HEATMAP_H - 1] = 3;

const streakColor = (streak: number, done: boolean): string => {
  if (done) return '#22C55E';
  if (streak >= 7) return FLAME_ORANGE;
  if (streak >= 3) return FLAME_AMBER;
  return FLAME_GREY;
};

export const HabitsScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const theme = moduleThemes.habits;

  const headerEnter = spring({ frame: frame - 4, fps, config: { damping: 16 } });
  const heroEnter = spring({ frame: frame - 10, fps, config: { damping: 14 } });
  const breath = 1 + Math.sin(frame / 14) * 0.005;

  const heroCount = Math.floor(
    interpolate(frame, [14, 52], [0, HERO_TARGET], {
      extrapolateLeft: 'clamp',
      extrapolateRight: 'clamp',
      easing: Easing.out(Easing.cubic),
    }),
  );

  const completeAt = 54;
  const checkPop = spring({
    frame: frame - completeAt,
    fps,
    config: { damping: 9, stiffness: 170 },
  });

  const confettiOn = frame >= completeAt && frame < completeAt + 28;
  const confettiFrame = frame - completeAt;

  const lastGlow = interpolate(frame, [72, 80, 88], [0, 1, 0.5], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  return (
    <SceneFrame
      tint={theme.color}
      title={moduleSlogans.habits.title}
      subtitle={moduleSlogans.habits.subtitle}
      transition={moduleSlogans.habits.transition}
      badge="🔥"
      chips={['Seri', 'Hatırlatıcı', 'Takip']}
    >
      <PhoneFrame>
        <div
          style={{
            paddingTop: 72,
            height: '100%',
            background: colors.surface,
            overflow: 'hidden',
            position: 'relative',
          }}
        >
          {confettiOn && <FullConfetti frame={confettiFrame} />}

          {/* PhobesModuleHeader — habit_screen.dart */}
          <div
            style={{
              padding: '8px 20px 10px',
              opacity: headerEnter,
              transform: `translateY(${(1 - headerEnter) * -12}px)`,
            }}
          >
            <div style={{ display: 'flex', alignItems: 'flex-start', gap: 10 }}>
              <div
                style={{
                  width: 36,
                  height: 36,
                  borderRadius: 11,
                  background: `${HABIT_GREEN}22`,
                  border: `1px solid ${HABIT_GREEN}44`,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontSize: 20,
                  flexShrink: 0,
                }}
              >
                🌿
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div
                  style={{
                    color: colors.white,
                    fontFamily: fonts.display,
                    fontSize: 22,
                    fontWeight: 700,
                    letterSpacing: -0.3,
                    lineHeight: 1.1,
                  }}
                >
                  Alışkanlıklar
                </div>
                <div
                  style={{
                    color: colors.white60,
                    fontFamily: fonts.display,
                    fontSize: 13,
                    fontWeight: 500,
                    marginTop: 2,
                  }}
                >
                  Zinciri kırma! 💪
                </div>
              </div>
              <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
                <div
                  style={{
                    width: 32,
                    height: 32,
                    borderRadius: 10,
                    background: colors.white05,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: 16,
                    color: '#FDE68A',
                  }}
                >
                  🔔
                </div>
                <div
                  style={{
                    width: 32,
                    height: 32,
                    borderRadius: 10,
                    background: `linear-gradient(135deg, ${HABIT_GREEN}, #15803D)`,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    color: colors.white,
                    fontFamily: fonts.display,
                    fontWeight: 800,
                    fontSize: 20,
                    boxShadow: `0 6px 14px ${HABIT_GREEN}55`,
                  }}
                >
                  +
                </div>
              </div>
            </div>
          </div>

          <div style={{ padding: '0 20px 12px' }}>
            {/* Hero streak */}
            <div
              style={{
                padding: '12px 14px',
                borderRadius: 20,
                background: `linear-gradient(135deg, ${HABIT_GREEN}, #15803D)`,
                boxShadow: `0 12px 28px ${HABIT_GREEN}44`,
                marginBottom: 10,
                display: 'flex',
                alignItems: 'center',
                gap: 12,
                transform: `scale(${heroEnter * breath})`,
                opacity: heroEnter,
                position: 'relative',
                overflow: 'hidden',
              }}
            >
              <div
                style={{
                  position: 'absolute',
                  top: -24,
                  right: -16,
                  width: 100,
                  height: 100,
                  borderRadius: '50%',
                  background:
                    'radial-gradient(circle, rgba(255,255,255,0.22) 0%, transparent 70%)',
                }}
              />
              <div
                style={{
                  width: 44,
                  height: 44,
                  borderRadius: 14,
                  background: 'rgba(255,255,255,0.16)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontSize: 26,
                }}
              >
                🔥
              </div>
              <div style={{ flex: 1 }}>
                <div
                  style={{
                    color: 'rgba(255,255,255,0.8)',
                    fontFamily: fonts.display,
                    fontSize: 9,
                    fontWeight: 800,
                    letterSpacing: 1.2,
                    textTransform: 'uppercase',
                  }}
                >
                  En uzun seri
                </div>
                <div
                  style={{
                    color: colors.white,
                    fontFamily: fonts.display,
                    fontSize: 30,
                    fontWeight: 900,
                    letterSpacing: -0.8,
                    lineHeight: 1,
                  }}
                >
                  {heroCount}
                  <span style={{ fontSize: 14, fontWeight: 700, marginLeft: 4 }}>
                    gün
                  </span>
                </div>
                <div
                  style={{
                    color: 'rgba(255,255,255,0.88)',
                    fontFamily: fonts.display,
                    fontSize: 11,
                    fontWeight: 600,
                    marginTop: 2,
                  }}
                >
                  Kitap oku
                </div>
              </div>
            </div>

            {/* Habit cards — _buildHabitCard */}
            {habits.map((h, i) => {
              const enter = spring({
                frame: frame - 18 - i * 6,
                fps,
                config: { damping: 14, mass: 0.85 },
              });
              const isTarget = i === COMPLETE_INDEX;
              const done =
                h.done || (isTarget && checkPop > 0.45);
              const sc = streakColor(h.streak, done);
              const displayStreak =
                isTarget && checkPop > 0.45 ? h.streak + 1 : h.streak;

              return (
                <div
                  key={h.title}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: 0,
                    padding: '12px 16px',
                    marginBottom: 12,
                    background: colors.surfaceLight,
                    borderRadius: 20,
                    border: `1px solid ${colors.white10}`,
                    opacity: enter,
                    transform: `translateX(${(1 - enter) * 24}px)`,
                  }}
                >
                  <div
                    style={{
                      width: 48,
                      height: 48,
                      borderRadius: 14,
                      background: done
                        ? 'linear-gradient(135deg, rgba(34,197,94,0.2), rgba(34,197,94,0.08))'
                        : `linear-gradient(135deg, ${sc}1a, ${sc}0d)`,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontSize: 24,
                      color: done ? '#22C55E' : sc,
                      flexShrink: 0,
                    }}
                  >
                    🔥
                  </div>
                  <div style={{ width: 14 }} />
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div
                      style={{
                        color: done ? colors.white40 : colors.white,
                        fontFamily: fonts.display,
                        fontSize: 15,
                        fontWeight: 700,
                        textDecoration: done ? 'line-through' : 'none',
                        whiteSpace: 'nowrap',
                        overflow: 'hidden',
                        textOverflow: 'ellipsis',
                      }}
                    >
                      {h.title}
                    </div>
                    <div
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: 6,
                        marginTop: 3,
                      }}
                    >
                      <span
                        style={{
                          padding: '2px 6px',
                          borderRadius: 4,
                          background: `${sc}1a`,
                          color: sc,
                          fontFamily: fonts.display,
                          fontSize: 10,
                          fontWeight: 700,
                          letterSpacing: 0.5,
                        }}
                      >
                        {displayStreak} GÜN
                      </span>
                      <span
                        style={{
                          color: colors.white40,
                          fontFamily: fonts.display,
                          fontSize: 11,
                          fontWeight: 500,
                          overflow: 'hidden',
                          textOverflow: 'ellipsis',
                          whiteSpace: 'nowrap',
                        }}
                      >
                        {done ? 'Harika gidiyorsun!' : h.subtitle}
                      </span>
                    </div>
                  </div>
                  <div style={{ width: 8 }} />
                  <div
                    style={{
                      width: 34,
                      height: 34,
                      borderRadius: 10,
                      flexShrink: 0,
                      background: done
                        ? 'linear-gradient(135deg, #10B981, #059669)'
                        : colors.white05,
                      border: done
                        ? 'none'
                        : `2px solid ${colors.white20}`,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      color: colors.white,
                      fontSize: 18,
                      fontWeight: 900,
                      boxShadow: done
                        ? '0 4px 10px rgba(16,185,129,0.35)'
                        : 'none',
                      transform: isTarget
                        ? `scale(${0.88 + checkPop * 0.12})`
                        : undefined,
                    }}
                  >
                    {done ? '✓' : null}
                  </div>
                </div>
              );
            })}

            {/* Heatmap — 7×7 wave */}
            <div
              style={{
                padding: 10,
                background: colors.white05,
                border: `1px solid ${colors.white10}`,
                borderRadius: 14,
                marginTop: 2,
              }}
            >
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  marginBottom: 8,
                }}
              >
                <span
                  style={{
                    color: colors.white60,
                    fontFamily: fonts.display,
                    fontSize: 10,
                    fontWeight: 800,
                    letterSpacing: 1.2,
                    textTransform: 'uppercase',
                  }}
                >
                  Son 7 hafta
                </span>
                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: 3,
                    color: colors.white40,
                    fontFamily: fonts.display,
                    fontSize: 8,
                  }}
                >
                  <span>az</span>
                  {[0.15, 0.4, 0.65, 1].map((a) => (
                    <span
                      key={a}
                      style={{
                        width: 8,
                        height: 8,
                        borderRadius: 2,
                        background: HABIT_GREEN,
                        opacity: a,
                      }}
                    />
                  ))}
                  <span>çok</span>
                </div>
              </div>
              <div
                style={{
                  display: 'grid',
                  gridTemplateColumns: `repeat(${HEATMAP_W}, 1fr)`,
                  gap: 3,
                }}
              >
                {Array.from({ length: HEATMAP_W * HEATMAP_H }).map((_, i) => {
                  const colIdx = i % HEATMAP_W;
                  const rowIdx = Math.floor(i / HEATMAP_W);
                  const level = heatmap[colIdx][rowIdx];
                  const waveDelay =
                    (HEATMAP_W - 1 - colIdx) * 2.2 + rowIdx * 0.5;
                  const reveal = spring({
                    frame: frame - 28 - waveDelay,
                    fps,
                    config: { damping: 15, mass: 0.65 },
                  });
                  const isLast =
                    colIdx === HEATMAP_W - 1 && rowIdx === HEATMAP_H - 1;
                  const baseAlpha = level === 0 ? 0.08 : 0.22 + level * 0.2;
                  return (
                    <div
                      key={i}
                      style={{
                        aspectRatio: '1',
                        borderRadius: 3,
                        background: level === 0 ? colors.white05 : HABIT_GREEN,
                        opacity:
                          0.08 + reveal * baseAlpha + (isLast ? lastGlow * 0.35 : 0),
                        transform: `scale(${
                          (0.55 + reveal * 0.45) *
                          (1 + (isLast ? lastGlow * 0.12 : 0))
                        })`,
                        boxShadow:
                          isLast && lastGlow > 0
                            ? `0 0 ${8 + lastGlow * 12}px ${HABIT_GREEN}`
                            : 'none',
                      }}
                    />
                  );
                })}
              </div>
            </div>
          </div>
        </div>
      </PhoneFrame>
    </SceneFrame>
  );
};

const FullConfetti: React.FC<{ frame: number }> = ({ frame }) => (
  <div
    style={{
      position: 'absolute',
      top: 60,
      left: 0,
      right: 0,
      height: 200,
      pointerEvents: 'none',
      zIndex: 20,
      overflow: 'hidden',
    }}
  >
    {CONFETTI.flatMap((col, ci) =>
      Array.from({ length: 8 }).map((_, pi) => {
        const seed = ci * 17 + pi * 31;
        const angle = (seed % 360) * (Math.PI / 180);
        const dist = Math.min(frame * 2.8 + (seed % 12), 120 + (seed % 40));
        const fade = interpolate(frame, [0, 8, 26], [1, 1, 0], {
          extrapolateLeft: 'clamp',
          extrapolateRight: 'clamp',
        });
        const x = 195 + Math.cos(angle) * dist * (0.6 + (pi % 3) * 0.2);
        const y = 40 + Math.sin(angle) * dist * 0.7 + frame * 1.2;
        return (
          <div
            key={`${ci}-${pi}`}
            style={{
              position: 'absolute',
              left: x,
              top: y,
              width: pi % 2 === 0 ? 7 : 5,
              height: pi % 2 === 0 ? 5 : 7,
              borderRadius: pi % 3 === 0 ? '50%' : 2,
              background: col,
              opacity: fade,
              transform: `rotate(${frame * 8 + seed}deg)`,
            }}
          />
        );
      }),
    )}
  </div>
);
