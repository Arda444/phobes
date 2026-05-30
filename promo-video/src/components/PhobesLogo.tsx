import React from 'react';
import { Img, staticFile, useCurrentFrame, spring, useVideoConfig } from 'remotion';

type Props = {
  size?: number;
  borderRadius?: number;
  style?: React.CSSProperties;
  /** Giriş animasyonu (spring scale) */
  animate?: boolean;
  /** Hafif nabız */
  pulse?: boolean;
};

/** Gerçek Phobes logosu — public/logo.png (phobes/resimler/log.png veya assets/icon/icon.png) */
export const PhobesLogo: React.FC<Props> = ({
  size = 220,
  borderRadius,
  style,
  animate = true,
  pulse = false,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const enter = animate
    ? spring({ frame, fps, config: { damping: 10, mass: 0.75 } })
    : 1;
  const pulseScale = pulse ? 1 + Math.sin((frame / fps) * Math.PI * 2.5) * 0.025 : 1;
  const radius = borderRadius ?? size * 0.22;

  return (
    <Img
      src={staticFile('logo.png')}
      style={{
        width: size,
        height: size,
        borderRadius: radius,
        objectFit: 'cover',
        opacity: enter,
        transform: `scale(${enter * pulseScale})`,
        boxShadow: '0 24px 80px rgba(139, 92, 246, 0.45), inset 0 2px 0 rgba(255,255,255,0.15)',
        ...style,
      }}
    />
  );
};
