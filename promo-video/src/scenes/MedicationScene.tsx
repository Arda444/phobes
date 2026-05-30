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
 * İlaç sahnesi — lib/screens/medication/medications_screen.dart
 * Bugün sekmesi: günlük uyum kartı, doz kartları (_buildDoseCard), stok çubukları.
 * Promo: hatırlatma banner sallanma, 3D kapsül dönüşü, stok barları. 90 kare.
 */

const MED_PINK = statsModuleColors.medications; // #EC4899

type Dose = {
  time: string;
  name: string;
  icon: string;
  dosage: string;
  color: string;
  taken: boolean;
  stock: number;
  max: number;
  stockTracking: boolean;
};

const doses: Dose[] = [
  {
    time: '08:00',
    name: 'Vitamin D',
    icon: '☀️',
    dosage: '1 tablet',
    color: '#F59E0B',
    taken: true,
    stock: 28,
    max: 30,
    stockTracking: true,
  },
  {
    time: '14:00',
    name: 'Omega 3',
    icon: '🐟',
    dosage: '2 kapsül',
    color: '#06B6D4',
    taken: true,
    stock: 12,
    max: 30,
    stockTracking: true,
  },
  {
    time: '21:00',
    name: 'Magnezyum',
    icon: '💊',
    dosage: '1 tablet',
    color: '#A855F7',
    taken: false,
    stock: 5,
    max: 30,
    stockTracking: true,
  },
];

const Capsule: React.FC<{
  width: number;
  height: number;
  left: string;
  right: string;
}> = ({ width, height, left, right }) => (
  <div
    style={{
      width,
      height,
      borderRadius: 999,
      background: `linear-gradient(90deg, ${left} 0%, ${left} 49%, ${right} 51%, ${right} 100%)`,
      position: 'relative',
      boxShadow: `0 ${Math.max(2, height / 5)}px ${Math.max(6, height / 2)}px ${left}44, inset 0 1px 0 rgba(255,255,255,0.5)`,
    }}
  >
    <div
      style={{
        position: 'absolute',
        left: '50%',
        top: '10%',
        bottom: '10%',
        width: Math.max(1, width * 0.03),
        background: 'rgba(0,0,0,0.25)',
        transform: 'translateX(-50%)',
        borderRadius: 1,
      }}
    />
    <div
      style={{
        position: 'absolute',
        top: '14%',
        left: '12%',
        right: '12%',
        height: height * 0.2,
        background: 'rgba(255,255,255,0.5)',
        borderRadius: 999,
        filter: 'blur(1px)',
      }}
    />
  </div>
);

