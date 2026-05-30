import React from 'react';
import { colors } from '../theme';

type Props = {
  children: React.ReactNode;
  width?: number;
  style?: React.CSSProperties;
};

/**
 * Macbook benzeri laptop mockup'ı. Web sürümü göstermek için.
 */
export const LaptopFrame: React.FC<Props> = ({ children, width = 760, style }) => {
  const screenHeight = width * (10 / 16);
  const radius = 16;
  const baseHeight = 22;
  const baseWidth = width * 1.06;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', ...style }}>
      {/* Ekran */}
      <div
        style={{
          width,
          height: screenHeight,
          borderRadius: radius,
          padding: 10,
          background:
            'linear-gradient(135deg, #2a2a2a 0%, #0a0a0a 50%, #1a1a1a 100%)',
          boxShadow:
            '0 40px 80px rgba(0,0,0,0.55), 0 0 0 1.5px rgba(255,255,255,0.08) inset',
          position: 'relative',
        }}
      >
        <div
          style={{
            width: '100%',
            height: '100%',
            borderRadius: 8,
            overflow: 'hidden',
            background: colors.surface,
            position: 'relative',
          }}
        >
          {/* Browser chrome */}
          <div
            style={{
              height: 28,
              background: '#1a1a1a',
              display: 'flex',
              alignItems: 'center',
              gap: 6,
              padding: '0 12px',
              borderBottom: `1px solid ${colors.white10}`,
            }}
          >
            <div style={dot('#FF5F57')} />
            <div style={dot('#FEBC2E')} />
            <div style={dot('#28C840')} />
            <div
              style={{
                marginLeft: 12,
                background: colors.white05,
                color: colors.white60,
                fontSize: 11,
                fontFamily: 'Outfit',
                fontWeight: 500,
                padding: '3px 14px',
                borderRadius: 6,
                flex: 1,
                maxWidth: 280,
              }}
            >
              phobes.app
            </div>
          </div>
          {children}
        </div>
      </div>

      {/* Taban */}
      <div
        style={{
          width: baseWidth,
          height: baseHeight,
          background:
            'linear-gradient(180deg, #2a2a2a 0%, #1a1a1a 50%, #050505 100%)',
          borderRadius: '0 0 14px 14px',
          boxShadow: '0 20px 40px rgba(0,0,0,0.5)',
          position: 'relative',
        }}
      >
        <div
          style={{
            position: 'absolute',
            top: 0,
            left: '50%',
            transform: 'translateX(-50%)',
            width: width * 0.18,
            height: 6,
            background: '#000',
            borderRadius: '0 0 8px 8px',
          }}
        />
      </div>
    </div>
  );
};

const dot = (c: string): React.CSSProperties => ({
  width: 10,
  height: 10,
  borderRadius: 999,
  background: c,
});
