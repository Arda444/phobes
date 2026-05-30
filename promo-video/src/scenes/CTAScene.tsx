import React from 'react';
import {
  AbsoluteFill,
  useCurrentFrame,
  useVideoConfig,
  spring,
  interpolate,
} from 'remotion';
import { colors, fonts } from '../theme';
import { AnimatedBackground } from '../components/AnimatedBackground';
import { PhobesLogo } from '../components/PhobesLogo';

export const CTAScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const logoEnter = spring({ frame, fps, config: { damping: 9, mass: 0.7 } });
  const headlineEnter = spring({ frame: frame - 8, fps, config: { damping: 12 } });
  const subEnter = spring({ frame: frame - 18, fps, config: { damping: 14 } });
  const ctaEnter = spring({ frame: frame - 26, fps, config: { damping: 11 } });
  const urlEnter = spring({ frame: frame - 38, fps, config: { damping: 14 } });
  const pulseScale = 1 + Math.sin((frame / fps) * Math.PI * 2.5) * 0.025;

  // Parlama animasyonu — kart üzerinde sağa kayan
  const shineX = interpolate(frame % 60, [0, 60], [-100, 200]);

  return (
    <AbsoluteFill>
      <AnimatedBackground tint={colors.primary} secondaryTint="#1E3A5F" useAccentGlow={false} intensity={0.7} />

      <AbsoluteFill
        style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          padding: 60,
        }}
      >
        <div
          style={{
            opacity: logoEnter,
            transform: `scale(${logoEnter * pulseScale})`,
            marginBottom: 40,
          }}
        >
          <PhobesLogo size={260} borderRadius={60} animate={false} pulse />
        </div>

        {/* Headline */}
        <h1
          style={{
            margin: 0,
            color: colors.white,
            fontFamily: fonts.display,
            fontSize: 110,
            fontWeight: 900,
            letterSpacing: -5,
            textAlign: 'center',
            lineHeight: 1,
            opacity: headlineEnter,
            transform: `translateY(${(1 - headlineEnter) * 30}px)`,
            textShadow: `0 0 60px ${colors.primary}88`,
          }}
        >
          PHOBES
        </h1>

        <p
          style={{
            margin: '20px 0 50px 0',
            color: colors.white80,
            fontFamily: fonts.display,
            fontSize: 38,
            fontWeight: 500,
            textAlign: 'center',
            opacity: subEnter,
            transform: `translateY(${(1 - subEnter) * 20}px)`,
            maxWidth: 800,
          }}
        >
          Görev, not, bütçe, AI… hepsi
          <br />
          tek uygulamada.
        </p>

        {/* CTA Button */}
        <div
          style={{
            padding: '28px 60px',
            background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.accent} 100%)`,
            borderRadius: 999,
            color: colors.white,
            fontFamily: fonts.display,
            fontSize: 42,
            fontWeight: 900,
            letterSpacing: -1,
            boxShadow: `0 20px 60px ${colors.primary}cc, inset 0 2px 0 rgba(255,255,255,0.2)`,
            opacity: ctaEnter,
            transform: `scale(${0.85 + ctaEnter * 0.15}) translateY(${(1 - ctaEnter) * 30}px)`,
            position: 'relative',
            overflow: 'hidden',
          }}
        >
          Hemen keşfet
          {/* Shine */}
          <div
            style={{
              position: 'absolute',
              top: 0,
              left: `${shineX}%`,
              width: '40%',
              height: '100%',
              background:
                'linear-gradient(90deg, transparent, rgba(255,255,255,0.4), transparent)',
              transform: 'skewX(-25deg)',
              pointerEvents: 'none',
            }}
          />
        </div>

        {/* Web sitesi URL'i */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 18,
            marginTop: 44,
            padding: '20px 32px',
            background: colors.white05,
            border: `1.5px solid ${colors.primary}66`,
            borderRadius: 999,
            backdropFilter: 'blur(20px)',
            opacity: urlEnter,
            transform: `translateY(${(1 - urlEnter) * 20}px) scale(${0.85 + urlEnter * 0.15})`,
            boxShadow: `0 10px 40px ${colors.primary}55`,
          }}
        >
          {/* Globe ikonu */}
          <div
            style={{
              width: 46,
              height: 46,
              borderRadius: '50%',
              background: `linear-gradient(135deg, ${colors.primary}, ${colors.accent})`,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontSize: 26,
              boxShadow: `0 4px 16px ${colors.primary}88`,
            }}
          >
            🌐
          </div>
          <div
            style={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'flex-start',
            }}
          >
            <div
              style={{
                color: colors.white60,
                fontFamily: fonts.display,
                fontSize: 16,
                fontWeight: 600,
                letterSpacing: 1.2,
                textTransform: 'uppercase',
              }}
            >
              Ziyaret et
            </div>
            <div
              style={{
                color: colors.white,
                fontFamily: fonts.display,
                fontSize: 36,
                fontWeight: 900,
                letterSpacing: -0.5,
                lineHeight: 1.1,
              }}
            >
              www.phobes.com.tr
            </div>
          </div>
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
