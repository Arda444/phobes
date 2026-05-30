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
import { colors, fonts, moduleThemes, statsModuleColors } from '../theme';
import { moduleSlogans } from '../moduleSlogans';

// ─── Sabit veriler (statistics_screen.dart + statistics_widgets.dart) ────────
const PERIODS = ['Gün', 'Hafta', 'Ay', 'Yıl'] as const;
const TARGET_ACTIONS = 47;
const GLOBAL_SCORE = 72;

type ModuleCard = {
  key: keyof typeof statsModuleColors;
  label: string;
  icon: string;
  headline: string;
  subtitle: string;
  score: number;
  spark: number[];
};

const MODULE_CARDS: ModuleCard[] = [
  {
    key: 'tasks',
    label: 'Görevler',
    icon: '✓',
    headline: '12',
    subtitle: '%78 tamamlanma',
    score: 78,
    spark: [0.4, 0.55, 0.5, 0.7, 0.65, 0.78],
  },
  {
    key: 'habits',
    label: 'Alışkanlık',
    icon: '◌',
    headline: '34',
    subtitle: '21 gün seri',
    score: 85,
    spark: [0.6, 0.7, 0.75, 0.8, 0.82, 0.85],
  },
  {
    key: 'budget',
    label: 'Bütçe',
    icon: '₺',
    headline: '+2.4K',
    subtitle: '18 işlem',
    score: 62,
    spark: [0.3, 0.45, 0.5, 0.55, 0.58, 0.62],
  },
  {
    key: 'notes',
    label: 'Notlar',
    icon: '✎',
    headline: '8',
    subtitle: '3 favori',
    score: 71,
    spark: [0.5, 0.55, 0.6, 0.65, 0.68, 0.71],
  },
  {
    key: 'appointments',
    label: 'Randevu',
    icon: '◷',
    headline: '5',
    subtitle: '₺1.2K',
    score: 68,
    spark: [0.45, 0.5, 0.55, 0.6, 0.65, 0.68],
  },
  {
    key: 'medications',
    label: 'İlaç',
    icon: '◉',
    headline: '%92',
    subtitle: '28 doz',
    score: 92,
    spark: [0.7, 0.75, 0.8, 0.85, 0.9, 0.92],
  },
  {
    key: 'books',
    label: 'Kitap',
    icon: '📖',
    headline: '3',
    subtitle: '1 biten',
    score: 55,
    spark: [0.2, 0.3, 0.35, 0.4, 0.48, 0.55],
  },
  {
    key: 'teams',
    label: 'Ekipler',
    icon: '◍',
    headline: '2',
    subtitle: '14 üye',
    score: 60,
    spark: [0.35, 0.4, 0.45, 0.5, 0.55, 0.6],
  },
];

const BAR_MODULES = [
  { label: 'Görev', score: 78, color: statsModuleColors.tasks },
  { label: 'Alış.', score: 85, color: statsModuleColors.habits },
  { label: 'Bütçe', score: 62, color: statsModuleColors.budget },
  { label: 'Not', score: 71, color: statsModuleColors.notes },
  { label: 'Rand.', score: 68, color: statsModuleColors.appointments },
  { label: 'İlaç', score: 92, color: statsModuleColors.medications },
];

const BUDGET_PIE = [
  { label: 'Market', pct: 32, color: '#F59E0B' },
  { label: 'Ulaşım', pct: 24, color: '#06B6D4' },
  { label: 'Eğlence', pct: 18, color: '#EF4444' },
  { label: 'Sağlık', pct: 15, color: '#8B5CF6' },
  { label: 'Diğer', pct: 11, color: '#10B981' },
];

const TASK_BUCKETS = [3, 5, 2, 4];
const TASK_LABELS = ['Pzt', 'Sal', 'Çar', 'Per'];

// 7×4 heatmap (alışkanlık uyumu)
const HEATMAP: number[][] = Array.from({ length: 4 }, (_, r) =>
  Array.from({ length: 7 }, (_, c) => ((r + c) % 4) as number),
);

const HIGHLIGHT_CARD_INDEX = 0; // Görevler kartı

