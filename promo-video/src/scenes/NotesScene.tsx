import React from 'react';
import {
  useCurrentFrame,
  useVideoConfig,
  spring,
  interpolate,
  Easing,
} from 'remotion';
import { SceneFrame } from '../components/SceneFrame';
import { PhoneFrame } from '../components/PhoneFrame';
import { colors, fonts, statsModuleColors } from '../theme';
import { moduleSlogans } from '../moduleSlogans';

// 210 frames @ 30fps = 7s — lib/screens/notes/* editör mockup
const DURATION = 210;
const ACCENT = statsModuleColors.notes; // #6366F1
const ACCENT2 = '#4F46E5';
const DESK = '#262626'; // page_canvas.dart PageCanvasScaffold
const PAPER = '#FFFFFF';

const titleText = 'Toplantı Notları';

type BodyBlock =
  | { kind: 'h1'; text: string }
  | { kind: 'p'; text: string }
  | { kind: 'bullet'; text: string; highlight?: boolean }
  | { kind: 'numbered'; n: number; text: string };

const bodyBlocks: BodyBlock[] = [
  { kind: 'h1', text: 'Sprint Planlaması' },
  { kind: 'p', text: 'Yarın sabah ekiple Q3 sprintinin önceliklerini belirleyeceğiz.' },
  { kind: 'bullet', text: 'Backend API kontratını yaz' },
  { kind: 'bullet', text: 'Frontend prototipini hazırla', highlight: true },
  { kind: 'numbered', n: 1, text: 'Tasarım review' },
  { kind: 'numbered', n: 2, text: 'Test senaryoları' },
];

const toolbarRow1 = [
  { ch: '↶', label: 'undo' },
  { ch: '↷', label: 'redo' },
  { ch: 'B', label: 'bold', bold: true },
  { ch: 'I', label: 'italic', italic: true },
  { ch: 'U', label: 'underline', underline: true },
  { ch: 'S', label: 'strike', strike: true },
];

const toolbarRow2 = [
  { ch: 'H1', label: 'h1', isText: true, active: true },
  { ch: 'H2', label: 'h2', isText: true },
  { ch: '•', label: 'bullet' },
  { ch: '1.', label: 'numbered', isText: true },
  { ch: '☑', label: 'check' },
  { ch: 'A', label: 'color', isText: true },
  { ch: '▦', label: 'table', isText: true },
  { ch: '💡', label: 'callout' },
  { ch: '☑', label: 'task' },
];

const notebookChips = [
  { emoji: '📓', name: 'Tüm Notlar', active: false },
  { emoji: '📕', name: 'İş', active: true, count: 12 },
  { emoji: '📗', name: 'Kişisel', active: false },
  { emoji: '📔', name: 'Fikirler', active: false },
];

// slash_command_overlay.dart — label + description + /key
const slashCommands = [
  {
    icon: 'H1',
    label: 'Başlık 1',
    desc: 'Büyük bölüm başlığı',
    shortcut: '/h1',
    tint: ACCENT,
  },
  {
    icon: '💡',
    label: 'Bilgi Kartı',
    desc: 'İpucu, uyarı veya bilgi kutusu',
    shortcut: '/callout',
    tint: '#00BFA5',
  },
  {
    icon: '☑',
    label: 'Görev Kartı',
    desc: 'Görevler modülünden kart ekle',
    shortcut: '/task',
    tint: '#3B82F6',
  },
  {
    icon: '▦',
    label: 'Tablo',
    desc: 'Satır ve sütunlu tablo',
    shortcut: '/table',
    tint: '#F59E0B',
  },
];

const ease = (t: number) =>
  Easing.bezier(0.22, 1, 0.36, 1)(Math.max(0, Math.min(1, t)));

const softSpring = { damping: 20, stiffness: 90, mass: 1 };

