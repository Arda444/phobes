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

/**
 * Bütçe sahnesi — 210 kare (7 sn @ 30 fps).
 * lib/screens/budget/budget_screen.dart + overview / accounts / goals sekmeleri.
 * Modül rengi: statsModuleColors.budget (#F59E0B).
 *
 * Zaman çizgisi (yavaş, 210 kareye yayılı):
 *   0–30   sekme barı + başlık girişi
 *  12–58   net değer count-up (header)
 *  28–72   banka kartı spring + bakiye count-up
 *  52–108  gelir / gider özet kartları
 *  78–138  donut çizim + legend stagger
 * 118–168  işlem satırları
 * 148–198  tasarruf hedefi ilerleme
 * 172–192  işlem highlight nabız
 */

const TINT = statsModuleColors.budget;
const BANK_GRADIENT: [string, string] = ['#667EEA', '#764BA2'];

type Tab = { label: string; icon: string };
const TABS: Tab[] = [
  { label: 'Genel Bakış', icon: '⌂' },
  { label: 'İstatistikler', icon: '◈' },
  { label: 'Hesaplar', icon: '▭' },
  { label: 'Borçlar', icon: '⇄' },
  { label: 'Hedefler', icon: '◎' },
];
const ACTIVE_TAB = 0;

type Category = { label: string; pct: number; color: string };
const CATEGORIES: Category[] = [
  { label: 'Market', pct: 32, color: '#F59E0B' },
  { label: 'Ulaşım', pct: 24, color: '#06B6D4' },
  { label: 'Eğlence', pct: 18, color: '#EF4444' },
  { label: 'Sağlık', pct: 15, color: '#8B5CF6' },
  { label: 'Diğer', pct: 11, color: '#10B981' },
];

type Tx = {
  name: string;
  cat: string;
  date: string;
  amount: number;
  isIncome: boolean;
};
const TRANSACTIONS: Tx[] = [
  { name: 'Maaş — Eylül', cat: 'Gelir', date: 'Bugün', amount: 24500, isIncome: true },
  { name: 'Migros Market', cat: 'Market', date: 'Bugün', amount: 1280.5, isIncome: false },
  { name: 'Spotify Premium', cat: 'Eğlence', date: 'Dün', amount: 89.99, isIncome: false },
];

const TARGET_NET_WORTH = 41620;
const TARGET_BALANCE = 23420.5;
const TARGET_INCOME = 38500;
const TARGET_EXPENSE = 15080.5;
const GOAL_PCT = 0.72;

