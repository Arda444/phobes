import React from 'react';
import {
  useCurrentFrame,
  useVideoConfig,
  spring,
  interpolate,
} from 'remotion';
import { SceneFrame } from '../components/SceneFrame';
import { PhoneFrame } from '../components/PhoneFrame';
import { colors, fonts, moduleThemes, statsModuleColors } from '../theme';
import { moduleSlogans } from '../moduleSlogans';

/**
 * Randevu sahnesi — appointment_screen.dart + timeline_view.dart
 * İstatistik satırı, görünüm modu, tarih navigatörü, timeline blokları.
 * Promo: timeline genişleme, QR flip. 90 kare @ 30fps.
 */

const APPT_CYAN = statsModuleColors.appointments; // #06B6D4

const HOUR_HEIGHT = 54;
const HOUR_START = 9;
const HOURS = [9, 10, 11, 12, 13];

const stats = [
  { label: 'Tümü', value: '4', color: '#3B82F6' },
  { label: 'Bekliyor', value: '1', color: '#F59E0B' },
  { label: 'Onaylı', value: '2', color: '#10B981' },
  { label: 'İptal', value: '1', color: '#EF4444' },
];

const QR: number[][] = [
  [1, 1, 1, 1, 1, 1, 1, 0, 1],
  [1, 0, 0, 0, 0, 0, 1, 1, 0],
  [1, 0, 1, 1, 1, 0, 1, 0, 1],
  [1, 0, 1, 1, 1, 0, 1, 1, 1],
  [1, 0, 1, 1, 1, 0, 1, 0, 0],
  [1, 0, 0, 0, 0, 0, 1, 1, 1],
  [1, 1, 1, 1, 1, 1, 1, 0, 1],
  [0, 1, 0, 1, 0, 1, 0, 1, 0],
  [1, 0, 1, 0, 1, 1, 1, 0, 1],
];

const rgba = (hex: string, a: number): string => {
  const h = hex.replace('#', '');
  const r = parseInt(h.substring(0, 2), 16);
  const g = parseInt(h.substring(2, 4), 16);
  const b = parseInt(h.substring(4, 6), 16);
  return `rgba(${r},${g},${b},${a})`;
};

