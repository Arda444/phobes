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
import { colors, fonts, moduleThemes } from '../theme';
import { moduleSlogans } from '../moduleSlogans';

/**
 * Nova AI Chat sahnesi — 180 frame (6 sn @ 30fps).
 *
 * Gerçek UI taklidi (lib/screens/chat/nova_chat_screen.dart):
 *  - Üst bar: rotating gradient yıldız avatar + "Nova" + yeşil çevrimiçi nokta
 *    + sağda arama/menü ikonları
 *  - Üstte küçük "bağlam" chip'i: "5 görev, 3 randevu, 2 ilaç bağlamından"
 *    (RAG — NovaContextBuilder göstergesi)
 *  - User mesajı: sağ hizalı, gradient mor → pembe balon, kuyruk sağ alt
 *    (PhobesTheme.secondaryGradient yerine doğrudan primary→accent kullandık)
 *  - Bot typing indicator: küçük avatar + 3 nokta bounce (faz farkı + opaklık)
 *  - Bot mesajı: typewriter, içinde bold ve italic kısımlar gradient renkli,
 *    yanıp sönen caret, bittikten sonra önemli kelimelerin altına glow
 *    çizgisi (emphasis underline) animasyonu
 *  - Eylem chip'leri: pop-in stagger (emoji + label)
 *  - Alt input bar: ataç + "Bir şey sor…" + canlı waveform + mikrofon
 *    + gradient gönder
 *  - Avatar yavaş döner (frame * 0.5°), nazikçe nefes alır
 *  - Sahne ortasında parlama (shimmer) — avatar ve bot balonu kısa süreliğine
 *    daha parlak olur
 */

type Seg = { text: string; bold?: boolean; italic?: boolean; emphasis?: boolean };

const userMsg = 'Bugün ne yapmam gerek?';

const botSegments: Seg[] = [
  { text: 'Bugün ' },
  { text: '5 görevin', bold: true, emphasis: true },
  { text: ', ' },
  { text: '2 randevun', bold: true, emphasis: true },
  { text: " ve 21:00'da bir " },
  { text: 'ilacın', bold: true, emphasis: true },
  { text: ' var. Önce sabah ilacını alıp ' },
  { text: "09:00'daki " },
  { text: 'Tasarım sunumu', italic: true, emphasis: true },
  { text: ' görevine başlamanı öneririm.' },
];

const botFullText = botSegments.map((s) => s.text).join('');
const TOTAL_CHARS = botFullText.length;

const actionChips = [
  { emoji: '📝', label: 'Sunumu aç' },
  { emoji: '💊', label: 'İlaç hatırlat' },
  { emoji: '📅', label: 'Takvime ekle' },
];

type VisibleSeg = { seg: Seg; visible: string; complete: boolean };

function getVisibleSegments(segs: Seg[], visibleChars: number): VisibleSeg[] {
  let remaining = visibleChars;
  return segs.map((seg) => {
    if (remaining <= 0) return { seg, visible: '', complete: false };
    if (remaining >= seg.text.length) {
      remaining -= seg.text.length;
      return { seg, visible: seg.text, complete: true };
    }
    const v = seg.text.slice(0, remaining);
    remaining = 0;
    return { seg, visible: v, complete: false };
  });
}

// Hex alfa yardımcı — "#F472B6" + 0..1 alfa → "#F472B6XX"
function alphaHex(hex: string, alpha: number): string {
  const a = Math.max(0, Math.min(255, Math.floor(alpha * 255)));
  return hex + a.toString(16).padStart(2, '0').toUpperCase();
}