const fmtTRY = (n: number) =>
  n.toLocaleString('tr-TR', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
const fmtInt = (n: number) => Math.round(n).toLocaleString('tr-TR');

function easeCount(frame: number, start: number, end: number, target: number) {
  return (
    interpolate(frame, [start, end], [0, target], {
      extrapolateLeft: 'clamp',
      extrapolateRight: 'clamp',
      easing: Easing.out(Easing.cubic),
    })
  );
}

export const BudgetScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const netWorth = easeCount(frame, 12, 58, TARGET_NET_WORTH);
  const balance = easeCount(frame, 42, 72, TARGET_BALANCE);
  const income = easeCount(frame, 58, 98, TARGET_INCOME);
  const expense = easeCount(frame, 64, 104, TARGET_EXPENSE);

  const pieProgress = interpolate(frame, [78, 128], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.out(Easing.cubic),
  });

  const centerPop = spring({
    frame: frame - 108,
    fps,
    config: { damping: 10, stiffness: 120 },
  });

  const tabUnderline = spring({
    frame: frame - 4,
    fps,
    config: { damping: 18, stiffness: 100 },
  });

  const goalProgress = interpolate(frame, [148, 192], [0, GOAL_PCT], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.out(Easing.cubic),
  });
  const goalGlow = 0.45 + 0.55 * Math.sin((frame - 160) * 0.12);

  const shine = ((frame * 4) % 420) - 90;
  const breathing = 1 + Math.sin(frame * 0.07) * 0.005;

  const highlightPulse = interpolate(
    frame,
    [172, 178, 186, 194],
    [0, 1, 1, 0],
    { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' },
  );
  const highlightScale = 1 + highlightPulse * 0.04;

  return (
    <SceneFrame
      tint={TINT}
      title={moduleSlogans.budget.title}
      subtitle={moduleSlogans.budget.subtitle}
      transition={moduleSlogans.budget.transition}
      badge="₺"
      chips={['Hesap kartları', 'Harcama dağılımı', 'Borç takibi', 'Finansal hedef']}
    >
      <PhoneFrame>
        <div
          style={{
            paddingTop: 54,
            height: '100%',
            background: `linear-gradient(180deg, ${TINT}1F 0%, ${colors.surface} 24%)`,
            display: 'flex',
            flexDirection: 'column',
            overflow: 'hidden',
          }}
        >
          <ModuleHeader netWorth={netWorth} />
          <TabBar tabs={TABS} active={ACTIVE_TAB} underlineProgress={tabUnderline} />

          <div style={{ padding: '2px 14px 0 14px', flex: 1, overflow: 'hidden' }}>
            <BankCard
              balance={balance}
              shine={shine}
              breathing={breathing}
              frame={frame}
              fps={fps}
            />

            <div style={{ display: 'flex', gap: 8, marginTop: 10 }}>
              <SummaryCard
                label="Aylık Gelir"
                amount={income}
                color="#10B981"
                isExpense={false}
                change="+12,4%"
                frame={frame}
                fps={fps}
                delay={52}
              />
              <SummaryCard
                label="Aylık Gider"
                amount={expense}
                color="#EF4444"
                isExpense
                change="-3,2%"
                frame={frame}
                fps={fps}
                delay={58}
              />
            </div>

            <AnalysisCard
              pieProgress={pieProgress}
              centerPop={centerPop}
              categories={CATEGORIES}
              total={TARGET_EXPENSE}
              frame={frame}
              fps={fps}
            />

            <SectionHeader label="Son İşlemler" />
            {TRANSACTIONS.map((tx, i) => {
              const rowEnter = spring({
                frame: frame - 118 - i * 8,
                fps,
                config: { damping: 15, stiffness: 95 },
              });
              const amountEnter = spring({
                frame: frame - 126 - i * 8,
                fps,
                config: { damping: 15, stiffness: 95 },
              });
              const isHighlight = i === 1;
              return (
                <TransactionRow
                  key={tx.name}
                  tx={tx}
                  rowEnter={rowEnter}
                  amountEnter={amountEnter}
                  scale={isHighlight ? highlightScale : 1}
                  glow={isHighlight ? highlightPulse : 0}
                />
              );
            })}

            <GoalCard
              progress={goalProgress}
              glow={goalGlow}
              targetPct={Math.round(GOAL_PCT * 100)}
              frame={frame}
              fps={fps}
            />
          </div>
        </div>
      </PhoneFrame>
    </SceneFrame>
  );
};

const ModuleHeader: React.FC<{ netWorth: number }> = ({ netWorth }) => (
  <div
    style={{
      padding: '4px 18px 2px 18px',
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center',
    }}
  >
    <div style={{ display: 'flex', alignItems: 'center', gap: 9 }}>
      <div
        style={{
          width: 28,
          height: 28,
          borderRadius: 8,
          background: `linear-gradient(135deg, ${TINT}, #D97706)`,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          color: colors.white,
          fontFamily: fonts.display,
          fontWeight: 800,
          fontSize: 14,
          boxShadow: `0 5px 12px ${TINT}55`,
        }}
      >
        ₺
      </div>
      <div
        style={{
          color: colors.white,
          fontFamily: fonts.display,
          fontWeight: 800,
          fontSize: 17,
          letterSpacing: -0.3,
        }}
      >
        Bütçe
      </div>
    </div>
    <div style={{ textAlign: 'right' }}>
      <div
        style={{
          color: colors.white40,
          fontFamily: fonts.display,
          fontSize: 9,
          fontWeight: 600,
          letterSpacing: 0.5,
        }}
      >
        Net Değer
      </div>
      <div
        style={{
          color: colors.white,
          fontFamily: fonts.display,
          fontWeight: 800,
          fontSize: 15,
          letterSpacing: -0.3,
        }}
      >
        ₺{fmtInt(netWorth)}
      </div>
    </div>
  </div>
);