export const NotesScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // ── Daktilo başlık (28 → 72) ─────────────────────────────────────────────
  const titleStart = 28;
  const titleEnd = 72;
  const charCount = Math.max(
    0,
    Math.min(
      titleText.length,
      Math.floor(
        interpolate(frame, [titleStart, titleEnd], [0, titleText.length], {
          extrapolateLeft: 'clamp',
          extrapolateRight: 'clamp',
        }),
      ),
    ),
  );
  const isTyping = frame >= titleStart && frame <= titleEnd + 8;
  const cursorBlink = Math.floor(frame / 5) % 2 === 0 ? 1 : 0.2;
  const cursorGlow = isTyping ? 1 : 0.3;

  // ── Kağıt giriş (12 → 48) ────────────────────────────────────────────────
  const paperEnter = spring({
    frame: frame - 12,
    fps,
    config: softSpring,
  });
  const breath = 1 + Math.sin((frame / fps) * Math.PI * 0.7) * 0.002;

  // ── Slash overlay (80 → 120) ───────────────────────────────────────────
  const slashOpacity = interpolate(
    frame,
    [80, 92, 108, 120],
    [0, 1, 1, 0],
    {
      extrapolateLeft: 'clamp',
      extrapolateRight: 'clamp',
      easing: Easing.inOut(Easing.cubic),
    },
  );
  const slashScale = interpolate(
    frame,
    [80, 96],
    [0.94, 1],
    { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' },
  );

  // ── Vurgulu bullet pulse (98 → 118) ─────────────────────────────────────
  const highlightPulse = interpolate(frame, [98, 106, 112, 118], [0, 1, 1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.bezier(0.4, 0, 0.4, 1),
  });

  const headerIn = ease((frame - 4) / 18);

  return (
    <SceneFrame
      tint={ACCENT}
      title={moduleSlogans.notes.title}
      subtitle={moduleSlogans.notes.subtitle}
      transition={moduleSlogans.notes.transition}
      badge="✎"
      chips={['flutter_quill', 'Defterler', 'Slash komutu', 'Embed kartlar']}
    >
      <PhoneFrame>
        {/* Modül gradyanı — indigo #6366F1 */}
        <div
          style={{
            position: 'absolute',
            inset: 0,
            background: `radial-gradient(120% 55% at 50% 0%, ${ACCENT}40 0%, transparent 52%), linear-gradient(180deg, ${ACCENT}22 0%, ${colors.surface} 28%, ${colors.bg} 100%)`,
          }}
        />

        {/* App header */}
        <div
          style={{
            position: 'absolute',
            top: 68,
            left: 20,
            right: 20,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            opacity: headerIn,
            transform: `translateY(${(1 - headerIn) * -10}px)`,
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div
              style={{
                width: 32,
                height: 32,
                borderRadius: 10,
                background: `linear-gradient(135deg, ${ACCENT}, ${ACCENT2})`,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: colors.white,
                fontFamily: fonts.display,
                fontWeight: 800,
                fontSize: 16,
                boxShadow: `0 6px 18px ${ACCENT}55`,
              }}
            >
              ✎
            </div>
            <div
              style={{
                color: colors.white,
                fontFamily: fonts.display,
                fontWeight: 800,
                fontSize: 20,
                letterSpacing: -0.2,
              }}
            >
              Notlar
            </div>
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            {['🔍', '▦', '⇅'].map((g, i) => (
              <div
                key={i}
                style={{
                  width: 30,
                  height: 30,
                  borderRadius: 9,
                  background: colors.white05,
                  border: `1px solid ${colors.white10}`,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  color: colors.white80,
                  fontSize: 13,
                }}
              >
                {g}
              </div>
            ))}
          </div>
        </div>

        {/* Notebook chips — notebook_sidebar.dart yatay özet */}
        <div
          style={{
            position: 'absolute',
            top: 108,
            left: 0,
            right: 0,
            paddingLeft: 20,
            paddingRight: 20,
            display: 'flex',
            gap: 8,
            overflow: 'hidden',
          }}
        >
          {notebookChips.map((nb, i) => {
            const p = spring({
              frame: frame - 10 - i * 4,
              fps,
              config: softSpring,
            });
            return (
              <div
                key={nb.name}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 6,
                  padding: '6px 12px',
                  borderRadius: 999,
                  background: nb.active ? `${ACCENT}28` : colors.white05,
                  border: `1px solid ${nb.active ? `${ACCENT}88` : colors.white10}`,
                  opacity: p,
                  transform: `translateY(${(1 - p) * 10}px)`,
                }}
              >
                <span style={{ fontSize: 12 }}>{nb.emoji}</span>
                <span
                  style={{
                    color: nb.active ? ACCENT : colors.white80,
                    fontFamily: fonts.display,
                    fontSize: 12,
                    fontWeight: nb.active ? 800 : 600,
                  }}
                >
                  {nb.name}
                </span>
                {nb.count !== undefined && (
                  <span
                    style={{
                      color: ACCENT,
                      fontFamily: fonts.display,
                      fontSize: 10,
                      fontWeight: 700,
                      background: `${ACCENT}22`,
                      padding: '1px 6px',
                      borderRadius: 999,
                    }}
                  >
                    {nb.count}
                  </span>
                )}
              </div>
            );
          })}
        </div>

        {/* Editör alanı — PageCanvasScaffold (#262626 masa) */}
        <div
          style={{
            position: 'absolute',
            top: 148,
            left: 0,
            right: 0,
            bottom: 14,
            background: DESK,
            borderRadius: '16px 16px 0 0',
            opacity: paperEnter,
            transform: `translateY(${(1 - paperEnter) * 20}px)`,
            overflow: 'hidden',
            padding: '10px 12px 12px',
          }}
        >
          {/* A4 kağıt — page_canvas.dart */}
          <div
            style={{
              height: '100%',
              borderRadius: 3,
              background: PAPER,
              boxShadow:
                '0 5px 20px rgba(0,0,0,0.40), 0 2px 6px rgba(0,0,0,0.20)',
              transform: `scale(${breath})`,
              transformOrigin: 'top center',
              display: 'flex',
              flexDirection: 'column',
              overflow: 'hidden',
            }}
          >
            {/* Sayfa sekmeleri — note_add_edit_screen.dart */}
            <div
              style={{
                display: 'flex',
                gap: 6,
                padding: '8px 10px 0',
                alignItems: 'center',
                borderBottom: '1px solid #E8E8E8',
              }}
            >
              {['Sayfa 1', 'Sayfa 2', '+'].map((t, i) => {
                const p = spring({
                  frame: frame - 18 - i * 4,
                  fps,
                  config: softSpring,
                });
                const active = i === 0;
                const isPlus = i === 2;
                return (
                  <div
                    key={t}
                    style={{
                      padding: isPlus ? '4px 8px' : '5px 10px',
                      borderRadius: 8,
                      background: active
                        ? `${ACCENT}18`
                        : isPlus
                          ? 'transparent'
                          : '#F3F4F6',
                      border: active
                        ? `1px solid ${ACCENT}55`
                        : isPlus
                          ? '1px dashed #D1D5DB'
                          : '1px solid #E5E7EB',
                      color: active ? ACCENT2 : '#6B7280',
                      fontFamily: fonts.display,
                      fontSize: 10,
                      fontWeight: active ? 800 : 600,
                      opacity: p,
                    }}
                  >
                    {t}
                  </div>
                );
              })}
              <div style={{ flex: 1 }} />
              <span
                style={{
                  color: '#9CA3AF',
                  fontFamily: fonts.display,
                  fontSize: 8,
                  fontWeight: 700,
                  letterSpacing: 0.8,
                }}
              >
                A4 · DİKEY
              </span>
            </div>

            {/* Toolbar — note_toolbar.dart iki satır */}
            <div
              style={{
                margin: '8px 10px 0',
                padding: '4px 5px',
                borderRadius: 10,
                background: '#F3F4F6',
                border: '1px solid #E5E7EB',
              }}
            >
              {[toolbarRow1, toolbarRow2].map((row, ri) => (
                <div
                  key={ri}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: 2,
                    flexWrap: 'wrap',
                    marginTop: ri > 0 ? 3 : 0,
                  }}
                >
                  {row.map((btn, i) => {
                    const p = spring({
                      frame: frame - 22 - ri * 6 - i * 3,
                      fps,
                      config: softSpring,
                    });
                    const active = 'active' in btn && btn.active;
                    return (
                      <div
                        key={`${ri}-${btn.label}`}
                        style={{
                          minWidth: 'isText' in btn && btn.isText ? 24 : 22,
                          height: 22,
                          padding: 'isText' in btn && btn.isText ? '0 5px' : 0,
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          borderRadius: 6,
                          background: active ? `${ACCENT}22` : 'transparent',
                          color: active ? ACCENT2 : '#374151',
                          fontFamily: fonts.display,
                          fontWeight: 'bold' in btn && btn.bold ? 900 : 700,
                          fontStyle: 'italic' in btn && btn.italic ? 'italic' : 'normal',
                          textDecoration:
                            'underline' in btn && btn.underline
                              ? 'underline'
                              : 'strike' in btn && btn.strike
                                ? 'line-through'
                                : 'none',
                          fontSize: 11,
                          opacity: p,
                          transform: `scale(${0.5 + p * 0.5})`,
                        }}
                      >
                        {btn.ch}
                      </div>
                    );
                  })}
                </div>
              ))}
            </div>

            {/* Emoji + typewriter başlık */}
            <div
              style={{
                padding: '10px 14px 4px',
                display: 'flex',
                alignItems: 'center',
                gap: 8,
              }}
            >
              <span
                style={{
                  fontSize: 20,
                  transform: `scale(${0.5 + ease((frame - 24) / 20) * 0.5})`,
                }}
              >
                📝
              </span>
              <div
                style={{
                  fontFamily: fonts.display,
                  fontSize: 18,
                  fontWeight: 800,
                  color: '#111827',
                  display: 'flex',
                  alignItems: 'center',
                }}
              >
                {titleText.slice(0, charCount)}
                <span
                  style={{
                    display: 'inline-block',
                    width: 2,
                    height: 20,
                    background: ACCENT,
                    marginLeft: 2,
                    borderRadius: 2,
                    opacity: cursorBlink * cursorGlow,
                    boxShadow: isTyping ? `0 0 8px ${ACCENT}` : 'none',
                  }}
                />
              </div>
            </div>

            <div
              style={{
                height: 1,
                margin: '0 14px 8px',
                background: '#E5E7EB',
              }}
            />

            {/* Gövde */}
            <div
              style={{
                padding: '0 14px',
                flex: 1,
                display: 'flex',
                flexDirection: 'column',
                gap: 5,
                overflow: 'hidden',
              }}
            >
              {bodyBlocks.map((block, i) => {
                const startFrame = 54 + i * 6;
                const p = spring({
                  frame: frame - startFrame,
                  fps,
                  config: softSpring,
                });
                const tx = (1 - p) * 12;

                const isHighlight =
                  block.kind === 'bullet' && block.highlight === true;
                const highlightBg = isHighlight
                  ? `rgba(99, 102, 241, ${0.14 * highlightPulse})`
                  : 'transparent';

                if (block.kind === 'h1') {
                  return (
                    <div
                      key={i}
                      style={{
                        fontFamily: fonts.display,
                        fontSize: 13,
                        fontWeight: 800,
                        color: ACCENT2,
                        opacity: p,
                        transform: `translateX(${tx}px)`,
                      }}
                    >
                      # {block.text}
                    </div>
                  );
                }
                if (block.kind === 'p') {
                  return (
                    <div
                      key={i}
                      style={{
                        fontFamily: fonts.display,
                        fontSize: 10.5,
                        color: '#374151',
                        lineHeight: 1.45,
                        opacity: p,
                        transform: `translateX(${tx}px)`,
                      }}
                    >
                      {block.text}
                    </div>
                  );
                }
                if (block.kind === 'bullet') {
                  return (
                    <div
                      key={i}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: 7,
                        padding: '2px 5px',
                        marginLeft: -4,
                        borderRadius: 6,
                        background: highlightBg,
                        opacity: p,
                        transform: `translateX(${tx}px)`,
                        boxShadow: isHighlight
                          ? `inset 0 0 0 1px rgba(99,102,241,${0.35 * highlightPulse})`
                          : 'none',
                      }}
                    >
                      <span
                        style={{
                          width: 4,
                          height: 4,
                          borderRadius: 4,
                          background: ACCENT,
                          flexShrink: 0,
                        }}
                      />
                      <span
                        style={{
                          fontFamily: fonts.display,
                          fontSize: 10.5,
                          color: '#1F2937',
                        }}
                      >
                        {block.text}
                      </span>
                    </div>
                  );
                }
                return (
                  <div
                    key={i}
                    style={{
                      display: 'flex',
                      gap: 7,
                      opacity: p,
                      transform: `translateX(${tx}px)`,
                    }}
                  >
                    <span
                      style={{
                        fontFamily: fonts.display,
                        fontSize: 10.5,
                        fontWeight: 800,
                        color: ACCENT2,
                        minWidth: 12,
                      }}
                    >
                      {block.n}.
                    </span>
                    <span
                      style={{
                        fontFamily: fonts.display,
                        fontSize: 10.5,
                        color: '#1F2937',
                      }}
                    >
                      {block.text}
                    </span>
                  </div>
                );
              })}

              {/* Callout — callout_embed.dart tip #00BFA5 */}
              {(() => {
                const enter = spring({
                  frame: frame - 108,
                  fps,
                  config: softSpring,
                });
                const tip = '#00BFA5';
                return (
                  <div
                    style={{
                      marginTop: 6,
                      display: 'flex',
                      borderRadius: 12,
                      background: `${tip}0F`,
                      border: `1px solid ${tip}2E`,
                      overflow: 'hidden',
                      opacity: enter,
                      transform: `translateY(${(1 - enter) * -10}px)`,
                    }}
                  >
                    <div style={{ width: 4, background: tip }} />
                    <div style={{ flex: 1, padding: '8px 10px' }}>
                      <div
                        style={{
                          display: 'inline-flex',
                          alignItems: 'center',
                          gap: 4,
                          padding: '2px 7px',
                          borderRadius: 6,
                          background: `${tip}1F`,
                          marginBottom: 4,
                        }}
                      >
                        <span style={{ fontSize: 10 }}>💡</span>
                        <span
                          style={{
                            color: tip,
                            fontFamily: fonts.display,
                            fontWeight: 800,
                            fontSize: 9,
                            letterSpacing: 0.8,
                          }}
                        >
                          İPUCU
                        </span>
                      </div>
                      <div
                        style={{
                          fontFamily: fonts.display,
                          fontSize: 10.5,
                          color: '#111827',
                          lineHeight: 1.4,
                        }}
                      >
                        Yeni özellik için kullanıcı geri bildirimini dinlemeyi
                        unutma.
                      </div>
                    </div>
                  </div>
                );
              })()}

              {/* Task card — task_card_embed.dart */}
              {(() => {
                const enter = spring({
                  frame: frame - 128,
                  fps,
                  config: softSpring,
                });
                const checkPop = spring({
                  frame: frame - 178,
                  fps,
                  config: { damping: 14, stiffness: 120 },
                });
                const taskColor = '#3B82F6';
                return (
                  <div
                    style={{
                      marginTop: 4,
                      display: 'flex',
                      alignItems: 'center',
                      gap: 9,
                      padding: '8px 10px',
                      borderRadius: 10,
                      background: PAPER,
                      border: '0.8px solid #D6D6D6',
                      boxShadow: '0 4px 10px rgba(0,0,0,0.04)',
                      opacity: enter,
                      transform: `translateY(${(1 - enter) * -8}px)`,
                    }}
                  >
                    <div
                      style={{
                        width: 16,
                        height: 16,
                        borderRadius: 8,
                        border: `1.5px solid ${
                          checkPop > 0.45 ? '#16A34A' : 'rgba(26,26,26,0.15)'
                        }`,
                        background: checkPop > 0.45 ? '#16A34A' : 'transparent',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        color: colors.white,
                        fontSize: 9,
                        fontWeight: 900,
                        flexShrink: 0,
                      }}
                    >
                      {checkPop > 0.45 ? '✓' : ''}
                    </div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div
                        style={{
                          fontFamily: fonts.display,
                          fontSize: 11,
                          fontWeight: 600,
                          color: checkPop > 0.45 ? 'rgba(26,26,26,0.5)' : '#1A1A1A',
                          textDecoration:
                            checkPop > 0.45 ? 'line-through' : 'none',
                        }}
                      >
                        PR taslağını ekiple paylaş
                      </div>
                      <div
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          gap: 4,
                          marginTop: 2,
                        }}
                      >
                        <span style={{ fontSize: 9, opacity: 0.4 }}>📅</span>
                        <span
                          style={{
                            fontFamily: fonts.display,
                            fontSize: 9,
                            color: 'rgba(26,26,26,0.45)',
                          }}
                        >
                          27 May 2026, 17:00
                        </span>
                        <span style={{ fontSize: 9, color: '#EF4444' }}>🚩</span>
                      </div>
                    </div>
                    <div
                      style={{
                        width: 3,
                        height: 26,
                        borderRadius: 2,
                        background: taskColor,
                      }}
                    />
                  </div>
                );
              })()}
            </div>

            <div
              style={{
                padding: '6px 14px 8px',
                opacity: 0.5,
              }}
            >
              <span
                style={{
                  fontFamily: fonts.display,
                  fontSize: 8,
                  color: '#9CA3AF',
                  fontWeight: 600,
                }}
              >
                / yazarak komut menüsünü aç
              </span>
            </div>
          </div>
        </div>

        {/* Slash overlay — frames 80–120 */}
        {slashOpacity > 0.01 && (
          <div
            style={{
              position: 'absolute',
              top: 340,
              left: 36,
              right: 36,
              borderRadius: 14,
              background: colors.surface,
              border: `1px solid ${colors.white10}`,
              boxShadow: '0 8px 32px rgba(0,0,0,0.55)',
              overflow: 'hidden',
              opacity: slashOpacity,
              transform: `translateY(${(1 - slashOpacity) * 10}px) scale(${slashScale})`,
              transformOrigin: 'top center',
              zIndex: 20,
            }}
          >
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 6,
                padding: '9px 12px 6px',
              }}
            >
              <span style={{ color: ACCENT, fontSize: 12 }}>⚡</span>
              <span
                style={{
                  color: colors.white40,
                  fontFamily: fonts.display,
                  fontSize: 10,
                  fontWeight: 600,
                  letterSpacing: 0.4,
                }}
              >
                Slash komutları
              </span>
            </div>
            <div style={{ height: 1, background: colors.white10 }} />
            {slashCommands.map((c, i) => {
              const itemP = spring({
                frame: frame - 84 - i * 4,
                fps,
                config: softSpring,
              });
              const selected = i === 1;
              return (
                <div
                  key={c.label}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: 10,
                    padding: '7px 12px',
                    background: selected ? `${ACCENT}14` : 'transparent',
                    opacity: itemP * slashOpacity,
                  }}
                >
                  <div
                    style={{
                      width: 30,
                      height: 30,
                      borderRadius: 8,
                      background: `${c.tint}22`,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      color: c.tint,
                      fontSize: 12,
                      fontFamily: fonts.display,
                      fontWeight: 800,
                    }}
                  >
                    {c.icon}
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div
                      style={{
                        color: colors.white,
                        fontFamily: fonts.display,
                        fontSize: 11,
                        fontWeight: selected ? 700 : 600,
                      }}
                    >
                      {c.label}
                    </div>
                    <div
                      style={{
                        color: colors.white40,
                        fontFamily: fonts.display,
                        fontSize: 9,
                        marginTop: 1,
                      }}
                    >
                      {c.desc}
                    </div>
                  </div>
                  <span
                    style={{
                      color: colors.white20,
                      fontFamily: fonts.mono,
                      fontSize: 9,
                    }}
                  >
                    {c.shortcut}
                  </span>
                </div>
              );
            })}
          </div>
        )}
      </PhoneFrame>
    </SceneFrame>
  );
};

// Sahne süresi PhobesPromo.tsx ile senkron (210 kare)
export const NOTES_SCENE_DURATION = DURATION;