// ─── Ana sahne ─────────────────────────────────────────────────────────────
export const StatisticsScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const theme = moduleThemes.statistics;

  // Dönem: Gün → Hafta (frame 40)
  const periodSlide = spring({
    frame: frame - 40,
    fps,
    config: { damping: 16, stiffness: 120 },
  });
  const activePeriod = frame >= 40 ? 1 : 0;

  // Gün → Hafta: alt çizgi frame 40'ta kayar (4 pill, her biri %25)
  const pillW = 25;
  const underlineLeft =
    activePeriod === 0 ? 0 : interpolate(periodSlide, [0, 1], [0, pillW]);

  // Toplam işlem count-up
  const totalActions = Math.round(
    interpolate(frame, [24, 78], [0, TARGET_ACTIONS], {
      extrapolateLeft: 'clamp',
      extrapolateRight: 'clamp',
      easing: Easing.out(Easing.cubic),
    }),
  );

  // Global skor halkası
  const scoreProgress = interpolate(frame, [30, 85], [0, GLOBAL_SCORE / 100], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.out(Easing.cubic),
  });

  // İçerik yavaş kaydırma (alt bölümleri göster)
  const scrollY = interpolate(frame, [100, 210], [0, -320], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.inOut(Easing.cubic),
  });

  // Paylaş ikonu parıltısı (frame 230)
  const shareGlow = interpolate(frame, [228, 234, 242], [0, 1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  const headerEnter = spring({ frame, fps, config: { damping: 14 } });

  return (
    <SceneFrame
      tint={theme.color}
      title={moduleSlogans.statistics.title}
      subtitle={moduleSlogans.statistics.subtitle}
      transition={moduleSlogans.statistics.transition}
      badge="◈"
      chips={['Dönem', 'Modül skorları', 'Grafikler', 'PDF / Excel']}
    >
      <PhoneFrame width={500}>
        <div
          style={{
            height: '100%',
            background: colors.surface,
            display: 'flex',
            flexDirection: 'column',
            overflow: 'hidden',
            position: 'relative',
          }}
        >
          {/* Modül başlık — PhobesModuleHeaderBar */}
          <StatsHeader
            totalActions={totalActions}
            enter={headerEnter}
            shareGlow={shareGlow}
            tint={theme.color}
          />

          {/* Kaydırılabilir gövde */}
          <div style={{ flex: 1, overflow: 'hidden', position: 'relative' }}>
            <div
              style={{
                transform: `translateY(${scrollY}px)`,
                padding: '0 12px 24px',
              }}
            >
              <PeriodSelector
                activeIndex={activePeriod}
                underlineLeft={underlineLeft}
                frame={frame}
              />

              <GlobalSummary
                scoreProgress={scoreProgress}
                totalActions={totalActions}
                frame={frame}
                fps={fps}
                tint={theme.color}
              />

              <SectionTitle text="Modül özeti" frame={frame} delay={44} fps={fps} />

              <ModuleOverviewGrid
                frame={frame}
                fps={fps}
                highlightIndex={HIGHLIGHT_CARD_INDEX}
              />

              <SectionTitle text="Detaylı istatistik" frame={frame} delay={95} fps={fps} />
              <p
                style={{
                  margin: '0 0 10px',
                  fontFamily: fonts.display,
                  fontSize: 11,
                  color: colors.white40,
                }}
              >
                Bu hafta · tüm modüller
              </p>

              <ModuleSection
                title="Görevler"
                icon="✓"
                color={statsModuleColors.tasks}
                metricLabel="Tamamlanan"
                metricValue="12"
                frame={frame}
                fps={fps}
                delay={108}
              >
                <TaskBarChart frame={frame} fps={fps} />
              </ModuleSection>

              <ModuleSection
                title="Bütçe"
                icon="₺"
                color={statsModuleColors.budget}
                metricLabel="Net"
                metricValue="+₺2.420"
                frame={frame}
                fps={fps}
                delay={125}
              >
                <BudgetPieChart frame={frame} fps={fps} />
              </ModuleSection>

              <ModuleSection
                title="Alışkanlıklar"
                icon="◌"
                color={statsModuleColors.habits}
                metricLabel="Uyum"
                metricValue="%85"
                frame={frame}
                fps={fps}
                delay={142}
              >
                <HabitHeatmap frame={frame} fps={fps} />
              </ModuleSection>

              <ExportChips frame={frame} fps={fps} />
            </div>
          </div>
        </div>
      </PhoneFrame>
    </SceneFrame>
  );
};

// ─── Başlık şeridi ─────────────────────────────────────────────────────────
const StatsHeader: React.FC<{
  totalActions: number;
  enter: number;
  shareGlow: number;
  tint: string;
}> = ({ totalActions, enter, shareGlow, tint }) => (
  <div
    style={{
      paddingTop: 52,
      padding: '52px 14px 12px',
      background: `linear-gradient(180deg, ${tint}28 0%, transparent 100%)`,
      borderBottom: `1px solid ${colors.white10}`,
      opacity: enter,
      transform: `translateY(${(1 - enter) * -12}px)`,
      flexShrink: 0,
    }}
  >
    <div style={{ display: 'flex', alignItems: 'flex-start', gap: 10 }}>
      <div
        style={{
          width: 40,
          height: 40,
          borderRadius: 12,
          background: `${tint}33`,
          border: `1px solid ${tint}55`,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontSize: 20,
          color: tint,
          flexShrink: 0,
        }}
      >
        ◈
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div
          style={{
            fontFamily: fonts.display,
            fontSize: 20,
            fontWeight: 800,
            color: colors.white,
            lineHeight: 1.1,
          }}
        >
          İstatistikler
        </div>
        <div
          style={{
            fontFamily: fonts.display,
            fontSize: 12,
            color: colors.white60,
            marginTop: 3,
          }}
        >
          Bu hafta · {totalActions} işlem
        </div>
      </div>
      <HeaderIcon icon="↗" glow={shareGlow} tint={tint} />
      <HeaderIcon icon="↓" glow={0} tint={tint} />
      <HeaderIcon icon="↻" glow={0} tint={tint} />
    </div>
  </div>
);

const HeaderIcon: React.FC<{ icon: string; glow: number; tint: string }> = ({
  icon,
  glow,
  tint,
}) => (
  <div
    style={{
      width: 34,
      height: 34,
      borderRadius: 10,
      background: colors.white10,
      border: `1px solid ${colors.white20}`,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      fontSize: 15,
      color: colors.white80,
      flexShrink: 0,
      boxShadow:
        glow > 0
          ? `0 0 ${12 + glow * 16}px ${tint}aa, inset 0 0 8px ${tint}44`
          : undefined,
      transform: glow > 0 ? `scale(${1 + glow * 0.08})` : undefined,
    }}
  >
    {icon}
  </div>
);

// ─── Dönem seçici ──────────────────────────────────────────────────────────
const PeriodSelector: React.FC<{
  activeIndex: number;
  underlineLeft: number;
  frame: number;
}> = ({ activeIndex, underlineLeft, frame }) => {
  const enter = spring({
    frame: frame - 6,
    fps: 30,
    config: { damping: 14 },
  });

  return (
    <div
      style={{
        marginBottom: 12,
        opacity: enter,
        transform: `translateY(${(1 - enter) * 10}px)`,
      }}
    >
      <div
        style={{
          position: 'relative',
          display: 'flex',
          background: colors.white05,
          borderRadius: 12,
          padding: 3,
        }}
      >
        {PERIODS.map((label, i) => {
          const isActive = i === activeIndex;
          return (
            <div
              key={label}
              style={{
                flex: 1,
                padding: '8px 0',
                textAlign: 'center',
                fontFamily: fonts.display,
                fontSize: 11,
                fontWeight: 600,
                color: isActive ? colors.white : colors.white40,
                borderRadius: 9,
                background: isActive ? colors.primary : 'transparent',
                boxShadow: isActive
                  ? `0 2px 8px ${colors.primary}55`
                  : undefined,
                position: 'relative',
                zIndex: 1,
              }}
            >
              {label}
            </div>
          );
        })}
        {/* Kayar alt çizgi (Gün → Hafta) */}
        <div
          style={{
            position: 'absolute',
            bottom: 2,
            left: `calc(${underlineLeft}% + 4px)`,
            width: `calc(${100 / PERIODS.length}% - 8px)`,
            height: 2,
            borderRadius: 2,
            background: activeIndex === 0 ? colors.white60 : colors.primary,
            opacity: activeIndex === 0 ? 0.5 : 1,
            transition: 'none',
            zIndex: 2,
            pointerEvents: 'none',
          }}
        />
      </div>
    </div>
  );
};

// ─── Genel özet ────────────────────────────────────────────────────────────
const GlobalSummary: React.FC<{
  scoreProgress: number;
  totalActions: number;
  frame: number;
  fps: number;
  tint: string;
}> = ({ scoreProgress, totalActions, frame, fps, tint }) => {
  const enter = spring({ frame: frame - 12, fps, config: { damping: 14 } });
  const ringSize = 64;
  const stroke = 6;
  const r = (ringSize - stroke) / 2;
  const circ = 2 * Math.PI * r;
  const dash = circ * scoreProgress;

  return (
    <div
      style={{
        marginBottom: 14,
        padding: 14,
        borderRadius: 16,
        background: `linear-gradient(135deg, ${tint}18 0%, ${colors.surfaceVariant} 100%)`,
        border: `1px solid ${tint}33`,
        boxShadow: `0 8px 24px ${tint}22`,
        opacity: enter,
        transform: `translateY(${(1 - enter) * 14}px)`,
      }}
    >
      <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
        <div style={{ position: 'relative', width: ringSize, height: ringSize, flexShrink: 0 }}>
          <svg width={ringSize} height={ringSize} style={{ transform: 'rotate(-90deg)' }}>
            <circle
              cx={ringSize / 2}
              cy={ringSize / 2}
              r={r}
              fill="none"
              stroke={colors.white10}
              strokeWidth={stroke}
            />
            <circle
              cx={ringSize / 2}
              cy={ringSize / 2}
              r={r}
              fill="none"
              stroke={tint}
              strokeWidth={stroke}
              strokeDasharray={`${dash} ${circ}`}
              strokeLinecap="butt"
            />
          </svg>
          <div
            style={{
              position: 'absolute',
              inset: 0,
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <span
              style={{
                fontFamily: fonts.display,
                fontSize: 18,
                fontWeight: 800,
                color: colors.white,
                lineHeight: 1,
              }}
            >
              {Math.round(scoreProgress * 100)}
            </span>
            <span
              style={{
                fontFamily: fonts.display,
                fontSize: 8,
                color: colors.white40,
              }}
            >
              skor
            </span>
          </div>
        </div>
        <div>
          <div
            style={{
              fontFamily: fonts.display,
              fontSize: 15,
              fontWeight: 700,
              color: colors.white,
            }}
          >
            Genel aktivite
          </div>
          <div
            style={{
              fontFamily: fonts.display,
              fontSize: 11,
              color: colors.white60,
              marginTop: 3,
            }}
          >
            Bu hafta · {totalActions} işlem
          </div>
        </div>
      </div>

      <div
        style={{
          marginTop: 12,
          fontFamily: fonts.display,
          fontSize: 10,
          fontWeight: 600,
          color: colors.white40,
        }}
      >
        Modül performansı
      </div>
      <ModuleBarChart frame={frame} fps={fps} />
    </div>
  );
};

const ModuleBarChart: React.FC<{ frame: number; fps: number }> = ({ frame, fps }) => {
  const chartH = 72;
  const maxScore = 100;

  return (
    <div
      style={{
        marginTop: 8,
        height: chartH + 18,
        display: 'flex',
        alignItems: 'flex-end',
        gap: 4,
        paddingBottom: 16,
        position: 'relative',
      }}
    >
      {BAR_MODULES.map((m, i) => {
        const grow = spring({
          frame: frame - 55 - i * 3,
          fps,
          config: { damping: 14, stiffness: 90 },
        });
        const h = (m.score / maxScore) * chartH * grow;
        return (
          <div
            key={m.label}
            style={{
              flex: 1,
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              gap: 3,
            }}
          >
            <span
              style={{
                fontFamily: fonts.display,
                fontSize: 8,
                fontWeight: 700,
                color: m.color,
                opacity: grow,
              }}
            >
              {Math.round(m.score * grow)}
            </span>
            <div
              style={{
                width: '100%',
                maxWidth: 22,
                height: h,
                borderRadius: '4px 4px 0 0',
                background: `${m.color}dd`,
                boxShadow: `0 0 8px ${m.color}44`,
              }}
            />
            <span
              style={{
                position: 'absolute',
                bottom: 0,
                fontFamily: fonts.display,
                fontSize: 7,
                color: colors.white40,
                width: `${100 / BAR_MODULES.length}%`,
                left: `${(i / BAR_MODULES.length) * 100}%`,
                textAlign: 'center',
              }}
            >
              {m.label}
            </span>
          </div>
        );
      })}
    </div>
  );
};

// ─── Modül özet grid ───────────────────────────────────────────────────────
const ModuleOverviewGrid: React.FC<{
  frame: number;
  fps: number;
  highlightIndex: number;
}> = ({ frame, fps, highlightIndex }) => (
  <div
    style={{
      display: 'grid',
      gridTemplateColumns: '1fr 1fr',
      gap: 8,
      marginBottom: 16,
    }}
  >
    {MODULE_CARDS.map((card, i) => {
      const enter = spring({
        frame: frame - 52 - i * 8,
        fps,
        config: { damping: 13, stiffness: 100 },
      });
      const color = statsModuleColors[card.key];
      const pulse = interpolate(
        frame,
        [180, 195, 210, 220],
        [0, 1, 1, 0],
        { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' },
      );
      const isHighlight = i === highlightIndex;
      const pulseScale = isHighlight ? 1 + pulse * 0.04 : 1;
      const pulseGlow = isHighlight ? pulse : 0;

      return (
        <div
          key={card.key}
          style={{
            padding: '10px 10px 8px',
            borderRadius: 14,
            background: `linear-gradient(135deg, ${color}24 0%, ${colors.surfaceVariant}88 100%)`,
            border: `1px solid ${color}${isHighlight && pulseGlow > 0.3 ? 'aa' : '48'}`,
            opacity: enter,
            transform: `translateY(${(1 - enter) * 16}px) scale(${0.92 + enter * 0.08 * pulseScale})`,
            boxShadow:
              pulseGlow > 0
                ? `0 0 ${20 * pulseGlow}px ${color}88, 0 4px 12px ${color}33`
                : `0 2px 8px ${color}22`,
            minHeight: 88,
            display: 'flex',
            flexDirection: 'column',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 6 }}>
            <div
              style={{
                width: 26,
                height: 26,
                borderRadius: 8,
                background: `${color}28`,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: 12,
                color,
              }}
            >
              {card.icon}
            </div>
            <span
              style={{
                fontFamily: fonts.display,
                fontSize: 10,
                fontWeight: 700,
                color: colors.white,
                flex: 1,
              }}
            >
              {card.label}
            </span>
            <span
              style={{
                fontFamily: fonts.display,
                fontSize: 9,
                fontWeight: 700,
                color,
              }}
            >
              %{card.score}
            </span>
          </div>
          <div
            style={{
              fontFamily: fonts.display,
              fontSize: 16,
              fontWeight: 800,
              color,
              lineHeight: 1,
            }}
          >
            {card.headline}
          </div>
          <div
            style={{
              fontFamily: fonts.display,
              fontSize: 9,
              color: colors.white60,
              marginTop: 2,
              marginBottom: 6,
            }}
          >
            {card.subtitle}
          </div>
          <Sparkline
            values={card.spark}
            color={color}
            frame={frame}
            delay={58 + i * 8}
            fps={fps}
          />
        </div>
      );
    })}
  </div>
);

const Sparkline: React.FC<{
  values: number[];
  color: string;
  frame: number;
  delay: number;
  fps: number;
}> = ({ values, color, frame, delay, fps }) => {
  const progress = spring({
    frame: frame - delay,
    fps,
    config: { damping: 16 },
  });
  const w = 100;
  const h = 22;
  const pts = values
    .map((v, i) => {
      const x = (i / (values.length - 1)) * w;
      const y = h - v * h * progress;
      return `${x},${y}`;
    })
    .join(' ');

  return (
    <svg width="100%" height={h} viewBox={`0 0 ${w} ${h}`} preserveAspectRatio="none">
      <polyline
        points={pts}
        fill="none"
        stroke={color}
        strokeWidth={1.8}
        strokeLinecap="round"
        strokeLinejoin="round"
        opacity={0.85}
      />
    </svg>
  );
};

// ─── Bölüm başlığı ─────────────────────────────────────────────────────────
const SectionTitle: React.FC<{ text: string; frame: number; delay: number; fps: number }> = ({
  text,
  frame,
  delay,
  fps,
}) => {
  const enter = spring({ frame: frame - delay, fps, config: { damping: 14 } });
  return (
    <div
      style={{
        fontFamily: fonts.display,
        fontSize: 14,
        fontWeight: 800,
        color: colors.white,
        marginBottom: 8,
        opacity: enter,
        transform: `translateX(${(1 - enter) * -12}px)`,
      }}
    >
      {text}
    </div>
  );
};

// ─── Modül detay bölümü ────────────────────────────────────────────────────
const ModuleSection: React.FC<{
  title: string;
  icon: string;
  color: string;
  metricLabel: string;
  metricValue: string;
  frame: number;
  fps: number;
  delay: number;
  children: React.ReactNode;
}> = ({
  title,
  icon,
  color,
  metricLabel,
  metricValue,
  frame,
  fps,
  delay,
  children,
}) => {
  const enter = spring({ frame: frame - delay, fps, config: { damping: 14 } });
  return (
    <div
      style={{
        marginBottom: 12,
        borderRadius: 16,
        background: `linear-gradient(135deg, ${color}22 0%, ${colors.surface}88 100%)`,
        border: `1px solid ${color}44`,
        padding: '12px 12px 10px',
        opacity: enter,
        transform: `translateY(${(1 - enter) * 12}px)`,
      }}
    >
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
        <div
          style={{
            width: 36,
            height: 36,
            borderRadius: 10,
            background: `${color}28`,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontSize: 16,
            color,
          }}
        >
          {icon}
        </div>
        <div style={{ flex: 1 }}>
          <div
            style={{
              fontFamily: fonts.display,
              fontSize: 14,
              fontWeight: 800,
              color: colors.white,
            }}
          >
            {title}
          </div>
          <div style={{ fontFamily: fonts.display, fontSize: 10, color: colors.white40 }}>
            2 metrik · 1 grafik
          </div>
        </div>
        <div style={{ textAlign: 'right' }}>
          <div style={{ fontFamily: fonts.display, fontSize: 9, color: colors.white40 }}>
            {metricLabel}
          </div>
          <div
            style={{
              fontFamily: fonts.display,
              fontSize: 14,
              fontWeight: 800,
              color,
            }}
          >
            {metricValue}
          </div>
        </div>
      </div>
      <div
        style={{
          borderRadius: 12,
          background: colors.surface,
          border: `1px solid ${color}28`,
          padding: 10,
        }}
      >
        {children}
      </div>
    </div>
  );
};

// ─── Görev bar grafiği ─────────────────────────────────────────────────────
const TaskBarChart: React.FC<{ frame: number; fps: number }> = ({ frame, fps }) => {
  const max = Math.max(...TASK_BUCKETS);
  const chartH = 56;

  return (
    <div>
      <div
        style={{
          fontFamily: fonts.display,
          fontSize: 10,
          fontWeight: 700,
          color: statsModuleColors.tasks,
          marginBottom: 8,
        }}
      >
        Dönem trendi
      </div>
      <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8, height: chartH + 14 }}>
        {TASK_BUCKETS.map((v, i) => {
          const grow = spring({
            frame: frame - 115 - i * 4,
            fps,
            config: { damping: 12, stiffness: 85 },
          });
          return (
            <div key={TASK_LABELS[i]} style={{ flex: 1, textAlign: 'center' }}>
              <div
                style={{
                  height: (v / max) * chartH * grow,
                  margin: '0 auto',
                  width: '70%',
                  maxWidth: 28,
                  borderRadius: '4px 4px 0 0',
                  background: statsModuleColors.tasks,
                }}
              />
              <span
                style={{
                  fontFamily: fonts.display,
                  fontSize: 8,
                  color: colors.white40,
                  marginTop: 4,
                  display: 'block',
                }}
              >
                {TASK_LABELS[i]}
              </span>
            </div>
          );
        })}
      </div>
    </div>
  );
};

// ─── Bütçe pasta grafiği (stroke-dashoffset) ─────────────────────────────────
const BudgetPieChart: React.FC<{ frame: number; fps: number }> = ({ frame, fps }) => {
  const size = 88;
  const cx = size / 2;
  const cy = size / 2;
  const r = 32;
  const circ = 2 * Math.PI * r;
  let offset = 0;

  return (
    <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
      <svg width={size} height={size} style={{ flexShrink: 0 }}>
        {BUDGET_PIE.map((slice, i) => {
          const segLen = (slice.pct / 100) * circ;
          const draw = spring({
            frame: frame - 132 - i * 10,
            fps,
            config: { damping: 14, stiffness: 80 },
          });
          const dashLen = segLen * draw;
          const dashOffset = -offset;
          offset += segLen;
          return (
            <circle
              key={slice.label}
              cx={cx}
              cy={cy}
              r={r}
              fill="none"
              stroke={slice.color}
              strokeWidth={14}
              strokeDasharray={`${dashLen} ${circ}`}
              strokeDashoffset={dashOffset}
              transform={`rotate(-90 ${cx} ${cy})`}
              opacity={0.9}
            />
          );
        })}
        <text
          x={cx}
          y={cy - 2}
          textAnchor="middle"
          fill={colors.white}
          fontSize={11}
          fontFamily={fonts.display}
          fontWeight={800}
        >
          Gider
        </text>
        <text
          x={cx}
          y={cy + 12}
          textAnchor="middle"
          fill={colors.white40}
          fontSize={8}
          fontFamily={fonts.display}
        >
          kategoriler
        </text>
      </svg>
      <div style={{ flex: 1 }}>
        {BUDGET_PIE.map((slice, i) => {
          const enter = spring({
            frame: frame - 138 - i * 6,
            fps,
            config: { damping: 14 },
          });
          return (
            <div
              key={slice.label}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 6,
                marginBottom: 5,
                opacity: enter,
              }}
            >
              <div
                style={{
                  width: 7,
                  height: 7,
                  borderRadius: '50%',
                  background: slice.color,
                }}
              />
              <span
                style={{
                  fontFamily: fonts.display,
                  fontSize: 9,
                  color: colors.white80,
                  flex: 1,
                }}
              >
                {slice.label}
              </span>
              <span
                style={{
                  fontFamily: fonts.display,
                  fontSize: 9,
                  fontWeight: 700,
                  color: slice.color,
                }}
              >
                %{slice.pct}
              </span>
            </div>
          );
        })}
      </div>
    </div>
  );
};