const TabBar: React.FC<{
  tabs: Tab[];
  active: number;
  underlineProgress: number;
}> = ({ tabs, active, underlineProgress }) => {
  const startIdx = 2;
  const idx = startIdx + (active - startIdx) * underlineProgress;
  const widthPct = 100 / tabs.length;
  const leftPct = idx * widthPct;

  return (
    <div
      style={{
        position: 'relative',
        margin: '2px 10px 0 10px',
        borderBottom: `1px solid ${colors.white10}`,
      }}
    >
      <div style={{ display: 'flex' }}>
        {tabs.map((t, i) => {
          const isActive = i === active;
          return (
            <div
              key={t.label}
              style={{
                flex: 1,
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                padding: '7px 0 9px 0',
                gap: 2,
              }}
            >
              <div
                style={{
                  fontSize: 13,
                  color: isActive ? TINT : colors.white40,
                  fontFamily: fonts.display,
                  lineHeight: 1,
                }}
              >
                {t.icon}
              </div>
              <div
                style={{
                  fontSize: 8.5,
                  fontWeight: isActive ? 800 : 600,
                  color: isActive ? colors.white : colors.white40,
                  fontFamily: fonts.display,
                  textAlign: 'center',
                  letterSpacing: -0.15,
                }}
              >
                {t.label}
              </div>
            </div>
          );
        })}
      </div>
      <div
        style={{
          position: 'absolute',
          bottom: -1,
          left: `${leftPct}%`,
          width: `${widthPct}%`,
          height: 2.5,
          background: TINT,
          borderRadius: 2,
          boxShadow: `0 0 8px ${TINT}88`,
        }}
      />
    </div>
  );
};

const BankCard: React.FC<{
  balance: number;
  shine: number;
  breathing: number;
  frame: number;
  fps: number;
}> = ({ balance, shine, breathing, frame, fps }) => {
  const enter = spring({
    frame: frame - 28,
    fps,
    config: { damping: 16, stiffness: 95 },
  });

  return (
    <div
      style={{
        marginTop: 6,
        padding: 14,
        height: 148,
        borderRadius: 20,
        background: `linear-gradient(135deg, ${BANK_GRADIENT[0]} 0%, ${BANK_GRADIENT[1]} 100%)`,
        boxShadow: `0 14px 32px ${BANK_GRADIENT[0]}55, inset 0 1px 0 rgba(255,255,255,0.22)`,
        position: 'relative',
        overflow: 'hidden',
        transform: `scale(${breathing * (0.94 + enter * 0.06)})`,
        opacity: enter,
      }}
    >
      <div
        style={{
          position: 'absolute',
          top: -28,
          right: -18,
          width: 120,
          height: 120,
          borderRadius: 999,
          background: 'rgba(255,255,255,0.07)',
        }}
      />
      <div
        style={{
          position: 'absolute',
          bottom: -50,
          right: 44,
          width: 150,
          height: 150,
          borderRadius: 999,
          background: 'rgba(255,255,255,0.04)',
        }}
      />
      <div
        style={{
          position: 'absolute',
          top: 0,
          left: shine,
          width: 60,
          height: '100%',
          background:
            'linear-gradient(110deg, rgba(255,255,255,0) 0%, rgba(255,255,255,0.26) 50%, rgba(255,255,255,0) 100%)',
          transform: 'skewX(-18deg)',
        }}
      />

      <div
        style={{
          position: 'relative',
          height: '100%',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'space-between',
        }}
      >
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
          }}
        >
          <div
            style={{
              width: 32,
              height: 32,
              borderRadius: 10,
              background: 'rgba(255,255,255,0.2)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: colors.white,
              fontSize: 16,
              fontWeight: 700,
            }}
          >
            ▭
          </div>
          <div
            style={{
              color: 'rgba(255,255,255,0.65)',
              fontFamily: fonts.display,
              fontSize: 9,
              fontWeight: 700,
              letterSpacing: 1.6,
            }}
          >
            HESAPLAR
          </div>
        </div>

        <div>
          <div
            style={{
              color: 'rgba(255,255,255,0.88)',
              fontFamily: fonts.display,
              fontSize: 13,
              fontWeight: 600,
              marginBottom: 2,
            }}
          >
            Ana Banka
          </div>
          <div
            style={{
              color: colors.white,
              fontFamily: fonts.display,
              fontSize: 26,
              fontWeight: 800,
              letterSpacing: -0.8,
              lineHeight: 1.05,
            }}
          >
            ₺{fmtTRY(balance)}
          </div>
        </div>

        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 5 }}>
          {[0, 1, 2, 3].map((i) => (
            <div
              key={i}
              style={{
                width: 7,
                height: 7,
                borderRadius: 999,
                background:
                  i < 3 ? 'rgba(255,255,255,0.28)' : 'rgba(255,255,255,0.85)',
              }}
            />
          ))}
        </div>
      </div>
    </div>
  );
};

