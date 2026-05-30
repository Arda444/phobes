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
 * Takvim sahnesi — gerçek Phobes Calendar UI (210 kare / 7 s):
 * - calendar_controller.dart: 6 stream (görev, randevu, müşteri randevusu,
 *   not, ilaç, alışkanlık) → statsModuleColors
 * - calendar_screen.dart monthly: TableCalendar toolbar, 35 günlük grid,
 *   4 px modül renkli etkinlik bar'ları, bugün turuncu gradient
 * - Alt panel: "Bugün" listesi, sol modül rengi şeridi
 * - Animasyon: yavaş dalga dolgu, bugün nabız, ay başlığı mikro kayma,
 *   etkinlik genişleme vurgusu
 */

// 6 calendar stream — calendar_controller.dart CalendarData
type ModuleKey =
  | 'task'
  | 'medication'
  | 'appointment'
  | 'clientAppointment'
  | 'habit'
  | 'note';

const MODULE_COLORS: Record<ModuleKey, string> = {
  task: statsModuleColors.tasks,
  medication: statsModuleColors.medications,
  appointment: statsModuleColors.appointments,
  clientAppointment: statsModuleColors.teams,
  habit: statsModuleColors.habits,
  note: statsModuleColors.notes,
};

const MODULE_ICONS: Record<ModuleKey, string> = {
  task: '✓',
  medication: '◉',
  appointment: '◷',
  clientAppointment: '◍',
  habit: '🔥',
  note: '✎',
};

// PhobesTheme.todayGradient — lib/core/phobes_theme.dart
const TODAY_GRADIENT = 'linear-gradient(135deg, #E65100 0%, #EF6C00 100%)';
const TODAY_BORDER = 'rgba(255, 183, 77, 0.55)';
const CARD_GRADIENT = 'linear-gradient(135deg, #212121 0%, #181818 100%)';

type DayCell = {
  num: number;
  inMonth: boolean;
  events: ModuleKey[];
};

// 5 × 7 = 35 hücre, Pazartesi başlangıç. Mayıs 2026, bugün = 27 Mayıs (index 30)
const TODAY_INDEX = 30;

const EVENT_MAP: Record<number, ModuleKey[]> = {
  2: ['task'],
  5: ['medication'],
  7: ['task', 'medication'],
  8: ['appointment'],
  11: ['habit'],
  12: ['task', 'clientAppointment'],
  13: ['medication'],
  14: ['task', 'medication', 'habit'],
  18: ['habit'],
  19: ['task'],
  20: ['appointment', 'medication'],
  21: ['note'],
  25: ['task', 'medication'],
  26: ['clientAppointment', 'task'],
  27: ['medication', 'appointment', 'task', 'habit'],
  28: ['task', 'habit'],
  29: ['note'],
  30: ['medication'],
};

const buildDays = (): DayCell[] => {
  const out: DayCell[] = [];
  for (let d = 27; d <= 30; d++) {
    out.push({ num: d, inMonth: false, events: [] });
  }
  for (let d = 1; d <= 31; d++) {
    out.push({ num: d, inMonth: true, events: EVENT_MAP[d] ?? [] });
  }
  return out;
};

const days = buildDays();
const weekdayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

type UpcomingEvent = {
  time: string;
  title: string;
  subtitle: string;
  type: ModuleKey;
};

const upcoming: UpcomingEvent[] = [
  {
    time: '09:00',
    title: 'Sabah ilacı',
    subtitle: 'D vitamini · 1 doz',
    type: 'medication',
  },
  {
    time: '11:30',
    title: 'Müşteri görüşmesi',
    subtitle: 'Brand kickoff · Ofis',
    type: 'clientAppointment',
  },
  {
    time: '14:00',
    title: 'Tasarım sunumu',
    subtitle: 'Yüksek öncelik',
    type: 'task',
  },
  {
    time: '18:30',
    title: 'Spor — 45 dk',
    subtitle: '12 günlük seri',
    type: 'habit',
  },
];

const SELECTED_EVENT_INDEX = 1;

const waveReveal = (frame: number, cellIndex: number): number => {
  const row = Math.floor(cellIndex / 7);
  const col = cellIndex % 7;
  const offset = row * 2.4 + col * 1.15;
  return interpolate(frame, [offset + 2, offset + 22], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.out(Easing.cubic),
  });
};