// ─── Alışkanlık heatmap (dalga dolgu) ──────────────────────────────────────
const HabitHeatmap: React.FC<{ frame: number; fps: number }> = ({ frame, fps }) => {
  const cell = 11;
  const gap = 3;

  return (
    <div>
      <div
        style={{
          fontFamily: fonts.display,
          fontSize: 10,
          fontWeight: 700,
          color: statsModuleColors.habits,
          marginBottom: 8,
        }}
      >
        Uyum ısı haritası
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap }}>
        {HEATMAP.map((row, ri) => (
          <div key={ri} style={{ display: 'flex', gap }}>
            {row.map((level, ci) => {
              const waveDelay = ri * 7 + ci * 4;
              const fill = spring({
                frame: frame - 148 - waveDelay,
                fps,
                config: { damping: 16, stiffness: 100 },
              });
              const intensity = [0.08, 0.25, 0.5, 0.85][level] ?? 0.08;
              const alpha = intensity * fill;
              return (
                <div
                  key={`${ri}-${ci}`}
                  style={{
                    width: cell,
                    height: cell,
                    borderRadius: 2,
                    background:
                      level === 0
                        ? colors.white05
                        : `rgba(34, 197, 94, ${alpha})`,
                    border: `1px solid ${statsModuleColors.habits}33`,
                    transform: `scale(${0.6 + fill * 0.4})`,
                  }}
                />
              );
            })}
          </div>
        ))}
      </div>
    </div>
  );
};