const SummaryCard: React.FC<{
  label: string;
  amount: number;
  color: string;
  isExpense: boolean;
  change: string;
  frame: number;
  fps: number;
  delay: number;
}> = ({ label, amount, color, isExpense, change, frame, fps, delay }) => {
  const enter = spring({
    frame: frame - delay,
    fps,
    config: { damping: 15, stiffness: 95 },
  });

  return (
    <div
      style={{
        flex: 1,
        padding: 10,
        background: colors.white05,
        borderRadius: 14,
        border: `1px solid ${color}22`,
        opacity: enter,
        transform: `translateY(${(1 - enter) * 16}px)`,
      }}
    >
      <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 5 }}>
        <div
          style={{
            width: 20,
            height: 20,
            borderRadius: 7,
            background: `${color}1A`,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color,
            fontSize: 12,
            fontWeight: 800,
            fontFamily: fonts.display,
          }}
        >
          {isExpense ? '↑' : '↓'}
        </div>
        <div
          style={{
            color: colors.white60,
            fontFamily: fonts.display,
            fontSize: 9.5,
            fontWeight: 600,
            flex: 1,
          }}
        >
          {label}
        </div>
      </div>
      <div
        style={{
          color: colors.white,
          fontFamily: fonts.display,
          fontSize: 16,
          fontWeight: 800,
          letterSpacing: -0.3,
        }}
      >
        ₺{fmtTRY(amount)}
      </div>
      <div
        style={{
          marginTop: 2,
          color: colors.white40,
          fontFamily: fonts.display,
          fontSize: 9,
          fontWeight: 600,
        }}
      >
        {change} geçen aya göre
      </div>
    </div>
  );
};

