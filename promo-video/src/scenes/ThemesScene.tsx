import React from 'react';
import {
  AbsoluteFill,
  useCurrentFrame,
  useVideoConfig,
  spring,
  interpolate,
  Easing,
} from 'remotion';
import { colors, fonts, moduleThemes } from '../theme';
import { AnimatedBackground } from '../components/AnimatedBackground';
import { PhoneFrame } from '../components/PhoneFrame';

/**
 * Phobes'un 3 teması (Light/Dark/AMOLED) ve 2 dili (Türkçe/İngilizce) hakkındaki sahne.
 * 3 telefon perspektifle birlikte sıralanır, her biri kendi temasında aynı ana ekranı gösterir.
 * Alttaki dil seçici animasyon ortasında TR'den EN'ye geçer ve telefonlardaki metinler değişir.
 */
export const ThemesScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();

  const enter = spring({ frame, fps, config: { damping: 14, stiffness: 110 } });
  const titleEnter = spring({ frame: frame - 4, fps, config: { damping: 12 } });
  const subEnter = spring({ frame: frame - 12, fps, config: { damping: 14 } });
  const phonesEnter = spring({ frame: frame - 18, fps, config: { damping: 12 } });
  const labelsEnter = spring({ frame: frame - 38, fps, config: { damping: 14 } });
  const langEnter = spring({ frame: frame - 48, fps, config: { damping: 14 } });

  // Dil geçiş animasyonu — 60-70 arası TR → EN'ye kayar
  const langSwitch = interpolate(frame, [60, 75], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.bezier(0.4, 0, 0.2, 1),
  });

  // Çıkış (son 10 kare)
  const exitProgress = interpolate(
    frame,
    [durationInFrames - 10, durationInFrames],
    [0, 1],
    { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' }
  );

  return (
    <AbsoluteFill>
      <AnimatedBackground tint={colors.primary} secondaryTint="#1E3A5F" useAccentGlow={false} intensity={0.65} />

      <AbsoluteFill
        style={{
          padding: '110px 40px 110px 40px',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          opacity: enter - exitProgress,
          transform: `translateY(${(1 - enter) * 40 + exitProgress * 20}px)`,
        }}
      >
        {/* Başlık */}
        <h1
          style={{
            margin: 0,
            color: colors.white,
            fontFamily: fonts.display,
            fontSize: 84,
            fontWeight: 900,
            letterSpacing: -3,
            textAlign: 'center',
            lineHeight: 1,
            opacity: titleEnter,
            transform: `translateY(${(1 - titleEnter) * 30}px)`,
            textShadow: `0 0 60px ${colors.primary}88`,
          }}
        >
          Senin tarzına
          <br />
          <span
            style={{
              background: `linear-gradient(135deg, ${colors.primary}, ${colors.accent})`,
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent',
              backgroundClip: 'text',
            }}
          >
            uygun
          </span>
        </h1>

        <p
          style={{
            margin: '14px 0 30px 0',
            color: colors.white80,
            fontFamily: fonts.display,
            fontSize: 28,
            fontWeight: 500,
            textAlign: 'center',
            opacity: subEnter,
            transform: `translateY(${(1 - subEnter) * 20}px)`,
          }}
        >
          Üç tema, iki dil, sınırsız özelleştirme
        </p>

        {/* Üç telefon — perspektifle yelpaze gibi */}
        <div
          style={{
            flex: 1,
            position: 'relative',
            width: '100%',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            perspective: 1800,
            opacity: phonesEnter,
            transform: `translateY(${(1 - phonesEnter) * 50}px)`,
          }}
        >
          {/* Light theme — sol */}
          <div
            style={{
              position: 'absolute',
              left: '50%',
              top: '50%',
              marginLeft: -390,
              transform: `translate(-50%, -50%) rotateY(22deg) rotateZ(-3deg) translateY(${Math.sin(frame * 0.05) * 5}px)`,
              transformStyle: 'preserve-3d',
              filter: `drop-shadow(0 30px 50px rgba(0,0,0,0.5))`,
              zIndex: 1,
            }}
          >
            <PhoneFrame width={300}>
              <ThemePreview variant="light" lang={langSwitch < 0.5 ? 'tr' : 'en'} />
            </PhoneFrame>
          </div>

          {/* Dark theme — orta (önde) */}
          <div
            style={{
              position: 'absolute',
              left: '50%',
              top: '50%',
              transform: `translate(-50%, -50%) translateY(${-10 + Math.sin(frame * 0.05 + 1) * 4}px) scale(1.05)`,
              filter: `drop-shadow(0 40px 80px ${colors.primary}aa)`,
              zIndex: 3,
            }}
          >
            <PhoneFrame width={320}>
              <ThemePreview variant="dark" lang={langSwitch < 0.5 ? 'tr' : 'en'} />
            </PhoneFrame>
          </div>

          {/* AMOLED — sağ */}
          <div
            style={{
              position: 'absolute',
              left: '50%',
              top: '50%',
              marginLeft: 390,
              transform: `translate(-50%, -50%) rotateY(-22deg) rotateZ(3deg) translateY(${Math.sin(frame * 0.05 + 2) * 5}px)`,
              transformStyle: 'preserve-3d',
              filter: `drop-shadow(0 30px 50px rgba(0,0,0,0.5))`,
              zIndex: 1,
            }}
          >
            <PhoneFrame width={300}>
              <ThemePreview variant="amoled" lang={langSwitch < 0.5 ? 'tr' : 'en'} />
            </PhoneFrame>
          </div>
        </div>

        {/* Tema etiketleri */}
        <div
          style={{
            display: 'flex',
            gap: 90,
            marginTop: -10,
            marginBottom: 28,
            opacity: labelsEnter,
            transform: `translateY(${(1 - labelsEnter) * 20}px)`,
          }}
        >
          {['Açık', 'Koyu', 'AMOLED'].map((label, i) => (
            <div
              key={label}
              style={{
                color: i === 1 ? colors.accent : colors.white80,
                fontFamily: fonts.display,
                fontSize: 22,
                fontWeight: i === 1 ? 800 : 600,
                textAlign: 'center',
              }}
            >
              {label}
            </div>
          ))}
        </div>

        {/* Dil seçici — TR / EN toggle */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 14,
            opacity: langEnter,
            transform: `translateY(${(1 - langEnter) * 20}px)`,
          }}
        >
          <div
            style={{
              color: colors.white60,
              fontFamily: fonts.display,
              fontSize: 22,
              fontWeight: 600,
            }}
          >
            Dil:
          </div>
          <LanguageToggle progress={langSwitch} />
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

/** Telefon içine yerleştirilen mini "Bugün" ekranı, tema'ya göre renklenir. */
const ThemePreview: React.FC<{ variant: 'light' | 'dark' | 'amoled'; lang: 'tr' | 'en' }> = ({
  variant,
  lang,
}) => {
  const bg =
    variant === 'light' ? '#F8FAFC' : variant === 'amoled' ? '#000000' : '#121212';
  const surface =
    variant === 'light' ? '#FFFFFF' : variant === 'amoled' ? '#0A0A0A' : '#1E1E1E';
  const surfaceAlt =
    variant === 'light' ? '#F1F5F9' : variant === 'amoled' ? '#141414' : '#2A2A2A';
  const textPrimary = variant === 'light' ? '#0F172A' : '#FFFFFF';
  const textSecondary = variant === 'light' ? '#475569' : 'rgba(255,255,255,0.6)';
  const accent = colors.primary;

  const t = {
    today: lang === 'tr' ? 'Bugün' : 'Today',
    welcome: lang === 'tr' ? 'Merhaba, Ada' : 'Hello, Ada',
    tasks: lang === 'tr' ? 'Görev' : 'Tasks',
    notes: lang === 'tr' ? 'Not' : 'Notes',
    budget: lang === 'tr' ? 'Bütçe' : 'Budget',
    calendar: lang === 'tr' ? 'Takvim' : 'Calendar',
    todoCount: lang === 'tr' ? '5 görev kaldı' : '5 tasks left',
    quickAccess: lang === 'tr' ? 'Hızlı erişim' : 'Quick access',
  };

  return (
    <div
      style={{
        height: '100%',
        background: bg,
        paddingTop: 60,
        paddingLeft: 14,
        paddingRight: 14,
        fontFamily: fonts.display,
        position: 'relative',
        overflow: 'hidden',
      }}
    >
      {/* Karşılama */}
      <div
        style={{
          color: textPrimary,
          fontSize: 20,
          fontWeight: 800,
          letterSpacing: -0.5,
        }}
      >
        {t.welcome}
      </div>
      <div
        style={{
          color: textSecondary,
          fontSize: 12,
          fontWeight: 500,
          marginBottom: 14,
        }}
      >
        {t.todoCount}
      </div>

      {/* Quick access başlık */}
      <div
        style={{
          color: textSecondary,
          fontSize: 9,
          fontWeight: 700,
          textTransform: 'uppercase',
          letterSpacing: 1.5,
          marginBottom: 8,
        }}
      >
        {t.quickAccess}
      </div>

      {/* 2x2 modül grid */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: '1fr 1fr',
          gap: 8,
          marginBottom: 12,
        }}
      >
        {[
          { l: t.tasks, c: moduleThemes.tasks.color },
          { l: t.notes, c: moduleThemes.notes.color },
          { l: t.calendar, c: moduleThemes.calendar.color },
          { l: t.budget, c: moduleThemes.budget.color },
        ].map((m, i) => (
          <div
            key={i}
            style={{
              background: `linear-gradient(135deg, ${m.c}, ${m.c}aa)`,
              padding: 10,
              borderRadius: 10,
              aspectRatio: '2 / 1',
              display: 'flex',
              alignItems: 'flex-end',
              color: '#fff',
              fontWeight: 800,
              fontSize: 11,
            }}
          >
            {m.l}
          </div>
        ))}
      </div>

      {/* Bugün başlığı */}
      <div
        style={{
          color: textPrimary,
          fontSize: 14,
          fontWeight: 800,
          marginBottom: 8,
        }}
      >
        {t.today}
      </div>

      {/* Mini görev listesi */}
      {[0, 1, 2, 3].map((i) => (
        <div
          key={i}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 8,
            padding: 8,
            background: surface,
            borderRadius: 8,
            marginBottom: 5,
            border: variant === 'light' ? '1px solid #E2E8F0' : '1px solid rgba(255,255,255,0.05)',
          }}
        >
          <div
            style={{
              width: 12,
              height: 12,
              borderRadius: 4,
              border: `1.5px solid ${i < 2 ? accent : textSecondary}`,
              background: i < 2 ? accent : 'transparent',
              flexShrink: 0,
            }}
          />
          <div
            style={{
              flex: 1,
              color: i < 2 ? textSecondary : textPrimary,
              fontSize: 10,
              fontWeight: 600,
              textDecoration: i < 2 ? 'line-through' : 'none',
            }}
          >
            {lang === 'tr' ? ['Sunumu hazırla', 'Spor', 'Toplantı', 'Rapor yaz'][i] : ['Prepare deck', 'Workout', 'Meeting', 'Write report'][i]}
          </div>
          <div
            style={{
              color: textSecondary,
              fontSize: 9,
              fontWeight: 600,
            }}
          >
            {['09:00', '12:30', '14:00', '17:00'][i]}
          </div>
        </div>
      ))}
    </div>
  );
};

