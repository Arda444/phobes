import React from 'react';
import {
  AbsoluteFill,
  useCurrentFrame,
  useVideoConfig,
  spring,
  interpolate,
  Easing,
} from 'remotion';
import { colors, fonts } from '../theme';
import { AnimatedBackground } from './AnimatedBackground';

export type SceneTransition =
  | 'slideUp'
  | 'slideRight'
  | 'slideLeft'
  | 'zoomBlur'
  | 'flipIn'
  | 'fadeScale';

type Props = {
  tint: string;
  /** Şarp slogan (modül adı değil) */
  title: string;
  subtitle: string;
  badge?: string;
  children: React.ReactNode;
  chips?: string[];
  transition?: SceneTransition;
  /** Pembe ikinci aurora kapalı — sadece modül rengi + koyu mavi */
  neutralBackground?: boolean;
};

export const SceneFrame: React.FC<Props> = ({
  tint,
  title,
  subtitle,
  badge,
  children,
  chips,
  transition = 'slideUp',
  neutralBackground = true,
}) => {
  const frame = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();

  const enter = spring({
    frame,
    fps,
    config: { damping: 14, stiffness: 110, mass: 0.9 },
  });

  const exitStart = durationInFrames - 14;
  const exitProgress = interpolate(frame, [exitStart, durationInFrames], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.bezier(0.4, 0, 1, 1),
  });

  const titleProgress = spring({ frame: frame - 4, fps, config: { damping: 14 } });
  const subtitleProgress = spring({ frame: frame - 9, fps, config: { damping: 14 } });

  const { opacity, transform } = getTransitionStyle(transition, enter, exitProgress, frame, fps);

  const titleEnter = getTitleStyle(transition, titleProgress, frame, fps);

  return (
    <AbsoluteFill>
      <AnimatedBackground
        tint={tint}
        secondaryTint={neutralBackground ? '#1E3A5F' : undefined}
        useAccentGlow={!neutralBackground}
        intensity={0.55}
      />

      <AbsoluteFill
        style={{
          opacity,
          transform,
          padding: '100px 48px 120px 48px',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
        }}
      >
        {badge && (
          <div
            style={{
              fontSize: 56,
              width: 110,
              height: 110,
              borderRadius: 30,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              background: `linear-gradient(135deg, ${tint} 0%, ${tint}99 100%)`,
              boxShadow: `0 20px 50px ${tint}88, inset 0 1px 0 rgba(255,255,255,0.3)`,
              opacity: titleProgress,
              transform: `translateY(${(1 - titleProgress) * 20}px) scale(${0.7 + titleProgress * 0.3})`,
              marginBottom: 20,
              color: colors.white,
              fontWeight: 800,
              fontFamily: fonts.display,
            }}
          >
            {badge}
          </div>
        )}

        <h1
          style={{
            margin: 0,
            color: colors.white,
            fontFamily: fonts.display,
            fontSize: 72,
            fontWeight: 900,
            letterSpacing: -2,
            lineHeight: 1.05,
            textAlign: 'center',
            opacity: titleEnter.opacity,
            transform: titleEnter.transform,
            textShadow: `0 0 50px ${tint}55`,
            maxWidth: 920,
          }}
        >
          {title}
        </h1>

        <p
          style={{
            margin: '12px 0 28px 0',
            color: colors.white80,
            fontFamily: fonts.display,
            fontSize: 28,
            fontWeight: 500,
            textAlign: 'center',
            opacity: subtitleProgress,
            transform: `translateY(${(1 - subtitleProgress) * 20}px)`,
            maxWidth: 760,
          }}
        >
          {subtitle}
        </p>

        <div
          style={{
            flex: 1,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            width: '100%',
            minHeight: 0,
          }}
        >
          {children}
        </div>

        {chips && chips.length > 0 && (
          <div
            style={{
              display: 'flex',
              gap: 10,
              flexWrap: 'wrap',
              justifyContent: 'center',
              marginTop: 16,
            }}
          >
            {chips.map((chip, i) => {
              const chipProgress = spring({
                frame: frame - 15 - i * 4,
                fps,
                config: { damping: 12 },
              });
              return (
                <span
                  key={chip}
                  style={{
                    padding: '10px 20px',
                    borderRadius: 999,
                    background: colors.white10,
                    border: `1.5px solid ${tint}66`,
                    color: colors.white,
                    fontFamily: fonts.display,
                    fontSize: 22,
                    fontWeight: 600,
                    opacity: chipProgress,
                    transform: `translateY(${(1 - chipProgress) * 16}px) scale(${0.75 + chipProgress * 0.25})`,
                  }}
                >
                  {chip}
                </span>
              );
            })}
          </div>
        )}
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

function getTransitionStyle(
  type: SceneTransition,
  enter: number,
  exit: number,
  _frame: number,
  _fps: number
): { opacity: number; transform: string } {
  const opacity = enter * (1 - exit);

  switch (type) {
    case 'slideRight': {
      const xIn = interpolate(enter, [0, 1], [120, 0]);
      const xOut = interpolate(exit, [0, 1], [0, -80]);
      const scale = interpolate(enter, [0, 1], [0.92, 1]) - exit * 0.05;
      return {
        opacity,
        transform: `translateX(${xIn + xOut}px) scale(${scale})`,
      };
    }
    case 'slideLeft': {
      const xIn = interpolate(enter, [0, 1], [-120, 0]);
      const xOut = interpolate(exit, [0, 1], [0, 80]);
      const scale = interpolate(enter, [0, 1], [0.92, 1]) - exit * 0.05;
      return {
        opacity,
        transform: `translateX(${xIn + xOut}px) scale(${scale})`,
      };
    }
    case 'zoomBlur': {
      const scale = interpolate(enter, [0, 1], [1.15, 1]) - exit * 0.08;
      const blur = interpolate(enter, [0, 1], [12, 0]) + exit * 8;
      return {
        opacity,
        transform: `scale(${scale})`,
        // blur on wrapper via filter in parent - apply filter on AbsoluteFill child
      };
    }
    case 'flipIn': {
      const rot = interpolate(enter, [0, 1], [8, 0]) - exit * 6;
      const scale = interpolate(enter, [0, 1], [0.85, 1]) - exit * 0.06;
      return {
        opacity,
        transform: `perspective(1200px) rotateX(${rot}deg) scale(${scale})`,
      };
    }
    case 'fadeScale': {
      const scale = interpolate(enter, [0, 1], [0.94, 1]) - exit * 0.04;
      return { opacity, transform: `scale(${scale})` };
    }
    case 'slideUp':
    default: {
      const y = (1 - enter) * 70 - exit * 35;
      const scale = interpolate(enter, [0, 1], [0.9, 1]) - exit * 0.06;
      return { opacity, transform: `translateY(${y}px) scale(${scale})` };
    }
  }
}

function getTitleStyle(
  type: SceneTransition,
  progress: number,
  frame: number,
  fps: number
) {
  const baseY = (1 - progress) * 30;
  switch (type) {
    case 'slideRight':
      return {
        opacity: progress,
        transform: `translateX(${(1 - progress) * 60}px) translateY(${baseY}px)`,
      };
    case 'slideLeft':
      return {
        opacity: progress,
        transform: `translateX(${(1 - progress) * -60}px) translateY(${baseY}px)`,
      };
    case 'zoomBlur':
      return {
        opacity: progress,
        transform: `scale(${0.8 + progress * 0.2}) translateY(${baseY}px)`,
      };
    case 'flipIn':
      return {
        opacity: progress,
        transform: `rotateX(${(1 - progress) * -12}deg) translateY(${baseY}px)`,
      };
    default:
      return {
        opacity: progress,
        transform: `translateY(${baseY}px)`,
      };
  }
}