export const NovaScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const theme = moduleThemes.nova;

  // ── Animasyon zaman planı (180 kare — yavaş, eşit dağılım) ───────────────
  // 0..12    bağlam chip
  // 4..24    user mesajı
  // 22..58   typing indicator
  // 46..122  bot typewriter
  // 124..144 emphasis underline
  // 110..146 shimmer
  // 132..    action chips

  const ctxChip = spring({ frame, fps, config: { damping: 14, stiffness: 120 } });

  const userVis = spring({
    frame: frame - 4,
    fps,
    config: { damping: 15, stiffness: 120 },
  });

  const typingShow = frame >= 22 && frame <= 58;
  const typingOpacity = interpolate(
    frame,
    [22, 30, 52, 58],
    [0, 1, 1, 0],
    { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' },
  );

  const typeStart = 46;
  const typeEnd = 122;
  const typeT = interpolate(
    frame,
    [typeStart, typeStart + 6, typeEnd - 6, typeEnd],
    [0, 0.18, 0.94, 1],
    {
      extrapolateLeft: 'clamp',
      extrapolateRight: 'clamp',
      easing: Easing.bezier(0.25, 0.1, 0.25, 1),
    },
  );
  const botChars = Math.max(0, Math.min(TOTAL_CHARS, Math.floor(typeT * TOTAL_CHARS)));
  const isTyping = frame >= typeStart && botChars < TOTAL_CHARS;
  const visibleSegs = getVisibleSegments(botSegments, botChars);

  // Bot balonu girişi
  const botBubbleVis = spring({ frame: frame - 44, fps, config: { damping: 18 } });

  const emphProgress = interpolate(frame, [124, 144], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.out(Easing.cubic),
  });

  // Action chips
  const chipsStart = 132;

  // Avatar — yavaş rotasyon + nefes
  const avatarRotation = frame * 0.5;
  const avatarPulse = 1 + Math.sin(frame * 0.12) * 0.05;

  // Shimmer — sahne ortasında Nova gradient'i parlar
  const shimmer = interpolate(frame, [110, 124, 146], [0, 1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.inOut(Easing.cubic),
  });

  // Bot balonu nazik nefes
  const breath = 1 + Math.sin(frame * 0.06) * 0.005;

  // Typewriter caret — yanıp söner
  const caretOn = Math.floor(frame / 5) % 2 === 0;

  return (
    <SceneFrame
      tint={theme.color}
      title={moduleSlogans.nova.title}
      subtitle={moduleSlogans.nova.subtitle}
      transition={moduleSlogans.nova.transition}
      badge="✦"
      chips={['Türkçe', 'Bağlam farkındalığı', 'Eylem üretir']}
    >
      <PhoneFrame>
        <div
          style={{
            paddingTop: 84,
            paddingLeft: 16,
            paddingRight: 16,
            paddingBottom: 14,
            height: '100%',
            background: `linear-gradient(180deg, ${colors.primary}29 0%, ${colors.surface} 28%, ${colors.accent}1c 100%)`,
            display: 'flex',
            flexDirection: 'column',
          }}
        >
          {/* ───────── Üst app bar ───────── */}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 12,
              paddingBottom: 10,
              marginBottom: 8,
              borderBottom: `1px solid ${colors.white10}`,
            }}
          >
            {/* Rotating gradient yıldız avatar */}
            <div
              style={{
                width: 44,
                height: 44,
                borderRadius: '50%',
                background: `linear-gradient(135deg, ${colors.primary}, ${colors.accent})`,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: colors.white,
                fontFamily: fonts.display,
                fontWeight: 900,
                fontSize: 22,
                boxShadow: `0 4px 16px ${alphaHex(
                  colors.primary,
                  0.5 + shimmer * 0.4,
                )}, 0 0 ${18 + shimmer * 36}px ${alphaHex(
                  colors.accent,
                  0.25 + shimmer * 0.55,
                )}`,
                transform: `rotate(${avatarRotation}deg) scale(${avatarPulse})`,
              }}
            >
              ✦
            </div>

            <div style={{ flex: 1, minWidth: 0 }}>
              <div
                style={{
                  color: colors.white,
                  fontFamily: fonts.display,
                  fontSize: 18,
                  fontWeight: 800,
                  lineHeight: 1.1,
                }}
              >
                Nova AI
              </div>
              <div
                style={{
                  color: colors.white60,
                  fontFamily: fonts.display,
                  fontSize: 11,
                  fontWeight: 600,
                  display: 'flex',
                  alignItems: 'center',
                  gap: 6,
                  marginTop: 2,
                }}
              >
                <div
                  style={{
                    width: 7,
                    height: 7,
                    borderRadius: '50%',
                    background: colors.secondary,
                    boxShadow: `0 0 ${4 + Math.abs(Math.sin(frame * 0.12)) * 6}px ${colors.secondary}`,
                  }}
                />
                Çevrimiçi
              </div>
            </div>

            {/* Geçmiş arama */}
            <div
              style={{
                width: 32,
                height: 32,
                borderRadius: 10,
                background: colors.white05,
                border: `1px solid ${colors.white10}`,
                color: colors.white60,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: 15,
                fontFamily: fonts.display,
              }}
            >
              ⌕
            </div>
            {/* Menü */}
            <div
              style={{
                width: 32,
                height: 32,
                borderRadius: 10,
                background: colors.white05,
                border: `1px solid ${colors.white10}`,
                color: colors.white60,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: 20,
                fontFamily: fonts.display,
                fontWeight: 700,
                lineHeight: 1,
              }}
            >
              ⋮
            </div>
          </div>

          {/* ───────── Bağlam chip (RAG göstergesi) ───────── */}
          <div
            style={{
              alignSelf: 'center',
              marginBottom: 14,
              padding: '6px 12px',
              borderRadius: 999,
              background: `linear-gradient(135deg, ${colors.primary}33, ${colors.accent}33)`,
              border: `1px solid ${colors.primary}55`,
              color: colors.white80,
              fontFamily: fonts.display,
              fontSize: 11,
              fontWeight: 600,
              display: 'flex',
              alignItems: 'center',
              gap: 6,
              opacity: ctxChip,
              transform: `translateY(${(1 - ctxChip) * -10}px) scale(${0.7 + ctxChip * 0.3})`,
              boxShadow: `0 0 ${10 + shimmer * 14}px ${alphaHex(colors.primary, 0.25 + shimmer * 0.3)}`,
            }}
          >
            <span style={{ fontSize: 10 }}>✦</span>
            5 görev, 3 randevu, 2 ilaç bağlamından
          </div>

          {/* ───────── Mesaj listesi ───────── */}
          <div
            style={{
              flex: 1,
              display: 'flex',
              flexDirection: 'column',
              gap: 12,
              minHeight: 0,
            }}
          >
            {/* User mesajı — sağdan slide-in + spring */}
            <div
              style={{
                alignSelf: 'flex-end',
                maxWidth: '78%',
                padding: '12px 16px',
                background: `linear-gradient(135deg, ${colors.secondary}, #059669)`,
                color: colors.white,
                fontFamily: fonts.display,
                fontSize: 15,
                fontWeight: 500,
                lineHeight: 1.4,
                borderRadius: '20px 20px 4px 20px',
                opacity: userVis,
                transform: `translateX(${(1 - userVis) * 80}px) scale(${0.86 + userVis * 0.14})`,
                boxShadow: `0 8px 24px ${alphaHex(colors.secondary, 0.45)}, inset 0 1px 0 ${colors.white20}`,
              }}
            >
              {userMsg}
            </div>

            {/* Typing indicator */}
            {typingShow && (
              <div
                style={{
                  display: 'flex',
                  alignItems: 'flex-end',
                  gap: 8,
                  alignSelf: 'flex-start',
                  opacity: typingOpacity,
                }}
              >
                <div
                  style={{
                    width: 24,
                    height: 24,
                    borderRadius: '50%',
                    background: `linear-gradient(135deg, ${colors.primary}, ${colors.accent})`,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    color: colors.white,
                    fontSize: 12,
                    fontWeight: 900,
                    fontFamily: fonts.display,
                    flexShrink: 0,
                    boxShadow: `0 2px 8px ${alphaHex(colors.primary, 0.4)}`,
                  }}
                >
                  ✦
                </div>
                <div
                  style={{
                    padding: '10px 14px',
                    background: colors.white05,
                    border: `1px solid ${colors.white10}`,
                    borderRadius: '18px 18px 18px 4px',
                    display: 'flex',
                    gap: 5,
                    alignItems: 'center',
                  }}
                >
                  {[0, 1, 2].map((i) => {
                    const phase = (frame - 24 - i * 4) * 0.38;
                    const bounce = Math.sin(phase) * 4;
                    const alphaT = (Math.sin(phase) + 1) / 2;
                    return (
                      <div
                        key={i}
                        style={{
                          width: 7,
                          height: 7,
                          borderRadius: '50%',
                          background: `rgba(255,255,255,${0.32 + alphaT * 0.5})`,
                          transform: `translateY(${bounce}px)`,
                        }}
                      />
                    );
                  })}
                </div>
              </div>
            )}

            {/* Bot mesajı — typewriter + zengin metin + emphasis */}
            {frame >= 44 && (
              <div
                style={{
                  display: 'flex',
                  alignItems: 'flex-end',
                  gap: 8,
                  alignSelf: 'flex-start',
                  maxWidth: '94%',
                  opacity: botBubbleVis,
                  transform: `translateY(${(1 - botBubbleVis) * 18}px)`,
                }}
              >
                <div
                  style={{
                    width: 24,
                    height: 24,
                    borderRadius: '50%',
                    background: `linear-gradient(135deg, ${colors.primary}, ${colors.accent})`,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    color: colors.white,
                    fontSize: 12,
                    fontWeight: 900,
                    fontFamily: fonts.display,
                    flexShrink: 0,
                    boxShadow: `0 2px 8px ${alphaHex(colors.primary, 0.5)}, 0 0 ${8 + shimmer * 18}px ${alphaHex(colors.accent, 0.3 + shimmer * 0.5)}`,
                  }}
                >
                  ✦
                </div>
                <div
                  style={{
                    padding: '14px 16px',
                    background: `linear-gradient(180deg, ${colors.white05}, rgba(255,255,255,0.02))`,
                    border: `1px solid ${colors.white10}`,
                    color: colors.white,
                    fontFamily: fonts.display,
                    fontSize: 14,
                    fontWeight: 500,
                    lineHeight: 1.55,
                    borderRadius: '20px 20px 20px 4px',
                    boxShadow: `0 6px 18px rgba(0,0,0,0.35), 0 0 ${shimmer * 26}px ${alphaHex(colors.accent, shimmer * 0.4)}`,
                    transform: `scale(${breath})`,
                    transformOrigin: 'bottom left',
                  }}
                >
                  {visibleSegs.map((vs, i) => {
                    if (!vs.visible) return null;
                    const isColored = !!(vs.seg.bold || vs.seg.italic);
                    const showEmph =
                      !!vs.seg.emphasis && vs.complete && emphProgress > 0;

                    const segStyle: React.CSSProperties = {
                      fontWeight: vs.seg.bold ? 800 : 500,
                      fontStyle: vs.seg.italic ? 'italic' : 'normal',
                      position: 'relative',
                      display: 'inline-block',
                      whiteSpace: 'pre-wrap',
                      ...(isColored
                        ? {
                            background: `linear-gradient(90deg, ${colors.primary}, ${colors.accent})`,
                            WebkitBackgroundClip: 'text',
                            WebkitTextFillColor: 'transparent',
                            backgroundClip: 'text',
                            // gradient-clip uygulanan span'in shadow ile parlaması için
                            // ek bir blur shadow yok; emphasis altı çizgisi yapacak.
                          }
                        : {}),
                    };

                    return (
                      <span key={i} style={segStyle}>
                        {vs.visible}
                        {showEmph && (
                          <span
                            style={{
                              position: 'absolute',
                              left: 0,
                              right: 0,
                              bottom: -1,
                              height: 2,
                              borderRadius: 1,
                              background: `linear-gradient(90deg, ${colors.primary}, ${colors.accent})`,
                              transformOrigin: 'left center',
                              transform: `scaleX(${emphProgress})`,
                              boxShadow: `0 0 8px ${alphaHex(colors.accent, emphProgress * 0.8)}`,
                              pointerEvents: 'none',
                            }}
                          />
                        )}
                      </span>
                    );
                  })}
                  {isTyping && (
                    <span
                      style={{
                        display: 'inline-block',
                        width: 2,
                        height: 14,
                        background: colors.accent,
                        verticalAlign: 'middle',
                        marginLeft: 2,
                        opacity: caretOn ? 1 : 0,
                        boxShadow: `0 0 6px ${colors.accent}`,
                        borderRadius: 1,
                      }}
                    />
                  )}
                </div>
              </div>
            )}

            {/* Eylem chip'leri — pop-in stagger */}
            {frame >= chipsStart && (
              <div
                style={{
                  display: 'flex',
                  gap: 8,
                  flexWrap: 'wrap',
                  marginLeft: 32,
                  marginTop: 2,
                }}
              >
                {actionChips.map((c, i) => {
                  const p = spring({
                    frame: frame - chipsStart - i * 8,
                    fps,
                    config: { damping: 13, stiffness: 140 },
                  });
                  return (
                    <div
                      key={i}
                      style={{
                        padding: '8px 14px',
                        background: `linear-gradient(135deg, ${colors.white10}, ${colors.white05})`,
                        border: `1px solid ${theme.color}77`,
                        color: colors.white,
                        fontFamily: fonts.display,
                        fontSize: 12,
                        fontWeight: 600,
                        borderRadius: 999,
                        display: 'flex',
                        alignItems: 'center',
                        gap: 6,
                        opacity: p,
                        transform: `translateY(${(1 - p) * 12}px) scale(${0.7 + p * 0.3})`,
                        boxShadow: `0 4px 14px ${alphaHex(theme.color, 0.25)}`,
                      }}
                    >
                      <span style={{ fontSize: 13 }}>{c.emoji}</span>
                      {c.label}
                    </div>
                  );
                })}
              </div>
            )}
          </div>

          {/* ───────── Alt input bar ───────── */}
          <div
            style={{
              marginTop: 12,
              padding: '10px 12px',
              background: `linear-gradient(180deg, ${colors.white05}, rgba(255,255,255,0.02))`,
              border: `1px solid ${colors.white10}`,
              borderRadius: 26,
              display: 'flex',
              alignItems: 'center',
              gap: 10,
              boxShadow: '0 -4px 18px rgba(0,0,0,0.25)',
            }}
          >
            {/* Ataç */}
            <div
              style={{
                width: 26,
                height: 26,
                color: colors.white40,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: 16,
                fontFamily: fonts.display,
                transform: 'rotate(-30deg)',
              }}
            >
              ⌘
            </div>

            {/* Placeholder */}
            <div
              style={{
                color: colors.white40,
                fontFamily: fonts.display,
                fontSize: 13,
                fontWeight: 500,
                flex: 1,
              }}
            >
              Bir şey sor…
            </div>

            {/* Canlı waveform (mikrofon listening görseli) */}
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 3,
                padding: '0 4px',
                height: 24,
              }}
            >
              {[0, 1, 2, 3, 4, 5, 6].map((i) => {
                const h = 4 + (Math.sin((frame + i * 4) * 0.35) + 1) * 7;
                return (
                  <div
                    key={i}
                    style={{
                      width: 2.5,
                      height: h,
                      background: `linear-gradient(180deg, ${colors.accent}, ${colors.primary})`,
                      borderRadius: 2,
                      opacity: 0.75,
                    }}
                  />
                );
              })}
            </div>

            {/* Mikrofon ikonu (hafif kırmızı pulse — listening) */}
            <div
              style={{
                width: 30,
                height: 30,
                borderRadius: '50%',
                background: `rgba(239,68,68,${0.18 + Math.abs(Math.sin(frame * 0.18)) * 0.18})`,
                color: colors.white,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: 13,
                fontFamily: fonts.display,
                fontWeight: 800,
              }}
            >
              ●
            </div>

            {/* Gönder */}
            <div
              style={{
                width: 34,
                height: 34,
                borderRadius: '50%',
                background: `linear-gradient(135deg, ${colors.primary}, ${colors.accent})`,
                color: colors.white,
                fontFamily: fonts.display,
                fontWeight: 800,
                fontSize: 16,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                boxShadow: `0 4px 14px ${alphaHex(colors.primary, 0.5)}`,
              }}
            >
              ↑
            </div>
          </div>
        </div>
      </PhoneFrame>
    </SceneFrame>
  );
};
