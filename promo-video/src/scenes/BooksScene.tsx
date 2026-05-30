import React from 'react';
import { useCurrentFrame, useVideoConfig, spring, interpolate, Easing } from 'remotion';
import { SceneFrame } from '../components/SceneFrame';
import { PhoneFrame } from '../components/PhoneFrame';
import { colors, fonts, moduleThemes, statsModuleColors } from '../theme';
import { moduleSlogans } from '../moduleSlogans';

const BOOKS = [
  { title: 'Atomic Habits', author: 'James Clear', status: 'reading', progress: 68, color: '#8B5CF6' },
  { title: 'Sapiens', author: 'Yuval Noah Harari', status: 'read', progress: 100, color: '#6366F1' },
  { title: 'Dune', author: 'Frank Herbert', status: 'to_read', progress: 0, color: '#06B6D4' },
];

const TABS = ['Kütüphane', 'İstatistik', 'Alıntılar', 'Hedefler'];

export const BooksScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const theme = moduleThemes.books;
  const s = moduleSlogans.books;

  const tabSlide = interpolate(frame, [25, 45], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.out(Easing.cubic),
  });

  return (
    <SceneFrame
      tint={theme.color}
      title={s.title}
      subtitle={s.subtitle}
      badge="📖"
      transition={s.transition}
      chips={['Kütüphane', 'Okuma hedefi', 'Alıntılar', 'İstatistik']}
    >
      <PhoneFrame width={500}>
        <div
          style={{
            paddingTop: 88,
            height: '100%',
            background: colors.surface,
            fontFamily: fonts.display,
          }}
        >
          {/* Header — books_screen.dart */}
          <div
            style={{
              padding: '12px 16px',
              background: `linear-gradient(135deg, ${theme.color}44, ${colors.surface})`,
              borderBottom: `1px solid ${colors.white10}`,
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <div style={{ color: colors.white, fontSize: 20, fontWeight: 800 }}>Kitaplarım</div>
                <div style={{ color: colors.white60, fontSize: 12, marginTop: 2 }}>
                  12 kitap · 4 okundu · 2 okunuyor
                </div>
              </div>
              <div
                style={{
                  width: 36,
                  height: 36,
                  borderRadius: 10,
                  background: theme.color,
                  color: colors.white,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontSize: 22,
                  fontWeight: 700,
                }}
              >
                +
              </div>
            </div>
            <div style={{ display: 'flex', gap: 6, marginTop: 12 }}>
              {TABS.map((t, i) => {
                const active = i === 0 || (i === 1 && tabSlide > 0.5);
                const enter = spring({ frame: frame - 8 - i * 3, fps, config: { damping: 14 } });
                return (
                  <div
                    key={t}
                    style={{
                      flex: 1,
                      padding: '8px 4px',
                      borderRadius: 8,
                      background: active ? theme.color : colors.white05,
                      color: active ? colors.white : colors.white60,
                      fontSize: 10,
                      fontWeight: 700,
                      textAlign: 'center',
                      opacity: enter,
                      transform: `scale(${0.85 + enter * 0.15})`,
                    }}
                  >
                    {t}
                  </div>
                );
              })}
            </div>
          </div>

          {/* Kitap kartları */}
          <div style={{ padding: '12px 14px', display: 'flex', flexDirection: 'column', gap: 10 }}>
            {BOOKS.map((b, i) => {
              const enter = spring({ frame: frame - 18 - i * 8, fps, config: { damping: 14 } });
              const prog = interpolate(
                frame,
                [35 + i * 12, 55 + i * 12],
                [0, b.progress / 100],
                { extrapolateLeft: 'clamp', extrapolateRight: 'clamp', easing: Easing.out(Easing.cubic) }
              );
              return (
                <div
                  key={b.title}
                  style={{
                    display: 'flex',
                    gap: 12,
                    padding: 12,
                    background: colors.white05,
                    border: `1px solid ${colors.white10}`,
                    borderRadius: 14,
                    opacity: enter,
                    transform: `translateX(${(1 - enter) * 40}px)`,
                  }}
                >
                  <div
                    style={{
                      width: 48,
                      height: 64,
                      borderRadius: 8,
                      background: `linear-gradient(160deg, ${b.color}, ${b.color}88)`,
                      boxShadow: `0 8px 20px ${b.color}44`,
                      flexShrink: 0,
                    }}
                  />
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ color: colors.white, fontSize: 14, fontWeight: 700 }}>{b.title}</div>
                    <div style={{ color: colors.white60, fontSize: 11, marginTop: 2 }}>{b.author}</div>
                    <div
                      style={{
                        marginTop: 8,
                        height: 5,
                        background: colors.white10,
                        borderRadius: 999,
                        overflow: 'hidden',
                      }}
                    >
                      <div
                        style={{
                          height: '100%',
                          width: `${prog * 100}%`,
                          background: theme.color,
                          borderRadius: 999,
                        }}
                      />
                    </div>
                    <div style={{ color: theme.color, fontSize: 10, fontWeight: 700, marginTop: 4 }}>
                      {b.status === 'reading'
                        ? `%${Math.round(prog * 100)} okundu`
                        : b.status === 'read'
                          ? 'Tamamlandı ✓'
                          : 'Okunacak'}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </PhoneFrame>
    </SceneFrame>
  );
};
