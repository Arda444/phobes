import React from 'react';
import { colors } from '../theme';

type Props = {
  children: React.ReactNode;
  width?: number;
  style?: React.CSSProperties;
};

/** iPad tarzı tablet mockup — MultiDevice sahnesinde solda. */
export const TabletFrame: React.FC<Props> = ({ children, width = 420, style }) => {
  const height = width * (4 / 3);
  const radius = width * 0.06;
  const bezel = 14;

  return (
    <div
      style={{
        width,
        height,
        borderRadius: radius,
        padding: bezel,
        background:
          'linear-gradient(145deg, #3a3a3a 0%, #1a1a1a 40%, #0d0d0d 100%)',
        boxShadow:
          '0 40px 90px rgba(0,0,0,0.55), 0 0 0 1.5px rgba(255,255,255,0.08) inset',
        position: 'relative',
        ...style,
      }}
    >
      <div
        style={{
          width: '100%',
          height: '100%',
          borderRadius: radius - 4,
          overflow: 'hidden',
          background: colors.surface,
          position: 'relative',
        }}
      >
        {children}
      </div>
    </div>
  );
};
