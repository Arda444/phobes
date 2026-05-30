import React from 'react';
import { AbsoluteFill, useCurrentFrame, interpolate } from 'remotion';
import { colors } from '../theme';

type Props = {
  /** Şu anki sahnenin ana rengi. Arka plan ona doğru "yumuşar". */
  tint?: string;
  /** İkinci aurora rengi (varsayılan: koyu mavi, pembe değil) */
  secondaryTint?: string;
  /** true ise ikinci katman pembe accent kullanır */
  useAccentGlow?: boolean;
  /** Yumuşak parlama oranı 0..1 */
  intensity?: number;
};

/**
 * Tüm sahnelerin arkasında akan, hafif hareket eden gradient + grain efekti.
 */
export const AnimatedBackground: React.FC<Props> = ({
  tint = colors.primary,
  secondaryTint = '#1E3A5F',
  useAccentGlow = false,
  intensity = 0.6,
}) => {
  const glow2 = useAccentGlow ? colors.accent : secondaryTint;
  const frame = useCurrentFrame();

  // Yavaş döner bir aurora etkisi
  const angle = (frame * 0.4) % 360;
  const x1 = 50 + Math.sin((angle * Math.PI) / 180) * 25;
  const y1 = 50 + Math.cos((angle * Math.PI) / 180) * 25;
  const x2 = 50 - Math.sin((angle * Math.PI) / 180) * 25;
  const y2 = 50 - Math.cos((angle * Math.PI) / 180) * 25;

  const pulse = interpolate(
    Math.sin((frame / 30) * Math.PI),
    [-1, 1],
    [0.7, 1.0]
  );

  return (
    <AbsoluteFill style={{ background: colors.bg, overflow: 'hidden' }}>
      {/* Aurora #1 */}
      <div
        style={{
          position: 'absolute',
          inset: -200,
          background: `radial-gradient(ellipse at ${x1}% ${y1}%, ${tint}${toHex(intensity * pulse * 0.6)}, transparent 60%)`,
          filter: 'blur(80px)',
        }}
      />
      {/* Aurora #2 — ters rengin yansıması */}
      <div
        style={{
          position: 'absolute',
          inset: -200,
          background: `radial-gradient(ellipse at ${x2}% ${y2}%, ${glow2}${toHex(intensity * 0.35)}, transparent 60%)`,
          filter: 'blur(120px)',
          mixBlendMode: 'screen',
        }}
      />
      {/* Hafif vignette */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          background:
            'radial-gradient(ellipse at center, transparent 40%, rgba(0,0,0,0.55) 100%)',
        }}
      />
      {/* Grain noise (kaliteyi sinematik yapıyor) */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          opacity: 0.06,
          backgroundImage:
            'url("data:image/svg+xml;utf8,<svg xmlns=\'http://www.w3.org/2000/svg\' width=\'200\' height=\'200\'><filter id=\'n\'><feTurbulence type=\'fractalNoise\' baseFrequency=\'0.9\' numOctaves=\'2\' stitchTiles=\'stitch\'/></filter><rect width=\'100%25\' height=\'100%25\' filter=\'url(%23n)\' opacity=\'0.6\'/></svg>")',
          mixBlendMode: 'overlay',
        }}
      />
    </AbsoluteFill>
  );
};

function toHex(v: number): string {
  const clamped = Math.max(0, Math.min(1, v));
  const hex = Math.round(clamped * 255).toString(16).padStart(2, '0');
  return hex;
}
