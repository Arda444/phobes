import React from 'react';
import { colors } from '../theme';

type Props = {
  children: React.ReactNode;
  width?: number;
  /** Üstündeki "dynamic island" gösterilsin mi */
  showNotch?: boolean;
  style?: React.CSSProperties;
};

/**
 * Sinematik telefon mockup'ı. Çocuk içeriği iç ekran içinde render eder.
 * Boyut oranı: iPhone 15 Pro (yaklaşık 9:19.5).
 */
export const PhoneFrame: React.FC<Props> = ({
  children,
  width = 540,
  showNotch = true,
  style,
}) => {
  const height = width * (852 / 393);
  const radius = width * 0.14;
  const innerRadius = radius - 6;

  return (
    <div
      style={{
        width,
        height,
        borderRadius: radius,
        padding: 8,
        background:
          'linear-gradient(135deg, #2a2a2a 0%, #0a0a0a 50%, #1a1a1a 100%)',
        boxShadow:
          '0 60px 120px rgba(0,0,0,0.55), 0 0 0 1.5px rgba(255,255,255,0.08) inset, 0 0 0 4px #000',
        position: 'relative',
        ...style,
      }}
    >
      {/* İç ekran */}
      <div
        style={{
          width: '100%',
          height: '100%',
          borderRadius: innerRadius,
          overflow: 'hidden',
          background: colors.surface,
          position: 'relative',
        }}
      >
        {children}

        {/* Dynamic island */}
        {showNotch && (
          <div
            style={{
              position: 'absolute',
              top: 18,
              left: '50%',
              transform: 'translateX(-50%)',
              width: width * 0.28,
              height: 28,
              borderRadius: 999,
              background: '#000',
              zIndex: 20,
            }}
          />
        )}

        {/* Status bar */}
        <div
          style={{
            position: 'absolute',
            top: 14,
            left: 30,
            right: 30,
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            color: colors.white,
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: 600,
            zIndex: 19,
          }}
        >
          <span>9:41</span>
          <span style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
            <span style={{ fontSize: 12 }}>●●●●</span>
          </span>
        </div>
      </div>
    </div>
  );
};
