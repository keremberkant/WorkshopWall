<p align="center">
  <img src="docs/icon.png" width="160" alt="Canlı Duvar simgesi">
</p>

<h1 align="center">Canlı Duvar</h1>

<p align="center">
  <b>macOS için canlı duvar kağıtları.</b> Wallpaper Engine'in <i>video</i> ve <i>web</i> duvar kağıtlarını Mac masaüstünüzde oynatır — Apple Silicon ve Intel'de yerel olarak.
  <br><br>
  <a href="README.md">English</a> ·
  <a href="#kurulum">Kurulum</a> ·
  <a href="#kullanım">Kullanım</a> ·
  <a href="#kaynaktan-derleme">Derleme</a>
</p>

---

*Canlı Duvar*, hareketli duvar kağıtlarını masaüstü simgelerinizin arkasında oynatan küçük ve açık kaynaklı bir macOS uygulamasıdır. Wallpaper Engine projelerini doğrudan okur; böylece Windows'ta sahip olduğunuz duvar kağıtları Mac'inizde de oynar. Steam Atölye'den yeni duvar kağıdı da indirebilir.

> Canlı Duvar bağımsız bir projedir. Wallpaper Engine, Kristjan Skutta veya Valve ile **bir bağlantısı yoktur**. Hiçbir duvar kağıdı içermez ve dağıtmaz.

## Özellikler

- 🎬 **Video duvar kağıtları** (MP4 / MOV / M4V), donanım çözücüyle — genelde %0–3 işlemci
- 🌐 **Web duvar kağıtları** (HTML / WebGL), Wallpaper Engine'in `wallpaperPropertyListener` arayüzü ve varsayılan ayarlarıyla
- 🖼 **Resim ve GIF**
- 🖥 **Tüm ekranlarda ve tüm masaüstlerinde (Spaces)**, simgelerin arkasında; tıklamaları engellemez
- ⏭ **Anında geçiş** — her yerde çalışan kısayollar, önceki / sonraki / rastgele, Dock menüsü, menü çubuğu, kütüphanede tek tık
- 📥 **Steam Atölye'den indirme**, Valve'ın resmi SteamCMD aracıyla — şifreniz uygulamaya hiç girmez
- 🔋 **Pil dostu** — ekran uyuyunca, pildeyken, Düşük Güç Modunda veya tam ekran / büyütülmüş bir pencere masaüstünü kapatınca kendiliğinden duraklar (her biri ayarlanabilir)
- 💾 **Kütüphane her yerde olabilir** — gigabaytlarca duvar kağıdını harici diskte tutun
- 🌍 İngilizce ve Türkçe, universal uygulama, ~4 MB, bağımlılık yok

### Neler oynar, neler oynamaz

| Wallpaper Engine türü | macOS | Not |
|---|---|---|
| Video | ✅ | MP4 / MOV / M4V. WebM'i macOS desteklemez. |
| Web | ✅ | Ses görselleştiriciler açılır ama sistem sesine tepki vermez. |
| Resim / GIF | ✅ | |
| Scene | ❌ | Wallpaper Engine'e özel, DirectX tabanlı kapalı bir biçim. Basit sahneler elle web duvar kağıdına çevrilebilir ([docs/converting-scenes.md](docs/converting-scenes.md)). |
| Uygulama | ❌ | Windows programları. |

## Kurulum

1. [Son sürümden](../../releases/latest) `CanliDuvar-x.y.z.zip` dosyasını indirip açın.
2. **Canlı Duvar.app**'i **Uygulamalar** klasörüne taşıyın.
3. Uygulama Apple tarafından onaylanmadığı (ücretli geliştirici hesabı yok) için ilk açılışta **sağ tık → Aç → Aç** deyin.
   macOS "hasarlı" derse Terminal'de şunu çalıştırın:
   ```bash
   xattr -dr com.apple.quarantine "/Applications/Canlı Duvar.app"
   ```

**macOS 14 Sonoma** veya üstü gerekir.

## Kullanım

- **Duvar kağıdı ekleme:** dosya veya klasörleri pencereye sürükleyin ya da **Dosya Ekle…**'ye tıklayın.
  Tek bir Wallpaper Engine projesini ya da Atölye klasörünün tamamını
  (`…/steamapps/workshop/content/431960`) seçip hepsini birden ekleyebilirsiniz.
