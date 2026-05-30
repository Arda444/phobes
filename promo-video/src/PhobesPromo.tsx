import React from 'react';
import { Series, AbsoluteFill } from 'remotion';
import { loadFont } from '@remotion/google-fonts/Outfit';
import { HookScene } from './scenes/HookScene';
import { StatisticsScene } from './scenes/StatisticsScene';
import { BudgetScene } from './scenes/BudgetScene';
import { CalendarScene } from './scenes/CalendarScene';
import { NotesScene } from './scenes/NotesScene';
import { BooksScene } from './scenes/BooksScene';
import { TasksScene } from './scenes/TasksScene';
import { HabitsScene } from './scenes/HabitsScene';
import { MedicationScene } from './scenes/MedicationScene';
import { AppointmentsScene } from './scenes/AppointmentsScene';
import { TeamsScene } from './scenes/TeamsScene';
import { NovaScene } from './scenes/NovaScene';
import { MultiDeviceScene } from './scenes/MultiDeviceScene';
import { ThemesScene } from './scenes/ThemesScene';
import { CTAScene } from './scenes/CTAScene';
import { colors } from './theme';

loadFont('normal', { weights: ['400', '500', '600', '700', '800', '900'] });

/**
 * ~60 sn dikey promo. Önemli modüller başta; istatistik en uzun sahne.
 * Toplam: 2000 kare @ 30fps ≈ 66.7 sn
 */
export const SCENES = [
  { id: 'hook', duration: 50, Component: HookScene },
  { id: 'statistics', duration: 270, Component: StatisticsScene },
  { id: 'budget', duration: 210, Component: BudgetScene },
  { id: 'calendar', duration: 210, Component: CalendarScene },
  { id: 'notes', duration: 210, Component: NotesScene },
  { id: 'books', duration: 90, Component: BooksScene },
  { id: 'tasks', duration: 120, Component: TasksScene },
  { id: 'habits', duration: 90, Component: HabitsScene },
  { id: 'medication', duration: 90, Component: MedicationScene },
  { id: 'appointments', duration: 90, Component: AppointmentsScene },
  { id: 'teams', duration: 90, Component: TeamsScene },
  { id: 'nova', duration: 180, Component: NovaScene },
  { id: 'multiDevice', duration: 120, Component: MultiDeviceScene },
  { id: 'themes', duration: 90, Component: ThemesScene },
  { id: 'cta', duration: 90, Component: CTAScene },
] as const;

export const TOTAL_DURATION = SCENES.reduce((acc, s) => acc + s.duration, 0);

export const PhobesPromo: React.FC = () => {
  return (
    <AbsoluteFill style={{ background: colors.bg, fontFamily: 'Outfit' }}>
      <Series>
        {SCENES.map((s) => (
          <Series.Sequence key={s.id} durationInFrames={s.duration}>
            <s.Component />
          </Series.Sequence>
        ))}
      </Series>
    </AbsoluteFill>
  );
};