const AnalysisCard: React.FC<{
  pieProgress: number;
  centerPop: number;
  categories: Category[];
  total: number;
  frame: number;
  fps: number;
}> = ({ pieProgress, centerPop, categories, total, frame, fps }) => {
  const cardEnter = spring({
    frame: frame - 72,
    fps,
    config: { damping: 15, stiffness: 95 },
  });

  return (
    <div
      style={{
        marginTop: 10,
        padding: 12,
        background: colors.white05,
        border: `1px solid ${colors.white10}`,
        borderRadius: 16,
        opacity: cardEnter,
        transform: `translateY(${(1 - cardEnter) * 14}px)`,
      }}
    >
      <div style={{ display: 'flex', alignItems: 'center', gap: 7, marginBottom: 8 }}>
        <div
          style={{
            width: 3,
            height: 14,
            background: TINT,
            borderRadius: 2,
            boxShadow: `0 0 6px ${TINT}88`,
          }}
        />
        <div
          style={{
            color: colors.white,
            fontFamily: fonts.display,
            fontSize: 12,
            fontWeight: 800,
          }}
        >
          Harcama Dağılımı
        </div>
      </div>

      <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
        <DonutChart
          progress={pieProgress}
          centerPop={centerPop}
          categories={categories}
          total={total}
          size={108}
        />
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 4 }}>
          {categories.map((c, i) => {
            const legendEnter = spring({
              frame: frame - 92 - i * 5,
              fps,
              config: { damping: 14, stiffness: 100 },
            });
            return (
              <div
                key={c.label}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 7,
                  opacity: legendEnter,
                  transform: `translateX(${(1 - legendEnter) * 14}px)`,
                }}
              >
                <div
                  style={{
                    width: 8,
                    height: 8,
                    borderRadius: 999,
                    background: c.color,
                  }}
                />
                <div
                  style={{
                    color: colors.white,
                    fontFamily: fonts.display,
                    fontSize: 11,
                    fontWeight: 600,
                    flex: 1,
                  }}
                >
                  {c.label}
                </div>
                <div
                  style={{
                    color: colors.white60,
                    fontFamily: fonts.display,
                    fontSize: 11,
                    fontWeight: 700,
                  }}
                >
                  %{c.pct}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};

const DonutChart: React.FC<{
  progress: number;
  centerPop: number;
  categories: Category[];
  total: number;
  size: number;
}> = ({ progress, centerPop, categories, total, size }) => {
  const stroke = 12;
  const r = size / 2 - stroke / 2 - 2;
  const c = 2 * Math.PI * r;
  let acc = 0;

  return (
    <div style={{ position: 'relative', width: size, height: size, flexShrink: 0 }}>
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
        <circle
          cx={size / 2}
          cy={size / 2}
          r={r}
          fill="none"
          stroke={colors.white10}
          strokeWidth={stroke}
        />
        {categories.map((cat, i) => {
          const start = (acc / 100) * c;
          const sliceFull = (cat.pct / 100) * c;
          const sliceStart = acc / 100;
          const sliceEnd = (acc + cat.pct) / 100;
          const localProgress = Math.min(
            1,
            Math.max(0, (progress - sliceStart) / (sliceEnd - sliceStart || 1)),
          );
          const arcLen = sliceFull * localProgress;
          acc += cat.pct;
          return (
            <circle
              key={i}
              cx={size / 2}
              cy={size / 2}
              r={r}
              fill="none"
              stroke={cat.color}
              strokeWidth={stroke}
              strokeDasharray={`${arcLen} ${c - arcLen}`}
              strokeDashoffset={-start}
              transform={`rotate(-90 ${size / 2} ${size / 2})`}
            />
          );
        })}
      </svg>
      <div
        style={{
          position: 'absolute',
          inset: 0,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          opacity: Math.max(0, Math.min(1, centerPop)),
          transform: `scale(${0.75 + Math.min(1, centerPop) * 0.25})`,
        }}
      >
        <div
          style={{
            color: colors.white40,
            fontFamily: fonts.display,
            fontSize: 8,
            fontWeight: 700,
            letterSpacing: 0.4,
          }}
        >
          Bu Ay
        </div>
        <div
          style={{
            color: colors.white,
            fontFamily: fonts.display,
            fontSize: 12,
            fontWeight: 800,
            marginTop: 1,
          }}
        >
          ₺{fmtInt(total)}
        </div>
      </div>
    </div>
  );
};

const SectionHeader: React.FC<{ label: string }> = ({ label }) => (
  <div
    style={{
      display: 'flex',
      alignItems: 'center',
      gap: 7,
      marginTop: 10,
      marginBottom: 5,
    }}
  >
    <div
      style={{
        width: 3,
        height: 13,
        background: TINT,
        borderRadius: 2,
      }}
    />
    <div
      style={{
        color: colors.white,
        fontFamily: fonts.display,
        fontSize: 12,
        fontWeight: 800,
      }}
    >
      {label}
    </div>
  </div>
);

const TransactionRow: React.FC<{
  tx: Tx;
  rowEnter: number;
  amountEnter: number;
  scale: number;
  glow: number;
}> = ({ tx, rowEnter, amountEnter, scale, glow }) => {
  const accent = tx.isIncome ? '#10B981' : '#EF4444';
  const sign = tx.isIncome ? '+' : '−';

  return (
    <div
      style={{
        display: 'flex',
        alignItems: 'center',
        marginBottom: 5,
        background: colors.white05,
        borderRadius: 12,
        border: `1px solid ${glow > 0 ? `${accent}66` : colors.white10}`,
        opacity: Math.min(1, Math.max(0, rowEnter)),
        transform: `translateX(${(1 - rowEnter) * 28}px) scale(${scale})`,
        boxShadow: glow > 0 ? `0 0 14px ${accent}44` : 'none',
        overflow: 'hidden',
        height: 50,
      }}
    >
      <div style={{ width: 4, height: '100%', background: accent, flexShrink: 0 }} />
      <div
        style={{
          width: 30,
          height: 30,
          borderRadius: 9,
          background: `${accent}18`,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          color: accent,
          fontFamily: fonts.display,
          fontWeight: 800,
          fontSize: 14,
          marginLeft: 9,
          flexShrink: 0,
        }}
      >
        {tx.isIncome ? '↓' : '↑'}
      </div>
      <div style={{ flex: 1, marginLeft: 8, minWidth: 0 }}>
        <div
          style={{
            color: colors.white,
            fontFamily: fonts.display,
            fontSize: 12,
            fontWeight: 700,
            whiteSpace: 'nowrap',
            overflow: 'hidden',
            textOverflow: 'ellipsis',
          }}
        >
          {tx.name}
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 5, marginTop: 2 }}>
          <div
            style={{
              padding: '1px 5px',
              background: colors.white10,
              borderRadius: 5,
              color: colors.white60,
              fontFamily: fonts.display,
              fontSize: 9,
              fontWeight: 600,
            }}
          >
            {tx.cat}
          </div>
          <div
            style={{
              color: colors.white40,
              fontFamily: fonts.display,
              fontSize: 9,
            }}
          >
            {tx.date}
          </div>
        </div>
      </div>
      <div
        style={{
          padding: '0 10px',
          color: accent,
          fontFamily: fonts.display,
          fontWeight: 800,
          fontSize: 13,
          opacity: Math.min(1, Math.max(0, amountEnter)),
          transform: `translateX(${(1 - amountEnter) * 20}px)`,
          whiteSpace: 'nowrap',
        }}
      >
        {sign}₺{fmtTRY(tx.amount)}
      </div>
    </div>
  );
};

