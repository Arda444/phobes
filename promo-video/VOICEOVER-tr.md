# Phobes Promo — Türkçe seslendirme metni

**Toplam süre:** ~67 saniye (videoyla birebir)  
**Tempo:** Enerjik, net, Reels/TikTok tonu — saniyede ~2,3 kelime  
**Önerilen ses:** ElevenLabs Multilingual v2 — genç, sıcak, güven veren (ör. `Chris` / `Charlotte` TR veya Voice Design)

---

## Zaman kodlu metin (ana versiyon)

Videodaki sahne sırasıyla oku. Köşeli parantez = ekranda görünen slogan; okumak zorunda değilsin, ritim için referans.

| Zaman | Sahne | Metin |
|-------|--------|--------|
| **0:00–0:02** | Hook | **Phobes.** Hayatın, tek uygulamada. |
| **0:02–0:11** | İstatistikler | Rakamlar yalan söylemez. Görevlerinden bütçene, alışkanlıklarından randevularına — hepsinin özeti tek ekranda. Dönem seç, modül modül gör, raporunu PDF veya Excel olarak al. |
| **0:11–0:18** | Bütçe | Cebinde netlik. Gelir, gider, hesaplar, borçlar ve hedefler — hepsi bir arada. |
| **0:18–0:25** | Takvim | Günün tek planı. Görev, randevu, ilaç, alışkanlık… Tek takvimde, tek bakışta. |
| **0:25–0:32** | Notlar | Düşüncelerin yaşıyor. Zengin metin, çoklu sayfa, gömülü kartlar — notların gerçekten not gibi. |
| **0:32–0:35** | Kitaplar | Okudukların hikayen. Kütüphaneni kur, hedef koy, alıntılarını sakla. |
| **0:35–0:39** | Görevler | Tikle. Kazan. İlerle. XP kazan, öncelik belirle, tekrarlı görevlerle düzeni yakala. |
| **0:39–0:42** | Alışkanlıklar | Zinciri kırma. Her gün bir adım, streak’inle motive ol. |
| **0:42–0:45** | İlaç | Doğru doz, doğru saat. Stok azalınca seni uyarır. |
| **0:45–0:48** | Randevu | Randevun, işin kolay. Müşterilerin online rezervasyon yapsın, sen timeline’dan yönet. |
| **0:48–0:51** | Takım | Birlikte daha güçlü. Kanban, davet kodu, anlık aktivite — ekip işi tek yerde. |
| **0:51–0:57** | Nova AI | Sana özel asistan. Bugün ne yapman gerektiğini sor; bağlamını bilen Nova sana yol göstersin. |
| **0:57–1:01** | Çoklu cihaz | Mobilde, tablette, webde — her yerde. |
| **1:01–1:04** | Tema & dil | Açık tema, koyu tema, AMOLED… Türkçe veya İngilizce. Senin tarzına uygun. |
| **1:04–1:07** | CTA | Hemen keşfet. **www.phobes.com.tr** |

---

## Tek parça (kopyala-yapıştır — ElevenLabs / kayıt)

```
Phobes. Hayatın, tek uygulamada.

Rakamlar yalan söylemez. Görevlerinden bütçene, alışkanlıklarından randevularına — hepsinin özeti tek ekranda. Dönem seç, modül modül gör, raporunu PDF veya Excel olarak al.

Cebinde netlik. Gelir, gider, hesaplar, borçlar ve hedefler — hepsi bir arada.

Günün tek planı. Görev, randevu, ilaç, alışkanlık… Tek takvimde, tek bakışta.

Düşüncelerin yaşıyor. Zengin metin, çoklu sayfa, gömülü kartlar — notların gerçekten not gibi.

Okudukların hikayen. Kütüphaneni kur, hedef koy, alıntılarını sakla.

Tikle. Kazan. İlerle. XP kazan, öncelik belirle, tekrarlı görevlerle düzeni yakala.

Zinciri kırma. Her gün bir adım, streak’inle motive ol.

Doğru doz, doğru saat. Stok azalınca seni uyarır.

Randevun, işin kolay. Müşterilerin online rezervasyon yapsın, sen timeline’dan yönet.

Birlikte daha güçlü. Kanban, davet kodu, anlık aktivite — ekip işi tek yerde.

Sana özel asistan. Bugün ne yapman gerektiğini sor; bağlamını bilen Nova sana yol göstersin.

Mobilde, tablette, webde — her yerde.

Açık tema, koyu tema, AMOLED… Türkçe veya İngilizce. Senin tarzına uygun.

Hemen keşfet. www nokta phobes nokta com nokta tr.
```

**Kelime sayısı:** ~165 kelime → ~67 sn (normal promo temposu)

---

## Kısa versiyon (~45 sn — müzik daha baskınsa)

```
Phobes — hayatın tek uygulamada.

Tüm modüllerin özeti tek ekranda: istatistik, bütçe, takvim, notlar, kitaplar.

Görevlerle XP kazan. Alışkanlık zincirini kırma. İlacını kaçırma. Randevunu yönet. Ekibinle üret.

Nova sor, cevabı al. Mobilde, tablette, webde.

Hemen keşfet: phobes.com.tr
```

---

## ElevenLabs ayarları (öneri)

| Ayar | Değer |
|------|--------|
| Model | Multilingual v2 |
| Dil | Turkish |
| Stability | 0,45–0,55 |
| Similarity | 0,75 |
| Style exaggeration | 0,35–0,45 (fazla abartma) |
| Hız | 1,0–1,05x |

**Prompt (Voice Design için):**  
*“Genç Türk erkek/ kadın, sıcak ve güvenilir startup sesi, hızlı ama anlaşılır, Reels tanıtım videosu, hafif gülümseme tonu, net telaffuz.”*

---

## Remotion’a ekleme

`public/voiceover.mp3` dosyasını koy, sonra `PhobesPromo.tsx` içinde:

```tsx
import { Audio, staticFile } from 'remotion';

// Series içinde, en üstte:
<Audio src={staticFile('voiceover.mp3')} volume={1} />
<Audio src={staticFile('music.mp3')} volume={0.22} />
```

Müzik voiceover’ın altında kalsın; CTA’da müziği biraz yükseltmek istersen `volume` frame’e göre interpolate edilebilir.

---

## Telaffuz notları

- **Phobes** → “Fo-bes” (İngilizce okunuş, net ve kısa)
- **Nova** → “No-va”
- **www.phobes.com.tr** → son CTA’da yavaş ve vurgulu: “ve ve ve nokta phobes nokta com nokta tr”
- **XP, PDF, Excel, AMOLED** → kısaltmaları harf harf veya Türkçe karşılıkla (isteğe bağlı “eks pi”)