// ─── Dışa aktarma chip'leri ──────────────────────────────────────────────────
const ExportChips: React.FC<{ frame: number; fps: number }> = ({ frame, fps }) => {
  const enter = spring({ frame: frame - 165, fps, config: { damping: 12 } });
  const chips = [
    { label: 'PDF rapor', color: '#EF4444', icon: '📄' },
    { label: 'Excel tablo', color: '#10B981', icon: '📊' },
  ];

  return (
    <div
      style={{
        display: 'flex',
        gap: 8,
        flexWrap: 'wrap',
        marginTop: 4,
        opacity: enter,
        transform: `translateY(${(1 - enter) * 10}px)`,
      }}
    >
      {chips.map((c, i) => {
        const pop = spring({ frame: frame - 170 - i * 6, fps, config: { damping: 10 } });
        return (
          <div
            key={c.label}
            style={{
              padding: '8px 14px',
              borderRadius: 999,
              background: `${c.color}18`,
              border: `1px solid ${c.color}44`,
              display: 'flex',
              alignItems: 'center',
              gap: 6,
              opacity: pop,
              transform: `scale(${0.85 + pop * 0.15})`,
            }}
          >
            <span style={{ fontSize: 12 }}>{c.icon}</span>
            <span
              style={{
                fontFamily: fonts.display,
                fontSize: 11,
                fontWeight: 600,
                color: colors.white80,
              }}
            >
              {c.label}
            </span>
          </div>
        );
      })}
    </div>
  );
};