export const AppointmentsScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const theme = moduleThemes.appointments;

  const headerEnter = spring({ frame: frame - 4, fps, config: { damping: 16 } });
  const statsEnter = spring({ frame: frame - 8, fps, config: { damping: 14 } });
  const dateEnter = spring({ frame: frame - 14, fps, config: { damping: 14 } });

  const hourDraw = (i: number) =>
    spring({ frame: frame - 18 - i * 3, fps, config: { damping: 14 } });

  const block1Enter = spring({ frame: frame - 26, fps, config: { damping: 14 } });
  const block1Expand = spring({
    frame: frame - 48,
    fps,
    config: { damping: 16, stiffness: 85 },
  });
  const block2Enter = spring({ frame: frame - 34, fps, config: { damping: 14 } });

  const tapSlot = spring({
    frame: frame - 58,
    fps,
    config: { damping: 10, stiffness: 130 },
  });

  const qrFlip = spring({ frame: frame - 68, fps, config: { damping: 16 } });
  const qrRotate = (1 - Math.min(qrFlip, 1)) * 88;

  const glowT = Math.max(0, frame - 42);
  const glowPulse = 0.5 + 0.5 * Math.sin(glowT * 0.16);

  const b1Top = (10 - HOUR_START) * HOUR_HEIGHT;
  const b1HBase = (45 / 60) * HOUR_HEIGHT;
  const b1HExpanded = 98;
  const b1Height = b1HBase + (b1HExpanded - b1HBase) * Math.min(block1Expand, 1);
  const b1Color = '#E65100';

  const b2Top = (12 - HOUR_START) * HOUR_HEIGHT;
  const b2Height = HOUR_HEIGHT;
  const b2Color = '#8B5CF6';

  const tapTop = (9.5 - HOUR_START) * HOUR_HEIGHT;
  const tapHeight = HOUR_HEIGHT / 2;
  const tapAlpha = Math.min(Math.max(tapSlot, 0), 1);

  return (
    <SceneFrame
      tint={theme.color}
      title={moduleSlogans.appointments.title}
      subtitle={moduleSlogans.appointments.subtitle}
      transition={moduleSlogans.appointments.transition}
      badge="◷"
      chips={['Timeline', 'Online rezervasyon', 'Müşteri']}
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
          {/* Header — appointment_screen PhobesModuleHeader */}
          <div
            style={{
              padding: '8px 20px 10px',
              opacity: headerEnter,
            }}
          >
            <div style={{ display: 'flex', alignItems: 'flex-start', gap: 10 }}>
              <div
                style={{
                  width: 36,
                  height: 36,
                  borderRadius: 11,
                  background: `${APPT_CYAN}22`,
                  border: `1px solid ${APPT_CYAN}44`,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontSize: 18,
                  color: APPT_CYAN,
                }}
              >
                ◷
              </div>
              <div style={{ flex: 1 }}>
                <div
                  style={{
                    color: colors.white,
                    fontFamily: fonts.display,
                    fontSize: 20,
                    fontWeight: 700,
                    lineHeight: 1.1,
                  }}
                >
                  Randevu Merkezi
                </div>
              </div>
              {/* View mode — surfaceVariant row */}
              <div
                style={{
                  padding: 2,
                  borderRadius: 10,
                  background: colors.surfaceVariant,
                  display: 'flex',
                  gap: 0,
                }}
              >
                {[
                  { icon: '▥', active: true },
                  { icon: '▦', active: false },
                  { icon: '☰', active: false },
                ].map((v, i) => (
                  <div
                    key={i}
                    style={{
                      padding: 7,
                      borderRadius: 8,
                      background: v.active ? `${APPT_CYAN}26` : 'transparent',
                      color: v.active ? APPT_CYAN : colors.white40,
                      fontSize: 14,
                    }}
                  >
                    {v.icon}
                  </div>
                ))}
              </div>
            </div>
            <div
              style={{
                display: 'flex',
                marginTop: 10,
                borderBottom: `1px solid ${colors.white10}`,
              }}
            >
              {['Yönetim', 'Randevularım'].map((tab, i) => (
                <div
                  key={tab}
                  style={{
                    flex: 1,
                    padding: '8px 0',
                    textAlign: 'center',
                    color: i === 0 ? APPT_CYAN : colors.white40,
                    fontFamily: fonts.display,
                    fontSize: 13,
                    fontWeight: i === 0 ? 700 : 500,
                    borderBottom:
                      i === 0 ? `2px solid ${APPT_CYAN}` : '2px solid transparent',
                  }}
                >
                  {tab}
                </div>
              ))}
            </div>
          </div>

          <div style={{ padding: '0 20px 10px' }}>
            {/* _AppointmentStatsRow */}
            <div
              style={{
                display: 'flex',
                gap: 8,
                marginBottom: 10,
                opacity: statsEnter,
                transform: `translateY(${(1 - statsEnter) * 10}px)`,
              }}
            >
              {stats.map((s) => (
                <div
                  key={s.label}
                  style={{
                    flex: 1,
                    padding: '10px 4px',
                    borderRadius: 16,
                    background: rgba(s.color, 0.08),
                    border: `1px solid ${rgba(s.color, 0.15)}`,
                    textAlign: 'center',
                  }}
                >
                  <div
                    style={{
                      color: s.color,
                      fontFamily: fonts.display,
                      fontSize: 18,
                      fontWeight: 700,
                    }}
                  >
                    {s.value}
                  </div>
                  <div
                    style={{
                      color: rgba(s.color, 0.8),
                      fontFamily: fonts.display,
                      fontSize: 10,
                      fontWeight: 500,
                      marginTop: 2,
                    }}
                  >
                    {s.label}
                  </div>
                </div>
              ))}
            </div>

            {/* Date navigator — _buildDateNavigator */}
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                marginBottom: 8,
                opacity: dateEnter,
              }}
            >
              <span style={{ color: colors.white40, fontSize: 22 }}>‹</span>
              <div style={{ flex: 1, textAlign: 'center' }}>
                <div
                  style={{
                    color: colors.white,
                    fontFamily: fonts.display,
                    fontSize: 16,
                    fontWeight: 700,
                  }}
                >
                  27 Mayıs Çarşamba
                </div>
              </div>
              <span style={{ color: colors.white40, fontSize: 22 }}>›</span>
            </div>

            {/* Timeline — timeline_view.dart hourHeight=72 scaled */}
            <div
              style={{
                display: 'flex',
                height: HOURS.length * HOUR_HEIGHT,
                marginBottom: 10,
                position: 'relative',
              }}
            >
              <div style={{ width: 44 }}>
                {HOURS.map((h, i) => {
                  const draw = hourDraw(i);
                  return (
                    <div
                      key={h}
                      style={{
                        height: HOUR_HEIGHT,
                        color: colors.white40,
                        fontFamily: fonts.display,
                        fontSize: 11,
                        fontWeight: 500,
                        opacity: draw,
                        transform: `translateY(-7px) translateX(${(1 - draw) * -8}px)`,
                      }}
                    >
                      {h.toString().padStart(2, '0')}:00
                    </div>
                  );
                })}
              </div>

              <div style={{ flex: 1, position: 'relative' }}>
                {HOURS.map((h, i) => {
                  const draw = hourDraw(i);
                  return (
                    <div
                      key={`g-${h}`}
                      style={{
                        position: 'absolute',
                        top: i * HOUR_HEIGHT,
                        left: 0,
                        right: 0,
                        height: 0.5,
                        background: colors.white10,
                        transform: `scaleX(${draw})`,
                        transformOrigin: 'left',
                      }}
                    />
                  );
                })}
                {HOURS.map((h, i) => (
                  <div
                    key={`h-${h}`}
                    style={{
                      position: 'absolute',
                      top: i * HOUR_HEIGHT + HOUR_HEIGHT / 2,
                      left: 0,
                      right: 0,
                      height: 0.5,
                      background: colors.white05,
                    }}
                  />
                ))}

                {/* Now line ~10:30 */}
                <div
                  style={{
                    position: 'absolute',
                    top: (10 - HOUR_START) * HOUR_HEIGHT + HOUR_HEIGHT / 2,
                    left: -6,
                    right: 0,
                    height: 1.5,
                    background: APPT_CYAN,
                    opacity: 0.55,
                    zIndex: 1,
                  }}
                />

                {/* Empty slot tap */}
                <div
                  style={{
                    position: 'absolute',
                    top: tapTop + 2,
                    left: 4,
                    right: 4,
                    height: tapHeight - 4,
                    borderRadius: 8,
                    border:
                      tapAlpha > 0.05
                        ? `1px solid ${rgba(colors.success, tapAlpha)}`
                        : `1px dashed ${colors.white10}`,
                    background:
                      tapAlpha > 0
                        ? rgba(colors.success, 0.2 * tapAlpha)
                        : 'transparent',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    color: tapAlpha > 0.4 ? colors.white : colors.white40,
                    fontFamily: fonts.display,
                    fontSize: 10,
                    fontWeight: 700,
                    transform: `scale(${0.94 + tapAlpha * 0.06})`,
                  }}
                >
                  {tapAlpha > 0.5 ? '✓ Yeni randevu' : '+ Boş slot'}
                </div>

                {/* Block 1 — expand */}
                <div
                  style={{
                    position: 'absolute',
                    top: b1Top,
                    left: 4,
                    right: 4,
                    height: b1Height,
                    borderRadius: 12,
                    padding: '8px 12px',
                    background: `linear-gradient(135deg, ${rgba(b1Color, 0.18)}, ${rgba(b1Color, 0.08)})`,
                    borderLeft: `3px solid ${b1Color}`,
                    opacity: block1Enter,
                    transform: `translateX(${(1 - block1Enter) * 24}px)`,
                    boxShadow: `0 ${5 + glowPulse * 6}px ${
                      14 + glowPulse * 12
                    }px ${rgba(b1Color, 0.3 + glowPulse * 0.2)}`,
                    overflow: 'hidden',
                    zIndex: 3,
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div
                        style={{
                          color: colors.white,
                          fontFamily: fonts.display,
                          fontSize: 13,
                          fontWeight: 600,
                          whiteSpace: 'nowrap',
                          overflow: 'hidden',
                          textOverflow: 'ellipsis',
                        }}
                      >
                        Saç kesimi
                      </div>
                      {b1Height > 40 && (
                        <div
                          style={{
                            color: colors.white60,
                            fontFamily: fonts.display,
                            fontSize: 11,
                            marginTop: 2,
                          }}
                        >
                          10:00 – 10:45 · Ayşe Kaya
                        </div>
                      )}
                    </div>
                    <div
                      style={{
                        width: 7,
                        height: 7,
                        borderRadius: '50%',
                        background: '#10B981',
                        flexShrink: 0,
                      }}
                    />
                  </div>
                  {block1Expand > 0.08 && b1Height > 55 && (
                    <div
                      style={{
                        marginTop: 8,
                        opacity: Math.min(block1Expand, 1),
                        transform: `translateY(${(1 - Math.min(block1Expand, 1)) * 10}px)`,
                      }}
                    >
                      <div
                        style={{
                          color: rgba(b1Color, 0.85),
                          fontFamily: fonts.display,
                          fontSize: 10,
                          fontWeight: 600,
                        }}
                      >
                        ₺250
                      </div>
                      <div style={{ display: 'flex', gap: 6, marginTop: 6 }}>
                        {['📞', '💬', '✎'].map((ic) => (
                          <div
                            key={ic}
                            style={{
                              width: 26,
                              height: 26,
                              borderRadius: 8,
                              background: rgba(b1Color, 0.12),
                              border: `1px solid ${rgba(b1Color, 0.35)}`,
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                              fontSize: 11,
                            }}
                          >
                            {ic}
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                </div>

                {/* Block 2 */}
                <div
                  style={{
                    position: 'absolute',
                    top: b2Top,
                    left: 4,
                    right: 4,
                    height: b2Height,
                    borderRadius: 12,
                    padding: '8px 12px',
                    background: `linear-gradient(135deg, ${rgba(b2Color, 0.18)}, ${rgba(b2Color, 0.08)})`,
                    borderLeft: `3px solid ${b2Color}`,
                    opacity: block2Enter,
                    transform: `translateX(${(1 - block2Enter) * 24}px)`,
                    display: 'flex',
                    flexDirection: 'column',
                    justifyContent: 'center',
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                    <span
                      style={{
                        color: colors.white,
                        fontFamily: fonts.display,
                        fontSize: 13,
                        fontWeight: 600,
                      }}
                    >
                      Masaj
                    </span>
                    <div
                      style={{
                        width: 7,
                        height: 7,
                        borderRadius: '50%',
                        background: '#F59E0B',
                        marginLeft: 'auto',
                      }}
                    />
                  </div>
                  <div
                    style={{
                      color: colors.white60,
                      fontFamily: fonts.display,
                      fontSize: 11,
                      marginTop: 2,
                    }}
                  >
                    12:00 – 13:00 · Mehmet Can
                  </div>
                </div>
              </div>
            </div>

            {/* QR share card — flip */}
            <div style={{ perspective: 800 }}>
              <div
                style={{
                  transform: `rotateY(${qrRotate}deg)`,
                  transformStyle: 'preserve-3d',
                  opacity: Math.min(qrFlip, 1),
                  padding: 12,
                  borderRadius: 14,
                  background: `linear-gradient(135deg, ${rgba(APPT_CYAN, 0.16)}, ${colors.surfaceLight})`,
                  border: `1px solid ${rgba(APPT_CYAN, 0.35)}`,
                  display: 'flex',
                  alignItems: 'center',
                  gap: 12,
                  boxShadow: `0 8px 22px ${rgba(APPT_CYAN, 0.25)}`,
                }}
              >
                <div
                  style={{
                    width: 52,
                    height: 52,
                    background: colors.white,
                    borderRadius: 8,
                    display: 'grid',
                    gridTemplateColumns: `repeat(${QR[0].length}, 1fr)`,
                    gap: 1,
                    padding: 4,
                    flexShrink: 0,
                  }}
                >
                  {QR.flat().map((cell, i) => (
                    <div
                      key={i}
                      style={{
                        background: cell ? '#0a0a0a' : 'transparent',
                        borderRadius: 1,
                      }}
                    />
                  ))}
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div
                    style={{
                      color: colors.white,
                      fontFamily: fonts.display,
                      fontSize: 12,
                      fontWeight: 800,
                    }}
                  >
                    Müşterilerinle paylaş
                  </div>
                  <div
                    style={{
                      color: colors.white60,
                      fontFamily: fonts.display,
                      fontSize: 9.5,
                      marginTop: 2,
                    }}
                  >
                    phobes.app/r/BOOK-A8K2
                  </div>
                  <div style={{ display: 'flex', gap: 6, marginTop: 6 }}>
                    <span
                      style={{
                        background: APPT_CYAN,
                        color: colors.white,
                        fontFamily: fonts.display,
                        fontSize: 9,
                        fontWeight: 700,
                        padding: '4px 9px',
                        borderRadius: 999,
                      }}
                    >
                      Linki kopyala
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </PhoneFrame>
    </SceneFrame>
  );
};
