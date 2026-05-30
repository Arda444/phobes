import type { SceneTransition } from './components/SceneFrame';

/** Modül başlığı = şarp slogan; alt başlık = kısa destek cümlesi */
export const moduleSlogans = {
  statistics: {
    title: 'Rakamlar yalan söylemez.',
    subtitle: 'Tüm modüller · tek özet ekran',
    transition: 'zoomBlur' as SceneTransition,
  },
  budget: {
    title: 'Cebinde netlik.',
    subtitle: 'Hesap, borç, hedef — tek bakışta',
    transition: 'slideRight' as SceneTransition,
  },
  calendar: {
    title: 'Günün tek planı.',
    subtitle: 'Görev, randevu, ilaç — hepsi burada',
    transition: 'slideLeft' as SceneTransition,
  },
  notes: {
    title: 'Düşüncelerin yaşıyor.',
    subtitle: 'Zengin metin · çoklu sayfa · embed',
    transition: 'flipIn' as SceneTransition,
  },
  books: {
    title: 'Okudukların hikayen.',
    subtitle: 'Kütüphane · alıntılar · okuma hedefi',
    transition: 'slideUp' as SceneTransition,
  },
  tasks: {
    title: 'Tikle. Kazan. İlerle.',
    subtitle: 'XP, öncelik, tekrarlı görevler',
    transition: 'slideRight' as SceneTransition,
  },
  habits: {
    title: 'Zinciri kırma.',
    subtitle: 'Streak · heatmap · hatırlatma',
    transition: 'fadeScale' as SceneTransition,
  },
  medication: {
    title: 'Doğru doz, doğru saat.',
    subtitle: 'Stok takibi · günlük plan',
    transition: 'slideLeft' as SceneTransition,
  },
  appointments: {
    title: 'Randevun, işin kolay.',
    subtitle: 'Timeline · online rezervasyon',
    transition: 'zoomBlur' as SceneTransition,
  },
  teams: {
    title: 'Birlikte daha güçlü.',
    subtitle: 'Kanban · davet kodu · aktivite',
    transition: 'slideUp' as SceneTransition,
  },
  nova: {
    title: 'Sana özel asistan.',
    subtitle: 'Bağlamı bilen · eylem üreten AI',
    transition: 'flipIn' as SceneTransition,
  },
} as const;
