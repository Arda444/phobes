import React from 'react';
import { colors } from '../theme';

type Props = {
  children: React.ReactNode;
  accent?: string;
  style?: React.CSSProperties;
  glow?: boolean;
};

/**
 * Genel cam-efektli (glassmorphism) kart. Phobes'un PremiumNavBar görselliğini
 * yansıtacak şekilde tasarlandı.
 */
export const Card: React.FC<Props> = ({ children, accent = colors.primary, style, glow = true }) => {
  return (
    <div
      style={{
        position: 'relative',
        background:
          'linear-gradient(135deg, rgba(255,255,255,0.10) 0%, rgba(255,255,255,0.03) 100%)',
        border: `1.5px solid ${colors.white20}`,
        borderRadius: 28,
        padding: 24,
        backdropFilter: 'blur(20px)',
        WebkitBackdropFilter: 'blur(20px)',
        boxShadow: glow
          ? `0 30px 80px rgba(0,0,0,0.45), 0 0 60px ${accent}33, inset 0 1px 0 rgba(255,255,255,0.15)`
          : '0 30px 80px rgba(0,0,0,0.45)',
        ...style,
      }}
    >
      {children}
    </div>
  );
};
