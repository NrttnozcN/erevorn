# Erevorn (Godot 4)

Eski HTML5 Erevorn'un Godot 4.7'ye taşınmış hali. Oynanış, sayılar, arayüz düzeni, sprite'lar ve sesler
eski oyundan birebir alındı. Hikaye kaynağı: Erevorn Lore Bible (Claude Doc).
Eski sürüm `../Erevorn` klasöründe duruyor ve dokunulmadı.

## Oyna

- **Tarayıcıda:** https://nrttnozcn.github.io/erevorn/ (Chrome ya da Edge önerilir; ilk açılış biraz sürebilir)
- **İndir:** [Son sürüm](https://github.com/NrttnozcN/erevorn/releases/tag/son-surum) — Windows için `Erevorn-Windows.zip`,
  Mac için `Erevorn-Mac.zip` (imzasız uygulama: Erevorn'a sağ tık → Aç).

## Çalıştırma (geliştirme)

Godot'da `project.godot` dosyasını aç ve F5'e bas.

| Tuş | İş |
|---|---|
| WASD / oklar | Hareket |
| Sol tık (basılı tut) | Temel saldırı (fareye doğru) |
| Boşluk | Atılma (kısa süre hasar almaz) |
| Q / R | Dövüş tarzının tek hedef / alan yeteneği |
| E | Sandık, sunak, tutsak, satıcı, portal; konuşmayı ilerletir (konuşma yalnızca E ile geçer) |
| F | Üçüncü yetenek (ilk bossu yenince açılır) |
| T | Gök Börü yeteneği (üçüncü bossu yenince açılır) |
| I veya B | Çanta |
| Esc | Duraklat / pencereyi kapat |

Dokunmatik ekranda joystick ve SALDIRI / Q / R / F / T / E / ATIL düğmeleri çıkar.

## Dövüş tarzları

Kahraman her zaman Arktan. Eski oyundaki üç sınıf onun dövüş tarzı oldu:

- **Savaşçı:** ağır kılıç savuruşu, %20 altındaki düşmanı infaz eder. Q Kırıcı Savurma, R Gök Kılıcı.
- **Okçu:** hızlı ok. Q Delici Ok (4 düşmanı deler, işaretler), R Ok Yağmuru.
- **Büyücü:** rün mermisi. Q Ateş Topu, R Meteor.

## Yapı

```
scripts/main.gd                  oyun yöneticisi (eski GameEngine): kat kurulumu, etkileşim, ölüm, kamera
scripts/autoload/game.gd         koşu durumu, görev, başarımlar, ruh taşları, tuşlar, kayıt
scripts/autoload/sprites.gd      eski SpriteEngine çizimleri + nefes / yürüme / saldırı hareketleri
scripts/autoload/sfx.gd          ses efektleri ve müzik
scripts/data/                    düşman, eşya, sınıf, kart tabloları (eski koddaki sayılar)
scripts/world/                   zindan haritası, ışık shader'ı, konuşma sistemi, efektler
scripts/entities/                Arktan, düşman, boss, mermi, gök saldırıları, sandık, portal, satıcı...
scripts/ui/                      HUD, mini harita, pencereler (çanta, dükkan, demirci...), dokunmatik kontroller
data/dialogue.json               eski oyunun tüm konuşmaları (yeni kanona göre yeniden yazılacak)
assets/sprites/                  eski oyundan dışa aktarılmış 130 kare
assets/sounds/                   eski oyunun sesleri
```

## Testler

```
godot --headless --path . res://tests/smoke_test.tscn      # 3 tarz: saldırı, yetenek, portal, boss fazları, dükkan, çanta, ölüm
godot --headless --path . res://tests/autoplay_test.tscn   # 3 tarz otomatik oynayarak birkaç kat iner
```

## Eskisinden farklı olanlar

Oynanış aynı tutuldu; yalnızca açık hatalar düzeltildi:

- Oyun hızı ekran yenileme hızından bağımsız (60 Hz sabit fizik karesi).
- Konuşmalar artık harf harf yazılıyor ve okunacak kadar ekranda kalıyor (eskisinde anında kayboluyordu).
- Savaşçının infazı bosslara işlemiyor; 100. katta Kârun ölmeden portal açılmıyor.
- Ok kritik vuruşu iki kez hesaplanmıyor; parçalamadan gelen can kalıcı Maks Can'a ekleniyor.
- "erevorn" hile kodu yok.
- Boss öldürünce düşen efsanevi silah, oynadığın dövüş tarzına uygun.