export const MedicationScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const theme = moduleThemes.medication;

  const headerEnter = spring({ frame: frame - 4, fps, config: { damping: 16 } });
  const bannerPop = spring({ frame: frame - 10, fps, config: { damping: 10, mass: 0.85 } });

  const shakeActive = frame > 28 && frame < 58;
  const reminderShake = shakeActive ? Math.sin((frame - 28) * 0.38) * 5 : 0;

  const heroRotation = interpolate(frame, [12, 78], [0, 360], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.inOut(Easing.cubic),
  });
  const breathing = 1 + Math.sin(frame * 0.07) * 0.035;

  const adherenceEnter = spring({ frame: frame - 16, fps, config: { damping: 14 } });
  const adherencePct = Math.round(
    interpolate(frame, [20, 48], [0, 67], {
      extrapolateLeft: 'clamp',
      extrapolateRight: 'clamp',
      easing: Easing.out(Easing.cubic),
    }),
  );

  const takeAt = 62;
  const takenSpring = spring({
    frame: frame - takeAt,
    fps,
    config: { damping: 11, mass: 0.7 },
  });

  const stockEnter = spring({ frame: frame - 48, fps, config: { damping: 14 } });

  return (
    <SceneFrame
      tint={theme.color}
      title={moduleSlogans.medication.title}
      subtitle={moduleSlogans.medication.subtitle}
      transition={moduleSlogans.medication.transition}
      badge="◉"
      chips={['Hatırlatıcı', 'Stok', 'Uyum']}
    >
      <PhoneFrame>
        <div
          style={{
            paddingTop: 72,
            height: '100%',
            background: colors.surface,
            overflow: 'hidden',
          }}
        >
          {/* Header + tabs — medications_screen.dart */}
          <div
            style={{
              padding: '8px 20px 0',
              opacity: headerEnter,
              transform: `translateY(${(1 - headerEnter) * -10}px)`,
            }}
          >
            <div style={{ display: 'flex', alignItems: 'flex-start', gap: 10 }}>
              <div
                style={{
                  width: 36,
                  height: 36,
                  borderRadius: 11,
                  background: `${MED_PINK}22`,
                  border: `1px solid ${MED_PINK}44`,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontSize: 18,
                }}
              >
                ◉
              </div>
              <div style={{ flex: 1 }}>
                <div
                  style={{
                    color: colors.white,
                    fontFamily: fonts.display,
                    fontSize: 22,
                    fontWeight: 700,
                  }}
                >
                  İlaçlarım
                </div>
              </div>
              <div
                style={{
                  width: 32,
                  height: 32,
                  borderRadius: 10,
                  background: `linear-gradient(135deg, ${MED_PINK}, #BE185D)`,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  color: colors.white,
                  fontSize: 20,
                  fontWeight: 800,
                }}
              >
                +
              </div>
            </div>
            <div
              style={{
                display: 'flex',
                marginTop: 12,
                borderBottom: `1px solid ${colors.white10}`,
              }}
            >
              {['Bugün', 'Tüm İlaçlar'].map((tab, i) => {
                const active = i === 0;
                return (
                  <div
                    key={tab}
                    style={{
                      flex: 1,
                      padding: '10px 0',
                      textAlign: 'center',
                      color: active ? MED_PINK : colors.white40,
                      fontFamily: fonts.display,
                      fontSize: 13,
                      fontWeight: active ? 700 : 500,
                      borderBottom: active
                        ? `2px solid ${MED_PINK}`
                        : '2px solid transparent',
                    }}
                  >
                    {tab}
                  </div>
                );
              })}
            </div>
          </div>

          <div style={{ padding: '12px 20px 14px' }}>
            {/* Sıradaki doz banner — shake + 3D kapsül */}
            <div
              style={{
                padding: '12px 14px',
                borderRadius: 16,
                background: `linear-gradient(135deg, ${MED_PINK}, #BE185D)`,
                boxShadow: `0 10px 24px ${MED_PINK}55`,
                marginBottom: 12,
                display: 'flex',
                alignItems: 'center',
                gap: 12,
                transform: `scale(${0.9 + bannerPop * 0.1}) translateX(${reminderShake}px)`,
                opacity: bannerPop,
                border: '1px solid rgba(255,255,255,0.15)',
              }}
            >
              <div style={{ width: 68, height: 36, perspective: 500, flexShrink: 0 }}>
                <div
                  style={{
                    width: '100%',
                    height: '100%',
                    transform: `rotateY(${heroRotation}deg) scale(${breathing})`,
                    transformStyle: 'preserve-3d',
                  }}
                >
                  <Capsule
                    width={68}
                    height={36}
                    left="#A855F7"
                    right="#DDD6FE"
                  />
                </div>
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div
                  style={{
                    color: 'rgba(255,255,255,0.75)',
                    fontFamily: fonts.display,
                    fontSize: 9,
                    fontWeight: 700,
                    letterSpacing: 1.2,
                    textTransform: 'uppercase',
                  }}
                >
                  Sıradaki doz
                </div>
                <div
                  style={{
                    color: colors.white,
                    fontFamily: fonts.display,
                    fontSize: 16,
                    fontWeight: 800,
                  }}
                >
                  21:00 · Magnezyum
                </div>
                <div
                  style={{
                    color: 'rgba(255,255,255,0.8)',
                    fontFamily: fonts.display,
                    fontSize: 11,
                  }}
                >
                  1 tablet · uyumadan önce
                </div>
              </div>
              <div
                style={{
                  fontSize: 22,
                  transform: `rotate(${reminderShake * 2.5}deg)`,
                }}
              >
                🔔
              </div>
            </div>

            {/* Günlük uyum — PhobesGlassCard */}
            <div
              style={{
                padding: 16,
                borderRadius: 20,
                background: 'rgba(255,255,255,0.04)',
                border: `1px solid ${colors.white10}`,
                backdropFilter: 'blur(12px)',
                display: 'flex',
                alignItems: 'center',
                gap: 16,
                marginBottom: 12,
                opacity: adherenceEnter,
                transform: `translateY(${(1 - adherenceEnter) * 14}px)`,
              }}
            >
              <div style={{ width: 60, height: 60, position: 'relative' }}>
                <svg width={60} height={60} style={{ transform: 'rotate(-90deg)' }}>
                  <circle
                    cx={30}
                    cy={30}
                    r={24}
                    fill="none"
                    stroke={colors.white10}
                    strokeWidth={6}
                  />
                  <circle
                    cx={30}
                    cy={30}
                    r={24}
                    fill="none"
                    stroke="#4CAF50"
                    strokeWidth={6}
                    strokeLinecap="round"
                    strokeDasharray={2 * Math.PI * 24}
                    strokeDashoffset={
                      2 * Math.PI * 24 * (1 - adherencePct / 100)
                    }
                  />
                </svg>
                <div
                  style={{
                    position: 'absolute',
                    inset: 0,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    color: colors.white,
                    fontFamily: fonts.display,
                    fontSize: 14,
                    fontWeight: 800,
                  }}
                >
                  {adherencePct}%
                </div>
              </div>
              <div>
                <div
                  style={{
                    color: colors.white,
                    fontFamily: fonts.display,
                    fontSize: 16,
                    fontWeight: 700,
                  }}
                >
                  Günlük uyum
                </div>
                <div
                  style={{
                    color: colors.white60,
                    fontFamily: fonts.display,
                    fontSize: 13,
                    marginTop: 2,
                  }}
                >
                  2 / 3 doz alındı
                </div>
              </div>
            </div>

            <div
              style={{
                color: colors.white40,
                fontFamily: fonts.display,
                fontSize: 14,
                fontWeight: 600,
                letterSpacing: 1,
                marginBottom: 8,
              }}
            >
              Bugünkü dozlar
            </div>

            {/* Dose cards — _buildDoseCard */}
            {doses.map((d, i) => {
              const enter = spring({
                frame: frame - 24 - i * 6,
                fps,
                config: { damping: 14 },
              });
              const isMag = i === 2;
              const taken = d.taken || (isMag && takenSpring > 0.45);

              return (
                <div
                  key={d.name}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    padding: 16,
                    marginBottom: 8,
                    background: colors.surfaceLight,
                    borderRadius: 20,
                    border: `1px solid ${
                      !taken ? `${d.color}44` : colors.white10
                    }`,
                    boxShadow: !taken
                      ? `0 0 20px ${d.color}22`
                      : 'none',
                    opacity: enter,
                    transform: `translateX(${(1 - enter) * 22}px)`,
                  }}
                >
                  <div
                    style={{
                      padding: '6px 10px',
                      borderRadius: 10,
                      background: `${d.color}1a`,
                      color: d.color,
                      fontFamily: fonts.display,
                      fontSize: 14,
                      fontWeight: 700,
                      flexShrink: 0,
                    }}
                  >
                    {d.time}
                  </div>
                  <div style={{ width: 14 }} />
                  <span style={{ fontSize: 24, flexShrink: 0 }}>{d.icon}</span>
                  <div style={{ width: 14 }} />
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div
                      style={{
                        color: colors.white,
                        fontFamily: fonts.display,
                        fontSize: 16,
                        fontWeight: 600,
                        textDecoration: taken ? 'line-through' : 'none',
                        textDecorationColor: colors.white40,
                      }}
                    >
                      {d.name}
                    </div>
                    <div
                      style={{
                        color: colors.white40,
                        fontFamily: fonts.display,
                        fontSize: 12,
                      }}
                    >
                      {d.dosage}
                    </div>
                  </div>
                  <div
                    style={{
                      width: 36,
                      height: 36,
                      borderRadius: 12,
                      flexShrink: 0,
                      background: taken
                        ? 'linear-gradient(135deg, #10B981, #059669)'
                        : colors.white05,
                      border: taken
                        ? 'none'
                        : `1.5px solid ${colors.white20}`,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      color: colors.white,
                      fontSize: 18,
                      fontWeight: 900,
                      boxShadow: taken
                        ? '0 4px 10px rgba(16,185,129,0.3)'
                        : 'none',
                      transform: isMag
                        ? `scale(${0.88 + takenSpring * 0.12})`
                        : undefined,
                    }}
                  >
                    {taken ? '✓' : '○'}
                  </div>
                </div>
              );
            })}

            {/* Stok çubukları — _buildMedCard stockTracking */}
            <div
              style={{
                padding: 12,
                background: colors.white05,
                borderRadius: 12,
                border: `1px solid ${colors.white10}`,
                marginTop: 4,
                opacity: stockEnter,
              }}
            >
              <div
                style={{
                  color: colors.white60,
                  fontFamily: fonts.display,
                  fontSize: 10,
                  fontWeight: 700,
                  letterSpacing: 1.2,
                  textTransform: 'uppercase',
                  marginBottom: 8,
                }}
              >
                Stok durumu
              </div>
              {doses
                .filter((d) => d.stockTracking)
                .map((d, i) => {
                  const low = d.stock <= 7;
                  const barSpring = spring({
                    frame: frame - 52 - i * 5,
                    fps,
                    config: { damping: 14 },
                  });
                  const warnShake =
                    low && frame > 64 && frame < 86
                      ? Math.sin((frame - 64) * 0.32) * 1.5
                      : 0;
                  const pct = (d.stock / d.max) * 100;

                  return (
                    <div
                      key={d.name}
                      style={{
                        marginBottom: 8,
                        transform: `translateX(${warnShake}px)`,
                      }}
                    >
                      <div
                        style={{
                          display: 'flex',
                          justifyContent: 'space-between',
                          marginBottom: 4,
                          fontFamily: fonts.display,
                          fontSize: 12,
                        }}
                      >
                        <span style={{ color: colors.white80 }}>{d.name}</span>
                        <span
                          style={{
                            fontWeight: 700,
                            color: low ? colors.error : colors.white80,
                          }}
                        >
                          {low ? '⚠ ' : ''}
                          {d.stock} kaldı
                        </span>
                      </div>
                      <div
                        style={{
                          height: 4,
                          background: colors.white10,
                          borderRadius: 4,
                          overflow: 'hidden',
                        }}
                      >
                        <div
                          style={{
                            height: '100%',
                            width: `${pct * Math.max(0, barSpring)}%`,
                            background: low
                              ? `linear-gradient(90deg, ${colors.error}, #DC2626)`
                              : `linear-gradient(90deg, ${d.color}, ${MED_PINK})`,
                            borderRadius: 4,
                            boxShadow: low
                              ? `0 0 8px ${colors.error}88`
                              : 'none',
                          }}
                        />
                      </div>
                    </div>
                  );
                })}
            </div>
          </div>
        </div>
      </PhoneFrame>
    </SceneFrame>
  );
};
