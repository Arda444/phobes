import React from 'react';
import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate } from 'remotion';
import { PhoneFrame } from '../components/PhoneFrame';
import { LaptopFrame } from '../components/LaptopFrame';
import { TabletFrame } from '../components/TabletFrame';
import { AnimatedBackground } from '../components/AnimatedBackground';
import { colors, fonts, statsModuleColors } from '../theme';

const MODULE_TILES = [
  { key: 'tasks', label: 'Görev', color: statsModuleColors.tasks },
  { key: 'notes', label: 'Not', color: statsModuleColors.notes },
  { key: 'calendar', label: 'Takvim', color: statsModuleColors.appointments },
  { key: 'budget', label: 'Bütçe', color: statsModuleColors.budget },
  { key: 'books', label: 'Kitap', color: statsModuleColors.books },
  { key: 'habits', label: 'Alışkanlık', color: statsModuleColors.habits },
  { key: 'appointments', label: 'Randevu', color: statsModuleColors.appointments },
  { key: 'medications', label: 'İlaç', color: statsModuleColors.medications },
] as const;

const PLATFORMS = ['iOS', 'Android', 'Web', 'Tablet'] as const;

/** Üç cihaz tek satırda sığacak şekilde ölçeklenmiş genişlikler */
const TABLET_W = 228;
const LAPTOP_W = 500;
const PHONE_W = 200;

export const MultiDeviceScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();

  const headlineEnter = spring({ frame: frame - 2, fps, config: { damping: 14 } });
  const devicesEnter = spring({ frame: frame - 8, fps, config: { damping: 13, stiffness: 100 } });
  const tabletEnter = spring({ frame: frame - 10, fps, config: { damping: 12 } });
  const laptopEnter = spring({ frame: frame - 6, fps, config: { damping: 14 } });
  const phoneEnter = spring({ frame: frame - 14, fps, config: { damping: 12 } });

  const floatT = Math.sin(frame * 0.055 + 2) * 4;
  const floatL = Math.sin(frame * 0.05 + 1) * 3;
  const floatP = Math.sin(frame * 0.06) * 5;

  const exitProgress = interpolate(frame, [durationInFrames - 10, durationInFrames], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  return (
    <AbsoluteFill>
      <AnimatedBackground
        tint={colors.primary}
        secondaryTint="#1E3A5F"
        useAccentGlow={false}
        intensity={0.5}
      />

      <AbsoluteFill
        style={{
          padding: '88px 24px 72px',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          opacity: 1 - exitProgress,
        }}
      >
        <h1
          style={{
            margin: 0,
            color: colors.white,
            fontFamily: fonts.display,
            fontSize: 64,
            fontWeight: 900,
            letterSpacing: -2,
            textAlign: 'center',
            lineHeight: 1.08,
            opacity: headlineEnter,
            transform: `translateY(${(1 - headlineEnter) * 24}px)`,
            maxWidth: 900,
          }}
        >
          Mobilde, tablette,
          <br />
          <span
            style={{
              background: `linear-gradient(135deg, ${colors.primary}, ${colors.tertiary})`,
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent',
              backgroundClip: 'text',
            }}
          >
            webde,
          </span>{' '}
          her yerde.
        </h1>

        {/* Cihazlar — sabit genişlik, ortalanmış, taşma yok */}
        <div
          style={{
            flex: 1,
            width: '100%',
            maxWidth: 1020,
            display: 'flex',
            alignItems: 'flex-end',
            justifyContent: 'center',
            gap: 14,
            marginTop: 12,
            opacity: devicesEnter,
            transform: `translateY(${(1 - devicesEnter) * 40}px)`,
          }}
        >
          <div
            style={{
              flexShrink: 0,
              transform: `translateX(${(1 - tabletEnter) * -80}px) translateY(${floatT}px)`,
              opacity: tabletEnter,
            }}
          >
            <TabletFrame width={TABLET_W}>
              <TabletMockup />
            </TabletFrame>
          </div>

          <div
            style={{
              flexShrink: 0,
              zIndex: 2,
              marginBottom: 8,
              transform: `translateY(${(1 - laptopEnter) * 30 + floatL}px) scale(${0.92 + laptopEnter * 0.08})`,
              opacity: laptopEnter,
            }}
          >
            <LaptopFrame width={LAPTOP_W}>
              <WebMockup />
            </LaptopFrame>
          </div>

          <div
            style={{
              flexShrink: 0,
              transform: `translateX(${(1 - phoneEnter) * 70}px) translateY(${floatP}px)`,
              opacity: phoneEnter,
            }}
          >
            <PhoneFrame width={PHONE_W}>
              <MobileMockup />
            </PhoneFrame>
          </div>
        </div>

        <div
          style={{
            display: 'flex',
            flexWrap: 'wrap',
            gap: 10,
            justifyContent: 'center',
            marginTop: 16,
          }}
        >
          {PLATFORMS.map((p, i) => {
            const enter = spring({
              frame: frame - 28 - i * 4,
              fps,
              config: { damping: 14 },
            });
            return (
              <div
                key={p}
                style={{
                  padding: '10px 20px',
                  background: colors.white10,
                  border: `1.5px solid ${colors.primary}66`,
                  borderRadius: 999,
                  color: colors.white,
                  fontFamily: fonts.display,
                  fontSize: 22,
                  fontWeight: 700,
                  opacity: enter,
                  transform: `translateY(${(1 - enter) * 16}px)`,
                }}
              >
                {p}
              </div>
            );
          })}
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

const TabletMockup: React.FC = () => (
  <div
    style={{
      height: '100%',
      background: `linear-gradient(180deg, ${colors.primary}18 0%, ${colors.surface} 40%)`,
      padding: '14px 12px',
      display: 'flex',
      flexDirection: 'column',
      gap: 8,
    }}
  >
    <div style={{ color: colors.white, fontFamily: fonts.display, fontSize: 14, fontWeight: 800 }}>
      Phobes
    </div>
    <div
      style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(3, 1fr)',
        gap: 6,
      }}
    >
      {MODULE_TILES.slice(0, 6).map((m) => (
        <div
          key={m.key}
          style={{
            padding: 6,
            borderRadius: 8,
            background: `linear-gradient(145deg, ${m.color}, ${m.color}99)`,
            color: colors.white,
            fontFamily: fonts.display,
            fontSize: 8,
            fontWeight: 700,
            aspectRatio: '1 / 1',
            display: 'flex',
            alignItems: 'flex-end',
          }}
        >
          {m.label}
        </div>
      ))}
    </div>
    <div style={{ flex: 1, background: colors.white05, borderRadius: 8, padding: 8 }}>
      <div style={{ color: colors.white60, fontSize: 8, fontWeight: 700, marginBottom: 6 }}>
        BUGÜN
      </div>
      {[1, 2, 3].map((i) => (
        <div key={i} style={{ display: 'flex', gap: 6, marginBottom: 4, fontSize: 9, color: colors.white }}>
          <div style={{ width: 8, height: 8, borderRadius: 2, background: statsModuleColors.tasks }} />
          Görev {i}
        </div>
      ))}
    </div>
  </div>
);