- **Uygulama:** karta bir kez tıklayın.
- **Geçiş:**

  | Kısayol | İşlem |
  |---|---|
  | <kbd>⌃⌥⌘→</kbd> | Sonraki duvar kağıdı (her uygulamada) |
  | <kbd>⌃⌥⌘←</kbd> | Önceki duvar kağıdı (her uygulamada) |
  | <kbd>⌃⌥⌘↓</kbd> | Duraklat / devam et (her uygulamada) |
  | <kbd>⌘→</kbd> / <kbd>⌘←</kbd> | Sonraki / önceki (uygulama içinde) |
  | <kbd>⌥⌘R</kbd> | Rastgele duvar kağıdı |

  Dock simgesine sağ tıklayınca tüm duvar kağıtlarının listesi açılır.
- Pencereyi kapatmak duvar kağıdını durdurmaz. Çıkmak için menü çubuğu simgesini veya uygulama menüsünü kullanın.
- **Ayarlar** (<kbd>⌘,</kbd>): ses, duraklatma kuralları, oturum açılınca başlatma, menü çubuğu simgesi, kütüphane klasörü
  ve isteğe bağlı olarak önizlemeyi sabit masaüstü resmi yapma (kilit ekranı / Mission Control).

### Steam Atölye'den indirme

Wallpaper Engine'e sahip bir Steam hesabı gerekir.

1. **Atölyeden İndir…** → SteamCMD'yi **Kur** (≈80 MB, kütüphanenin yanına kurulur).
2. Steam kullanıcı adınızı yazın → **Steam'e Giriş Yap…**. Açılan Terminal penceresinde şifrenizi ve Steam Guard kodunuzu **doğrudan SteamCMD'ye** girersiniz. Bu yalnızca bir kez gerekir; SteamCMD oturumu hatırlar.
3. Bir veya daha fazla Atölye linkini yapıştırın → **İndir ve Ekle**.

İpucu: Atölye'yi *Type: Video* veya *Web* ile filtreleyin. Scene öğeleri oynatılamadığı için indirildikten sonra silinir.

## Gizlilik ve güvenlik

- Analitik yok, uygulama kendi başına internete bağlanmaz. Ağ erişimi yalnızca SteamCMD'yi kurarken (Valve'ın sunucusundan) ve Atölye öğesi indirirken (SteamCMD üzerinden) olur.
- Steam şifreniz yalnızca Terminal'de, Valve'ın SteamCMD aracına girilir. Canlı Duvar şifrenizi görmez ve saklamaz.
- Web duvar kağıtları WebKit'in korumalı web içeriği sürecinde çalışır ve yalnızca kendi klasörlerindeki dosyaları okuyabilir (test edildi: ev klasörünüzdeki başka dosyalar okunamıyor). Wallpaper Engine'de olduğu gibi web duvar kağıtları internete erişebilir — yalnızca güvendiğiniz duvar kağıtlarını ekleyin.
- Genel kısayollar Carbon kısayol arayüzünü kullanır; Erişilebilirlik izni gerekmez.

## Kaynaktan derleme

Gereksinim: macOS 14+ üzerinde Xcode 15+ (Swift 5.9+).

```bash
git clone https://github.com/keremberkant/CanliDuvar.git
cd CanliDuvar
swift test                         # birim testleri
scripts/build-app.sh               # → dist/Canlı Duvar.app (universal)
scripts/build-app.sh --install     # derle ve /Applications'a kopyala
VERSION=1.2.0 scripts/build-app.sh --zip   # sürüm zip'i + SHA-256
```

Dilerseniz `Package.swift` dosyasını Xcode'da açıp `CanliDuvar` şemasını çalıştırabilirsiniz.

Proje yapısı ve teknik ayrıntılar için [İngilizce README](README.md#project-layout)'ye bakın.

## Katkı

Hata bildirimleri ve pull request'ler memnuniyetle karşılanır — [CONTRIBUTING.md](CONTRIBUTING.md). Özellikle çeviriler: İngilizce metinleri anahtar olarak kullanan bir `Resources/<dil>.lproj/Localizable.strings` dosyası ekleyin.

## Lisans

[MIT](LICENSE). Wallpaper Engine ilgili sahiplerinin ticari markasıdır; Steam ve SteamCMD, Valve Corporation'ın ticari markalarıdır.
