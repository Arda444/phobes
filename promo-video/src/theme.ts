// Phobes marka renkleri — lib/core/phobes_theme.dart ile birebir aynı.
export const colors = {
  primary: '#8B5CF6',
  secondary: '#10B981',
  accent: '#F472B6',
  tertiary: '#06B6D4',
  warning: '#F59E0B',
  error: '#EF4444',
  info: '#3B82F6',
  success: '#10B981',

  bg: '#050505',
  surface: '#121212',
  surfaceLight: '#1E1E1E',
  surfaceVariant: '#2A2A2A',

  white: '#FFFFFF',
  white80: 'rgba(255,255,255,0.80)',
  white60: 'rgba(255,255,255,0.60)',
  white40: 'rgba(255,255,255,0.40)',
  white20: 'rgba(255,255,255,0.20)',
  white10: 'rgba(255,255,255,0.10)',
  white05: 'rgba(255,255,255,0.05)',

  black: '#000000',
  black50: 'rgba(0,0,0,0.50)',
} as const;

export const fonts = {
  display: '"Outfit", system-ui, -apple-system, BlinkMacSystemFont, sans-serif',
  body: '"Outfit", system-ui, -apple-system, BlinkMacSystemFont, sans-serif',
  mono: '"JetBrains Mono", ui-monospace, SFMono-Regular, monospace',
} as const;

// lib/core/stats_module_palette.dart — istatistik ekranı modül renkleri
export const statsModuleColors = {
  tasks: '#3B82F6',
  habits: '#22C55E',
  budget: '#F59E0B',
  notes: '#6366F1',
  appointments: '#06B6D4',
  medications: '#EC4899',
  books: '#8B5CF6',
  teams: '#14B8A6',
  corkboard: '#A16207',
} as const;

// Modül başına ana renk teması (kartlara hayat veriyor)
export const moduleThemes = {
  statistics: {
    color: colors.primary,
    gradient: [colors.primary, '#6366F1'],
    emoji: '◈',
  },
  tasks: { color: statsModuleColors.tasks, gradient: [statsModuleColors.tasks, '#1D4ED8'], emoji: '✓' },
  notes: { color: statsModuleColors.notes, gradient: [statsModuleColors.notes, '#4F46E5'], emoji: '✎' },
  calendar: { color: colors.info, gradient: [colors.info, '#1D4ED8'], emoji: '☷' },
  budget: { color: statsModuleColors.budget, gradient: [statsModuleColors.budget, '#D97706'], emoji: '₺' },
  habits: { color: statsModuleColors.habits, gradient: [statsModuleColors.habits, '#15803D'], emoji: '🔥' },
  medication: { color: statsModuleColors.medications, gradient: [statsModuleColors.medications, '#BE185D'], emoji: '◉' },
  appointments: { color: statsModuleColors.appointments, gradient: [statsModuleColors.appointments, '#0E7490'], emoji: '◷' },
  teams: { color: statsModuleColors.teams, gradient: [statsModuleColors.teams, '#0F766E'], emoji: '◍' },
  books: { color: statsModuleColors.books, gradient: [statsModuleColors.books, '#6D28D9'], emoji: '📖' },
  nova: { color: colors.primary, gradient: [colors.primary, colors.tertiary], emoji: '✦' },
} as const;