const GoalCard: React.FC<{
  progress: number;
  glow: number;
  targetPct: number;
  frame: number;
  fps: number;
}> = ({ progress, glow, targetPct, frame, fps }) => {
  const enter = spring({
    frame: frame - 140,
    fps,
    config: { damping: 15, stiffness: 95 },
  });
  const pctNow = Math.round(progress * 100);

  return (
    <div
      style={{
        marginTop: 8,
        padding: 10,
        borderRadius: 14,
        background: `${TINT}12`,
        border: `1px solid ${TINT}33`,
        opacity: enter,
        transform: `translateY(${(1 - enter) * 12}px)`,
      }}
    >
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginBottom: 7,
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
          <div
            style={{
              width: 20,
              height: 20,
              borderRadius: 7,
              background: `${TINT}33`,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: TINT,
              fontWeight: 800,
              fontSize: 11,
              fontFamily: fonts.display,
            }}
          >
            ◎
          </div>
          <div
            style={{
              color: colors.white,
              fontFamily: fonts.display,
              fontSize: 11,
              fontWeight: 700,
            }}
          >
            Tatil için biriktir
          </div>
        </div>
        <div
          style={{
            color: TINT,
            fontFamily: fonts.display,
            fontWeight: 800,
            fontSize: 12,
          }}
        >
          %{pctNow}
        </div>
      </div>

      <div
        style={{
          height: 7,
          borderRadius: 999,
          background: colors.white10,
          overflow: 'hidden',
        }}
      >
        <div
          style={{
            height: '100%',
            width: `${progress * 100}%`,
            background: `linear-gradient(90deg, ${TINT} 0%, #34D399 100%)`,
            borderRadius: 999,
            boxShadow: `0 0 ${6 + glow * 12}px ${TINT}99`,
          }}
        />
      </div>

      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          marginTop: 5,
        }}
      >
        <div
          style={{
            color: colors.white60,
            fontFamily: fonts.display,
            fontSize: 9,
            fontWeight: 600,
          }}
        >
          ₺{fmtInt(36000)} / ₺{fmtInt(50000)}
        </div>
        <div
          style={{
            color: colors.white40,
            fontFamily: fonts.display,
            fontSize: 9,
            fontWeight: 600,
          }}
        >
          {pctNow >= targetPct ? 'Hedefe yakın' : '14 gün kaldı'}
        </div>
      </div>
    </div>
  );
};