const WebMockup: React.FC = () => {
  const navItems = [
    { l: 'Görev', c: statsModuleColors.tasks, active: true },
    { l: 'Not', c: statsModuleColors.notes },
    { l: 'Kitap', c: statsModuleColors.books },
    { l: 'Takvim', c: statsModuleColors.appointments },
    { l: 'Bütçe', c: statsModuleColors.budget },
    { l: 'Nova', c: colors.tertiary },
  ];

  return (
    <div
      style={{
        height: 'calc(100% - 28px)',
        background: colors.surface,
        padding: 10,
        display: 'flex',
        gap: 8,
      }}
    >
      <div
        style={{
          width: 72,
          background: colors.white05,
          borderRadius: 6,
          padding: 8,
          display: 'flex',
          flexDirection: 'column',
          gap: 5,
        }}
      >
        <div style={{ color: colors.white, fontFamily: fonts.display, fontWeight: 900, fontSize: 10 }}>
          Phobes
        </div>
        {navItems.map((item, i) => (
          <div
            key={i}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 5,
              padding: '4px 6px',
              borderRadius: 4,
              background: item.active ? colors.white10 : 'transparent',
            }}
          >
            <div style={{ width: 6, height: 6, borderRadius: 2, background: item.c }} />
            <div
              style={{
                color: item.active ? colors.white : colors.white60,
                fontFamily: fonts.display,
                fontSize: 8,
                fontWeight: item.active ? 700 : 500,
              }}
            >
              {item.l}
            </div>
          </div>
        ))}
      </div>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 5 }}>
        <div style={{ color: colors.white, fontFamily: fonts.display, fontSize: 12, fontWeight: 800 }}>
          Bugün
        </div>
        {[1, 2, 3, 4].map((i) => (
          <div
            key={i}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 6,
              padding: 5,
              background: colors.white05,
              borderRadius: 5,
              fontSize: 9,
              color: colors.white,
            }}
          >
            <div
              style={{
                width: 10,
                height: 10,
                borderRadius: 3,
                background: i % 2 === 0 ? statsModuleColors.tasks : 'transparent',
                border: `1px solid ${statsModuleColors.tasks}`,
              }}
            />
            Görev {i}
          </div>
        ))}
      </div>
      <div style={{ width: 72, background: colors.white05, borderRadius: 6, padding: 6 }}>
        <div style={{ color: colors.white60, fontSize: 7, fontWeight: 700 }}>BÜTÇE</div>
        <div style={{ color: colors.white, fontSize: 11, fontWeight: 900 }}>₺23.420</div>
      </div>
    </div>
  );
};

const MobileMockup: React.FC = () => (
  <div
    style={{
      paddingTop: 48,
      padding: '48px 8px 8px',
      height: '100%',
      background: colors.surface,
    }}
  >
    <div style={{ color: colors.white, fontFamily: fonts.display, fontSize: 12, fontWeight: 800, marginBottom: 8 }}>
      Hoş geldin
    </div>
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 5, marginBottom: 8 }}>
      {MODULE_TILES.slice(0, 4).map((m) => (
        <div
          key={m.key}
          style={{
            padding: 6,
            background: m.color,
            borderRadius: 6,
            color: colors.white,
            fontSize: 8,
            fontWeight: 700,
            aspectRatio: '2/1',
            display: 'flex',
            alignItems: 'flex-end',
          }}
        >
          {m.label}
        </div>
      ))}
    </div>
    {[1, 2, 3].map((i) => (
      <div
        key={i}
        style={{
          padding: 5,
          marginBottom: 4,
          background: colors.white05,
          borderRadius: 5,
          fontSize: 9,
          color: colors.white,
        }}
      >
        Görev {i}
      </div>
    ))}
  </div>
);