/** TR / EN arası kayan toggle — pill switcher. */
const LanguageToggle: React.FC<{ progress: number }> = ({ progress }) => {
  // progress 0 → TR aktif, 1 → EN aktif
  return (
    <div
      style={{
        position: 'relative',
        display: 'flex',
        background: colors.white10,
        border: `1.5px solid ${colors.white20}`,
        borderRadius: 999,
        padding: 6,
        backdropFilter: 'blur(20px)',
        boxShadow: `0 10px 30px ${colors.primary}33`,
      }}
    >
      {/* Sliding indicator */}
      <div
        style={{
          position: 'absolute',
          top: 6,
          left: 6,
          width: 'calc(50% - 6px)',
          height: 'calc(100% - 12px)',
          background: `linear-gradient(135deg, ${colors.primary}, ${colors.accent})`,
          borderRadius: 999,
          transform: `translateX(${progress * 100}%)`,
          boxShadow: `0 4px 20px ${colors.primary}aa`,
        }}
      />
      {[
        { code: 'TR', flag: '🇹🇷', label: 'Türkçe' },
        { code: 'EN', flag: '🇬🇧', label: 'English' },
      ].map((l, i) => {
        const active = (i === 0 && progress < 0.5) || (i === 1 && progress >= 0.5);
        return (
          <div
            key={l.code}
            style={{
              position: 'relative',
              padding: '12px 24px',
              minWidth: 130,
              textAlign: 'center',
              color: active ? colors.white : colors.white60,
              fontFamily: fonts.display,
              fontSize: 22,
              fontWeight: active ? 800 : 600,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: 8,
              transition: 'color 0.2s',
              zIndex: 1,
            }}
          >
            <span style={{ fontSize: 24 }}>{l.flag}</span>
            <span>{l.label}</span>
          </div>
        );
      })}
    </div>
  );
};
