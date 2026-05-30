# Phobes Promo Video

Phobes için tamamen kodla yazılmış, **dikey (1080×1920, 9:16)** tanıtım videosu. Instagram Reels, TikTok, YouTube Shorts ve Play Store / App Store önizleme için uygundur.

## Senaryo

Her modül için kendi rengi, kendi mockup'ı ve kendi animasyonu olan kart sahneleri:

| # | Sahne | Süre | Modül rengi |
|---|---|---|---|
| # | Sahne | Süre | Not |
|---|---|---|---|
| 1 | **Hook** — gerçek logo (`public/logo.png`) + modül orbit | 1.7 sn | |
| 2 | **İstatistikler** — en detaylı sahne (dönem, modül skorları, grafikler) | **9 sn** | Başta |
| 3 | **Bütçe** | 7 sn | Başta |
| 4 | **Takvim** | 7 sn | Başta |
| 5 | **Notlar** | 7 sn | Başta |
| 6 | Görevler | 4 sn | |
| 7–10 | Alışkanlık, İlaç, Randevu, Takım | 3 sn each | |
| 11 | Nova AI | 6 sn | |
| 12 | **Çoklu cihaz** — tablet + laptop + telefon | 4 sn | |
| 13 | Tema & Dil | 3 sn | |
| 14 | CTA — www.phobes.com.tr | 3 sn | |

**Toplam: ~64 sn, 1910 kare, 30 fps.**

Modül renkleri `lib/core/stats_module_palette.dart` ile uyumlu (`promo-video/src/theme.ts` → `statsModuleColors`).

## Kurulum

```bash
cd promo-video
npm install
```

## Çalıştırma

### Studio (canlı önizleme — geliştirme için)

```bash
npm run dev
```

Tarayıcıda `http://localhost:3000` açılır. Sol panelden `PhobesPromo` (tam video) veya tek tek sahneleri (`scene-tasks`, `scene-budget`, vs.) seçerek önizleme yapabilirsin. Sahne hızlıca düzenlenip kayıt yapılınca anında yenilenir.

### Tam video render (MP4)

```bash
npm run build
```

Çıktı: `out/phobes-promo.mp4` — H.264, yuv420p, CRF 18 (Reels/TikTok için yüksek kalite).

### Diğer formatlar

```bash
npm run build:webm    # WebM (VP9) — web siteleri için
npm run build:gif     # GIF — küçük teaser
npm run still         # Tek frame PNG — kapak görseli için
```

### Tek bir sahneyi ayrı render etmek

```bash
npx remotion render src/index.ts scene-tasks out/tasks.mp4
npx remotion render src/index.ts scene-budget out/budget.mp4
```

## Dosya yapısı

```
promo-video/
  package.json
  tsconfig.json
  remotion.config.ts
  src/
    index.ts                  ← Remotion entry
    Root.tsx                  ← Composition kayıtları
    PhobesPromo.tsx           ← Sahne sırası + toplam süre
    theme.ts                  ← Phobes marka renkleri (lib/core/phobes_theme.dart ile aynı)
    components/
      AnimatedBackground.tsx  ← Aurora gradient + grain
      PhoneFrame.tsx          ← iPhone mockup
      LaptopFrame.tsx         ← Macbook + tarayıcı mockup'ı
      Card.tsx                ← Glassmorphism kart
      SceneFrame.tsx          ← Her modül sahnesinin ortak iskeleti
    scenes/
      HookScene.tsx           ← Açılış
      TasksScene.tsx
      NotesScene.tsx
      CalendarScene.tsx
      BudgetScene.tsx
      HabitsScene.tsx
      MedicationScene.tsx
      AppointmentsScene.tsx
      TeamsScene.tsx
      NovaScene.tsx
      MultiDeviceScene.tsx    ← Mobil + Web yan yana
      ThemesScene.tsx         ← Light / Dark / AMOLED + TR/EN toggle
      CTAScene.tsx            ← Kapanış (www.phobes.com.tr)
```

## Özelleştirme ipuçları

- **Süreyi değiştir:** `src/PhobesPromo.tsx` dosyasındaki `SCENES` dizisinde her sahnenin `duration` değerini değiştir.
- **Renkleri değiştir:** `src/theme.ts` — Phobes uygulamasındaki `phobes_theme.dart` ile birebir aynı tutulmuştur.
- **Sahne ekle/çıkar:** Yeni bir sahne yaz (`scenes/MyScene.tsx`), `PhobesPromo.tsx` ve `Root.tsx`'e ekle.
- **Voiceover / müzik ekle:** `public/` klasörüne `voice.mp3` ve `music.mp3` koy, `PhobesPromo.tsx`'in en başına ekle:
  ```tsx
  import { Audio, staticFile } from 'remotion';
  <Audio src={staticFile('voice.mp3')} />
  <Audio src={staticFile('music.mp3')} volume={0.25} />
  ```
- **Gerçek ekran görüntüleri kullan:** Mockup içeriklerini `<Img src={staticFile('screens/tasks.png')} />` ile gerçek Phobes PNG'leriyle değiştir.
- **Yatay versiyon (16:9):** `src/Root.tsx`'te `width: 1920, height: 1080` yap.

## Render performansı

Tüm video 1080×1920'de paralel olarak ~3-7 dk içinde render olur (CPU'ya göre). Hızlandırmak için:

```bash
npx remotion render src/index.ts PhobesPromo out/promo.mp4 --concurrency=8
```

## Sosyal medyaya yükleme

- **Instagram Reels / TikTok:** Doğrudan `out/phobes-promo.mp4` yüklenebilir.
- **YouTube Shorts:** 60 sn altı olduğu için otomatik Short olarak işaretlenir.
- **App Store / Play Store:** İlk 1 saniye uygulamayı göstermeli — `HookScene` süresini azaltıp `TasksScene`'i öne al.