export const CalendarScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const theme = moduleThemes.calendar;

  const toolbarEnter = spring({
    frame: frame - 2,
    fps,
    config: { damping: 14, stiffness: 100 },
  });

  const segmentEnter = spring({
    frame: frame - 6,
    fps,
    config: { damping: 14 },
  });

  // Bugün hücresi nabız — frame 35'ten itibaren sürekli
  const pulseT = Math.max(0, frame - 35) * 0.16;
  const todayPulse = 1 + Math.sin(pulseT) * 0.045;
  const todayGlow = 0.28 + Math.sin(pulseT) * 0.16;

  // Ay başlığı mikro kayma — mock sayfa değişimi (frame 72–98)
  const monthShiftProgress = interpolate(
    frame,
    [72, 78, 86, 98],
    [0, 1, -0.6, 0],
    {
      extrapolateLeft: 'clamp',
      extrapolateRight: 'clamp',
      easing: Easing.inOut(Easing.sin),
    },
  );
  const monthShift = monthShiftProgress * 16;
  const monthOpacity =
    1 - Math.abs(monthShiftProgress) * 0.22;

  // Alt listede seçili etkinlik genişleme vurgusu (frame 118+)
  const selectedHighlight = spring({
    frame: frame - 118,
    fps,
    config: { damping: 11, stiffness: 82 },
  });

  // Bugün hücresindeki bar genişlemesi — etkinlik vurgusu ile senkron
  const todayBarExpand = interpolate(
    frame,
    [118, 132, 158, 172],
    [1, 1.45, 1.45, 1],
    {
      extrapolateLeft: 'clamp',
      extrapolateRight: 'clamp',
      easing: Easing.inOut(Easing.quad),
    },
  );

  const listSectionEnter = spring({
    frame: frame - 88,
    fps,
    config: { damping: 14 },
  });

  return (
    <SceneFrame
      tint={theme.color}
      title={moduleSlogans.calendar.title}
      subtitle={moduleSlogans.calendar.subtitle}
      transition={moduleSlogans.calendar.transition}
      badge="☷"
      chips={['Görev', 'Randevu', 'İlaç', 'Alışkanlık']}
    >
      <PhoneFrame>
        <div
          style={{
            paddingTop: 88,
            paddingLeft: 14,
            paddingRight: 14,
            paddingBottom: 12,
            height: '100%',
            display: 'flex',
            flexDirection: 'column',
            overflow: 'hidden',
            background: colors.surface,
          }}
        >
          {/* TableCalendar headerStyle — ay navigasyonu */}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              marginBottom: 10,
              opacity: toolbarEnter,
              transform: `translateY(${(1 - toolbarEnter) * 10}px)`,
            }}
          >
            <div
              style={{
                width: 28,
                height: 28,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: theme.color,
                fontFamily: fonts.display,
                fontSize: 18,
                fontWeight: 700,
              }}
            >
              ‹
            </div>

            <div
              style={{
                display: 'flex',
                alignItems: 'baseline',
                gap: 6,
                transform: `translateX(${monthShift}px)`,
                opacity: monthOpacity,
              }}
            >
              <span
                style={{
                  color: colors.white,
                  fontFamily: fonts.display,
                  fontSize: 16,
                  fontWeight: 800,
                  letterSpacing: -0.3,
                }}
              >
                Mayıs
              </span>
              <span
                style={{
                  color: colors.white60,
                  fontFamily: fonts.display,
                  fontSize: 14,
                  fontWeight: 600,
                }}
              >
                2026
              </span>
            </div>

            <div
              style={{
                width: 28,
                height: 28,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: theme.color,
                fontFamily: fonts.display,
                fontSize: 18,
                fontWeight: 700,
              }}
            >
              ›
            </div>
          </div>

          {/* Ay / Hafta / Gün görünüm seçici */}
          <div
            style={{
              alignSelf: 'center',
              padding: 3,
              background: colors.white05,
              border: `1px solid ${colors.white10}`,
              borderRadius: 999,
              display: 'flex',
              gap: 2,
              marginBottom: 10,
              opacity: segmentEnter,
              transform: `scale(${0.92 + segmentEnter * 0.08})`,
            }}
          >
            {['Ay', 'Hafta', 'Gün'].map((label, i) => {
              const isActive = i === 0;
              return (
                <div
                  key={label}
                  style={{
                    padding: '5px 15px',
                    borderRadius: 999,
                    fontFamily: fonts.display,
                    fontSize: 11,
                    fontWeight: 700,
                    color: isActive ? colors.white : colors.white60,
                    background: isActive ? theme.color : 'transparent',
                    boxShadow: isActive
                      ? `0 4px 12px ${theme.color}77`
                      : 'none',
                  }}
                >
                  {label}
                </div>
              );
            })}
          </div>

          {/* Hafta günleri — daysOfWeekStyle */}
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(7, 1fr)',
              gap: 2,
              marginBottom: 4,
              padding: '0 1px',
            }}
          >
            {weekdayLabels.map((d, i) => {
              const isWeekend = i >= 5;
              return (
                <div
                  key={d}
                  style={{
                    textAlign: 'center',
                    fontFamily: fonts.display,
                    fontSize: 11,
                    fontWeight: 700,
                    color: isWeekend ? 'rgba(255, 107, 107, 0.85)' : colors.white60,
                  }}
                >
                  {d}
                </div>
              );
            })}
          </div>

          {/* 35 günlük grid — _buildMonthlyCell */}
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(7, 1fr)',
              gap: 2,
            }}
          >
            {days.map((day, i) => {
              const reveal = waveReveal(frame, i);
              const isToday = i === TODAY_INDEX;
              const dayColIndex = i % 7;
              const isWeekend = dayColIndex >= 5;

              const baseScale = 0.55 + reveal * 0.45;
              const cellScale = isToday ? baseScale * todayPulse : baseScale;

              const numberColor = isToday
                ? colors.white
                : day.inMonth
                  ? isWeekend
                    ? 'rgba(255, 107, 107, 0.85)'
                    : colors.white80
                  : 'rgba(255,255,255,0.25)';

              return (
                <div
                  key={i}
                  style={{
                    aspectRatio: '1 / 1.05',
                    background: isToday ? TODAY_GRADIENT : CARD_GRADIENT,
                    border: `1px solid ${
                      isToday
                        ? TODAY_BORDER
                        : day.inMonth
                          ? 'rgba(255,255,255,0.08)'
                          : 'rgba(255,255,255,0.04)'
                    }`,
                    borderRadius: 8,
                    padding: '3px 2px 4px',
                    display: 'flex',
                    flexDirection: 'column',
                    opacity: reveal,
                    transform: `scale(${cellScale})`,
                    boxShadow: isToday
                      ? `0 0 ${10 + todayGlow * 16}px rgba(239, 108, 0, ${todayGlow})`
                      : 'none',
                    overflow: 'hidden',
                  }}
                >
                  <div
                    style={{
                      textAlign: 'center',
                      fontFamily: fonts.display,
                      fontSize: isToday ? 12 : 11,
                      fontWeight: isToday ? 800 : 500,
                      color: numberColor,
                      lineHeight: 1.1,
                      paddingTop: 2,
                    }}
                  >
                    {day.num}
                  </div>

                  {/* _buildMonthlyCellContent — 4 px modül bar'ları */}
                  {day.events.length > 0 && (
                    <div
                      style={{
                        flex: 1,
                        display: 'flex',
                        flexDirection: 'column',
                        alignItems: 'center',
                        justifyContent: 'flex-start',
                        gap: 3,
                        paddingTop: 2,
                      }}
                    >
                      {day.events.slice(0, 3).map((evType, j) => {
                        const barDelay = i * 0.35 + j * 1.8;
                        const barReveal = interpolate(
                          frame,
                          [barDelay + 8, barDelay + 24],
                          [0, 1],
                          {
                            extrapolateLeft: 'clamp',
                            extrapolateRight: 'clamp',
                            easing: Easing.out(Easing.cubic),
                          },
                        );
                        const expand =
                          isToday && selectedHighlight > 0
                            ? todayBarExpand
                            : 1;

                        return (
                          <div
                            key={j}
                            style={{
                              width: `${Math.min(24 * expand, 34)}px`,
                              height: 4,
                              borderRadius: 2,
                              background: isToday
                                ? 'rgba(255,255,255,0.88)'
                                : MODULE_COLORS[evType],
                              opacity: barReveal,
                              transform: `scaleX(${barReveal * expand})`,
                              transformOrigin: 'center',
                              boxShadow:
                                isToday && selectedHighlight > 0.3
                                  ? `0 0 6px rgba(255,255,255,${selectedHighlight * 0.5})`
                                  : 'none',
                            }}
                          />
                        );
                      })}
                      {day.events.length > 3 && (
                        <div
                          style={{
                            fontSize: 7,
                            fontWeight: 700,
                            color: isToday
                              ? colors.white
                              : 'rgba(255,255,255,0.55)',
                            lineHeight: 1,
                            opacity: reveal,
                          }}
                        >
                          +{day.events.length - 3}
                        </div>
                      )}
                    </div>
                  )}
                </div>
              );
            })}
          </div>

          {/* Alt panel — Bugün listesi, modül renkli sol şerit */}
          <div
            style={{
              marginTop: 10,
              flex: 1,
              display: 'flex',
              flexDirection: 'column',
              minHeight: 0,
              opacity: listSectionEnter,
              transform: `translateY(${(1 - listSectionEnter) * 14}px)`,
            }}
          >
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 7,
                marginBottom: 8,
              }}
            >
              <div
                style={{
                  color: colors.white,
                  fontFamily: fonts.display,
                  fontSize: 14,
                  fontWeight: 800,
                }}
              >
                Bugün
              </div>
              <div
                style={{
                  padding: '2px 7px',
                  borderRadius: 6,
                  background: colors.white05,
                  color: colors.white60,
                  fontFamily: fonts.display,
                  fontSize: 10,
                  fontWeight: 500,
                }}
              >
                4 etkinlik
              </div>
              <div style={{ flex: 1 }} />
              <div
                style={{
                  color: colors.white40,
                  fontFamily: fonts.display,
                  fontSize: 10,
                }}
              >
                27 May · Çar
              </div>
            </div>

            {upcoming.map((e, i) => {
              const enter = spring({
                frame: frame - 92 - i * 4,
                fps,
                config: { damping: 14 },
              });
              const isSelected = i === SELECTED_EVENT_INDEX;
              const color = MODULE_COLORS[e.type];
              const highlight = isSelected ? selectedHighlight : 0;
              const cardScale = 1 + highlight * 0.04;
              const borderWidth = 3 + highlight * 1.5;

              return (
                <div
                  key={i}
                  style={{
                    display: 'flex',
                    alignItems: 'stretch',
                    marginBottom: 5,
                    borderRadius: 12,
                    overflow: 'hidden',
                    opacity: enter,
                    transform: `translateX(${(1 - enter) * 28}px) scale(${cardScale})`,
                    boxShadow:
                      highlight > 0.2
                        ? `0 6px 20px ${color}${Math.round(highlight * 90)
                            .toString(16)
                            .padStart(2, '0')}`
                        : 'none',
                  }}
                >
                  <div
                    style={{
                      width: borderWidth,
                      flexShrink: 0,
                      background: color,
                      boxShadow:
                        highlight > 0.15
                          ? `0 0 ${8 + highlight * 10}px ${color}`
                          : 'none',
                    }}
                  />
                  <div
                    style={{
                      flex: 1,
                      display: 'flex',
                      alignItems: 'center',
                      gap: 9,
                      padding: '8px 10px',
                      background:
                        highlight > 0.1
                          ? `linear-gradient(90deg, ${color}22, ${colors.white05})`
                          : colors.white05,
                      border: `1px solid ${highlight > 0.1 ? `${color}55` : colors.white10}`,
                      borderLeft: 'none',
                    }}
                  >
                    <div
                      style={{
                        color,
                        fontFamily: fonts.display,
                        fontWeight: 800,
                        fontSize: 12,
                        minWidth: 40,
                      }}
                    >
                      {e.time}
                    </div>
                    <div
                      style={{
                        width: 26,
                        height: 26,
                        borderRadius: 8,
                        background: `${color}18`,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        color,
                        fontFamily: fonts.display,
                        fontSize: 13,
                        fontWeight: 800,
                      }}
                    >
                      {MODULE_ICONS[e.type]}
                    </div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div
                        style={{
                          color: colors.white,
                          fontFamily: fonts.display,
                          fontWeight: 700,
                          fontSize: 12,
                          overflow: 'hidden',
                          textOverflow: 'ellipsis',
                          whiteSpace: 'nowrap',
                        }}
                      >
                        {e.title}
                      </div>
                      <div
                        style={{
                          color: colors.white60,
                          fontFamily: fonts.display,
                          fontSize: 9,
                          marginTop: 1,
                          overflow: 'hidden',
                          textOverflow: 'ellipsis',
                          whiteSpace: 'nowrap',
                        }}
                      >
                        {e.subtitle}
                      </div>
                    </div>
                    {isSelected && highlight > 0.45 && (
                      <div
                        style={{
                          padding: '2px 7px',
                          borderRadius: 999,
                          background: color,
                          color: colors.white,
                          fontFamily: fonts.display,
                          fontSize: 8,
                          fontWeight: 800,
                          letterSpacing: 0.4,
                          textTransform: 'uppercase',
                          opacity: (highlight - 0.45) / 0.55,
                        }}
                      >
                        Şimdi
                      </div>
                    )}
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
