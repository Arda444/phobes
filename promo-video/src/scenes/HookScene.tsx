import React from 'react';
import {
  AbsoluteFill,
  useCurrentFrame,
  useVideoConfig,
  spring,
  interpolate,
  Easing,
} from 'remotion';
import { colors, fonts, moduleThemes, statsModuleColors } from '../theme';
import { AnimatedBackground } from '../components/AnimatedBackground';
import { PhobesLogo } from '../components/PhobesLogo';

/** 9 promo modülleri — istatistik + stats_module_palette renkleri */
const HOOK_ORBS: { color: string; emoji: string }[] = [
  { color: moduleThemes.statistics.color, emoji: moduleThemes.statistics.emoji },
  { color: statsModuleColors.tasks, emoji: moduleThemes.tasks.emoji },
  { color: statsModuleColors.notes, emoji: moduleThemes.notes.emoji },
  { color: moduleThemes.calendar.color, emoji: moduleThemes.calendar.emoji },
  { color: statsModuleColors.budget, emoji: moduleThemes.budget.emoji },
  { color: statsModuleColors.books, emoji: moduleThemes.books.emoji },
  { color: statsModuleColors.habits, emoji: moduleThemes.habits.emoji },
  { color: statsModuleColors.medications, emoji: moduleThemes.medication.emoji },
  { color: statsModuleColors.appointments, emoji: moduleThemes.appointments.emoji },
  { color: statsModuleColors.teams, emoji: moduleThemes.teams.emoji },
];

/**
 * Açılış — 50 kare (~1.7 sn @ 30fps).
 * PhobesLogo + 9 modül rengi orbit + "Hayatın, tek uygulamada."
 */
export const HookScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();

  const logoEnter = spring({ frame, fps, config: { damping: 11, stiffness: 200 } });
  const subtitleEnter = spring({
    frame: frame - 6,
    fps,
    config: { damping: 12, stiffness: 180 },
  });
  const titleEnter = spring({
    frame: frame - 2,
    fps,
    config: { damping: 13, stiffness: 190 },
  });

  const orbitAngle = (frame / fps) * 140;

  const exitStart = durationInFrames - 6;
  const exitProgress = interpolate(frame, [exitStart, durationInFrames], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.bezier(0.4, 0, 1, 1),
  });

  const orbitScale = 0.72 + logoEnter * 0.28;

  return (
    <AbsoluteFill>
      <AnimatedBackground tint={colors.primary} secondaryTint="#1E3A5F" useAccentGlow={false} intensity={0.75} />

      <AbsoluteFill
        style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          opacity: 1 - exitProgress,
          transform: `scale(${1 - exitProgress * 0.06})`,
        }}
      >
        <div
          style={{
            position: 'relative',
            width: 500,
            height: 500,
            marginBottom: 36,
            opacity: logoEnter,
            transform: `scale(${orbitScale})`,
          }}
        >
          <div
            style={{
              position: 'absolute',
              top: '50%',
              left: '50%',
              transform: 'translate(-50%, -50%)',
            }}
          >
            <PhobesLogo size={200} animate={false} pulse />
          </div>

          <div
            style={{
              position: 'absolute',
              inset: 24,
              borderRadius: '50%',
              border: `2px dashed ${colors.white20}`,
            }}
          />

          {HOOK_ORBS.map((orb, i) => {
            const baseAngle = (i / HOOK_ORBS.length) * 360;
            const angle = ((baseAngle + orbitAngle) * Math.PI) / 180;
            const r = 218;
            const cx = 250;
            const cy = 250;
            const size = 52;
            const x = cx + Math.cos(angle) * r - size / 2;
            const y = cy + Math.sin(angle) * r - size / 2;
            const pop = spring({
              frame: frame - 3 - i * 1.5,
              fps,
              config: { damping: 10, stiffness: 220 },
            });
            return (
              <div
                key={i}
                style={{
                  position: 'absolute',
                  left: x,
                  top: y,
                  width: size,
                  height: size,
                  borderRadius: 14,
                  background: `linear-gradient(145deg, ${orb.color}, ${orb.color}cc)`,
                  boxShadow: `0 0 28px ${orb.color}99, inset 0 1px 0 rgba(255,255,255,0.35)`,
                  transform: `scale(${pop})`,
                  opacity: pop,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  color: colors.white,
                  fontFamily: fonts.display,
                  fontSize: 22,
                  fontWeight: 800,
                }}
              >
                {orb.emoji}
              </div>
            );
          })}
        </div>

        <h1
          style={{
            margin: 0,
            color: colors.white,
            fontFamily: fonts.display,
            fontSize: 128,
            fontWeight: 900,
            letterSpacing: -5,
            lineHeight: 0.95,
            textShadow: `0 0 60px ${colors.primary}99`,
            opacity: titleEnter,
            transform: `translateY(${(1 - titleEnter) * 24}px)`,
          }}
        >
          PHOBES
        </h1>

        <p
          style={{
            margin: '18px 0 0 0',
            color: colors.white80,
            fontFamily: fonts.display,
            fontSize: 40,
            fontWeight: 500,
            textAlign: 'center',
            opacity: subtitleEnter,
            transform: `translateY(${(1 - subtitleEnter) * 20}px)`,
            letterSpacing: -0.5,
          }}
        >
          Hayatın, tek uygulamada.
        </p>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
