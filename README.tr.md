<p align="center">
  <img src="docs/icon.png" width="128" alt="WorkshopWall simgesi">
</p>

<h1 align="center">WorkshopWall</h1>

<p align="center">
  <b>Steam Atölye duvar kağıtları artık Mac'te.</b><br>
  Wallpaper Engine'in <i>video</i> ve <i>web</i> duvar kağıtlarını masaüstü simgelerinizin arkasında oynatır — Apple Silicon ve Intel'de yerel olarak.
</p>

<p align="center">
  <a href="https://github.com/keremberkant/WorkshopWall/releases/latest"><img src="https://img.shields.io/github/v/release/keremberkant/WorkshopWall?label=indir&color=7c3aed" alt="Son sürüm"></a>
  <a href="https://github.com/keremberkant/WorkshopWall/actions/workflows/ci.yml"><img src="https://github.com/keremberkant/WorkshopWall/actions/workflows/ci.yml/badge.svg" alt="CI durumu"></a>
  <img src="https://img.shields.io/badge/macOS-14%2B-0a84ff?logo=apple&logoColor=white" alt="macOS 14 veya üstü">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/keremberkant/WorkshopWall?color=22c55e" alt="MIT lisansı"></a>
</p>

<p align="center">
  <a href="README.md">English</a> ·
  <a href="#kurulum">Kurulum</a> ·
  <a href="#kullanım">Kullanım</a> ·
  <a href="#örnek-duvar-kağıtları">Örnekler</a> ·
  <a href="#kaynaktan-derleme">Derleme</a>
</p>

<p align="center">
  <img src="docs/screenshots/hero.png" width="900" alt="Hareketli Aurora duvar kağıdının üzerinde WorkshopWall kütüphane penceresi">
</p>

**WorkshopWall**, Steam Atölye'nin canlı duvar kağıtlarını Mac'inize getiren küçük ve açık kaynaklı bir macOS uygulamasıdır. Duvar kağıtlarını doğrudan Atölye'den indirir, Wallpaper Engine projelerini doğrudan okur (Windows'ta sahip olduklarınız da oynar) ve hepsini masaüstü simgelerinizin arkasında oynatır. Swift, SwiftUI ve AppKit ile yazıldı; bağımlılığı yok, boyutu yaklaşık 4 MB.

> [!NOTE]
> WorkshopWall bağımsız bir projedir. Wallpaper Engine, Kristjan Skutta veya Valve ile **bir bağlantısı yoktur**. Atölye içeriği içermez ve dağıtmaz.

## Özellikler

| Özellik | |
|---|---|
| 📥 **Steam Atölye** | Atölye linklerini yapıştırın, Valve'ın resmi SteamCMD aracıyla indirin. Şifreniz uygulamaya hiç girmez. |
| 🎬 **Video duvar kağıtları** | MP4 / MOV / M4V, donanım çözücüyle. Tüm ekranlar tek çözücüyü paylaşır; işlemci kullanımı genelde %0–3. |
| 🌐 **Web duvar kağıtları** | HTML / WebGL; Wallpaper Engine'in `wallpaperPropertyListener` arayüzü ve projenin varsayılan ayarlarıyla. |
| 🖼 **Resim ve GIF** | Sabit ve hareketli resimler, her ekranı dolduracak şekilde. |
| 🖥 **Her ekran, her masaüstü** | Simgelerin arkasında durur; tıklamalar doğrudan masaüstüne geçer. |
| ⏭ **Anında geçiş** | Her yerde çalışan kısayollar, önceki / sonraki / rastgele, Dock menüsü, menü çubuğu veya kütüphanede tek tık. |
| 🔋 **Pil dostu** | Ekran uyuyunca, pildeyken, Düşük Güç Modunda veya tam ekran / büyütülmüş bir pencere masaüstünü kapatınca duraklar. Her kural kapatılabilir. |
| 💾 **Kütüphane her yerde olabilir** | Gigabaytlarca duvar kağıdını harici diskte tutun. Klasörleri sürükleyip bırakın ya da Atölye klasörünü tek seferde ekleyin. |
| 🌍 **Çok dilli** | İngilizce ve Türkçe. Yeni çevirilere açık. |

<p align="center">
  <img src="docs/screenshots/switching.gif" width="820" alt="WorkshopWall'da duvar kağıtları arasında geçiş">
</p>

### Neler oynar, neler oynamaz

| Wallpaper Engine türü | macOS | Not |
|---|:---:|---|
| Video | ✅ | MP4 / MOV / M4V. WebM'i macOS'un video çözücüsü desteklemez. |
| Web | ✅ | Ses görselleştiriciler açılır ama sistem sesine tepki vermez. |
| Resim / GIF | ✅ | |
| Scene | ❌ | Wallpaper Engine'e özel, DirectX tabanlı kapalı bir biçim. Basit sahneler elle web duvar kağıdına çevrilebilir: [docs/converting-scenes.md](docs/converting-scenes.md). |
| Uygulama | ❌ | Windows programları. |

## Kurulum

1. [Son sürümden](https://github.com/keremberkant/WorkshopWall/releases/latest) **`WorkshopWall-x.y.z.zip`** dosyasını indirip açın.
2. **WorkshopWall.app**'i **Uygulamalar** klasörüne taşıyın.
3. Uygulama açık kaynaklı ama Apple tarafından onaylanmış (notarize) değil; bunun için ücretli geliştirici hesabı gerekiyor. İlk açılışta **uygulamaya sağ tık → Aç → Aç** deyin.

> [!TIP]
> macOS "hasarlı, açılamıyor" derse indirme karantina işaretini kaldırıp yeniden açın:
> ```bash
> xattr -dr com.apple.quarantine "/Applications/WorkshopWall.app"
> ```

**macOS 14 Sonoma** veya üstü gerekir (Apple Silicon veya Intel). İndirmeyi doğrulamak isterseniz her sürümde zip'in yanında bir `.sha256` dosyası bulunur.

## Kullanım

<p align="center">
  <img src="docs/screenshots/library.png" width="720" alt="WorkshopWall kütüphane penceresi">
</p>

- **Duvar kağıdı ekleme:** dosya veya klasörleri pencereye sürükleyin ya da **+** düğmesine tıklayın. Tek bir Wallpaper Engine projesini, düz bir video / resim / `index.html` dosyasını ya da Atölye klasörünün tamamını (`…/steamapps/workshop/content/431960`) seçip hepsini birden ekleyebilirsiniz.
- **Uygulama:** karta bir kez tıklayın. Mavi çerçeve ve onay işareti oynayanı gösterir.
- **Geçiş:**

  | Kısayol | İşlem |
  |---|---|
  | <kbd>⌃</kbd> <kbd>⌥</kbd> <kbd>⌘</kbd> <kbd>→</kbd> | Sonraki duvar kağıdı (her uygulamada) |
  | <kbd>⌃</kbd> <kbd>⌥</kbd> <kbd>⌘</kbd> <kbd>←</kbd> | Önceki duvar kağıdı (her uygulamada) |
  | <kbd>⌃</kbd> <kbd>⌥</kbd> <kbd>⌘</kbd> <kbd>↓</kbd> | Duraklat / devam et (her uygulamada) |
  | <kbd>⌘</kbd> <kbd>→</kbd> / <kbd>⌘</kbd> <kbd>←</kbd> | Sonraki / önceki (uygulama içinde) |
  | <kbd>⌥</kbd> <kbd>⌘</kbd> <kbd>R</kbd> | Rastgele duvar kağıdı |

  Dock simgesine sağ tıklayarak veya menü çubuğu simgesinden de tüm duvar kağıtlarının listesine ulaşabilirsiniz.
- **Arka planda çalışma:** pencereyi kapatmak duvar kağıdını durdurmaz. Çıkmak için menü çubuğu simgesini veya uygulama menüsünü kullanın.
- **Ayarlar** (<kbd>⌘</kbd> <kbd>,</kbd>): ses, duraklatma kuralları, oturum açılınca başlatma, menü çubuğu simgesi, kütüphane klasörü ve isteğe bağlı olarak önizlemeyi sabit masaüstü resmi yapma (kilit ekranı / Mission Control).

### Steam Atölye'den indirme

Wallpaper Engine'e sahip bir Steam hesabı gerekir.

1. Araç çubuğundaki **indirme** düğmesine tıklayın → SteamCMD'yi **Kur** (≈ 80 MB, kütüphanenin yanına kurulur).
2. Steam kullanıcı adınızı yazın → **Steam'e Giriş Yap…**. Açılan Terminal penceresinde şifrenizi ve Steam Guard kodunuzu **doğrudan SteamCMD'ye** girersiniz. Bu yalnızca bir kez gerekir; SteamCMD oturumu hatırlar.
3. Bir veya daha fazla Atölye linkini yapıştırın → **İndir ve Ekle**.

İpucu: Atölye'yi *Type: Video* veya *Web* ile filtreleyin. Scene öğeleri oynatılamadığı için indirildikten sonra silinir.

## Örnek duvar kağıtları

[`examples`](examples) klasöründe sekiz özgün WebGL duvar kağıdı var. Her biri tek başına çalışan bir `index.html` dosyası ve deponun geri kalanı gibi MIT lisanslı. Hepsini eklemek için `examples` klasörünü kütüphane penceresine sürükleyin. Wallpaper Engine'de ve herhangi bir tarayıcıda da çalışırlar.

| | | | |
|:---:|:---:|:---:|:---:|
| <a href="examples/aurora"><img src="examples/aurora/preview.jpg" width="200" alt="Aurora"></a><br>**Aurora** | <a href="examples/caustics"><img src="examples/caustics/preview.jpg" width="200" alt="Caustics"></a><br>**Caustics** | <a href="examples/synthwave"><img src="examples/synthwave/preview.jpg" width="200" alt="Synthwave"></a><br>**Synthwave** | <a href="examples/dunes"><img src="examples/dunes/preview.jpg" width="200" alt="Dunes"></a><br>**Dunes** |
| <a href="examples/nebula"><img src="examples/nebula/preview.jpg" width="200" alt="Nebula"></a><br>**Nebula** | <a href="examples/lava-lamp"><img src="examples/lava-lamp/preview.jpg" width="200" alt="Lava Lamp"></a><br>**Lava Lamp** | <a href="examples/silk"><img src="examples/silk/preview.jpg" width="200" alt="Silk"></a><br>**Silk** | <a href="examples/bokeh"><img src="examples/bokeh/preview.jpg" width="200" alt="Bokeh"></a><br>**Bokeh** |

## Kendi duvar kağıdınızı yapın

Şunlardan birini içeren her klasör çalışır:

- bir **video** (`.mp4`, `.mov`, `.m4v`), bir **resim** (`.jpg`, `.png`, `.gif`, `.heic`…) veya bir **`index.html`**
- isteğe bağlı olarak başlık ve önizleme için Wallpaper Engine tarzı bir **`project.json`**:

```json
{
  "title": "Duvar Kağıdım",
  "type": "web",
  "file": "index.html",
  "preview": "preview.jpg"
}
```

Web duvar kağıtları korumalı bir WebKit görünümünde çalışır ve yalnızca kendi klasörlerindeki dosyaları okuyabilir. Pil tasarrufu için uygulama istediğinde animasyonu durdurun:

```js
window.wallpaperPropertyListener = {
  setPaused(paused) { /* requestAnimationFrame döngünüzü durdurun veya yeniden başlatın */ },
  applyUserProperties(props) { /* isteğe bağlı: Wallpaper Engine kullanıcı ayarları */ }
};
```

[Örnek duvar kağıtları](examples) iyi bir başlangıç noktası: birini kopyalayıp shader'ını düzenleyin. [`templates/water-waves`](templates/water-waves) ise sabit bir resmi dalgalanan su sahnesine çeviren bir şablon.

## Gizlilik ve güvenlik

- **Analitik yok, uygulama kendi başına internete bağlanmaz.** Ağ yalnızca SteamCMD'yi kurarken (Valve'ın sunucusundan) ve Atölye öğesi indirirken (SteamCMD üzerinden) kullanılır.
- **Steam şifreniz yalnızca Terminal'de**, Valve'ın SteamCMD aracına girilir. WorkshopWall şifrenizi görmez ve saklamaz.
- **Web duvar kağıtları korumalı alanda çalışır:** WebKit'in web içeriği sürecinde, yalnızca kendi klasörlerindeki dosyaları okuyabilirler (test edildi: ev klasörünüzdeki başka dosyalar okunamıyor). Wallpaper Engine'de olduğu gibi web duvar kağıtları internete erişebilir; yalnızca güvendiğiniz duvar kağıtlarını ekleyin.
- **Özel izin gerekmez.** Genel kısayollar Carbon kısayol arayüzünü kullanır (Erişilebilirlik izni gerekmez); "masaüstü kapalı mı" kontrolü yalnızca pencere sınırlarını okur (Ekran Kaydı izni gerekmez).

## Sık sorulanlar

<details>
<summary><b>Çok pil harcar mı?</b></summary>

Videolar donanımda, tüm ekranlar için bir kez çözülür ve en büyük ekranınızın çözünürlüğüyle sınırlanır. Masaüstü görünmediğinde, ekran uyuduğunda, pildeyken veya Düşük Güç Modunda her şey durur (Ayarlar'dan değiştirilebilir). Duraklatılmış bir duvar kağıdı işlemci veya ekran kartı kullanmaz.
</details>

<details>
<summary><b>Wallpaper Engine "Scene" duvar kağıdım neden oynamıyor?</b></summary>

Scene'ler Wallpaper Engine'in kendi DirectX çiziciyi ve kapalı bir biçimi kullanır; başka yerde oynatılamaz. Birçok basit sahne (tek resim + dalga veya titreme efekti) elle küçük bir web duvar kağıdına dönüştürülebilir: [docs/converting-scenes.md](docs/converting-scenes.md).
</details>

<details>
<summary><b>Videom WebM dosyası.</b></summary>

macOS WebM'i yerel olarak çözemez. Bir kez dönüştürüp MP4'ü ekleyin: `ffmpeg -i in.webm -c:v hevc_videotoolbox -tag:v hvc1 -b:v 8M out.mp4`
</details>

<details>
<summary><b>Duvar kağıdını kilit ekranında görebilir miyim?</b></summary>

macOS uygulamaların kilit ekranına çizim yapmasına izin vermez. **Ayarlar → Önizlemeyi sabit masaüstü resmi olarak da ayarla** seçeneğini açarsanız duvar kağıdının sabit önizlemesi orada ve Mission Control'de kullanılır.
</details>

<details>
<summary><b>Duvar kağıtlarım nerede saklanıyor?</b></summary>

Varsayılan olarak `~/Library/Application Support/WorkshopWall/Wallpapers` klasöründe. Ayarlar'dan harici disk dahil herhangi bir klasörü seçebilirsiniz.
</details>

## Kaynaktan derleme

Gereksinim: macOS 14+ üzerinde Xcode 15+ (Swift 5.9+).

```bash
git clone https://github.com/keremberkant/WorkshopWall.git
cd WorkshopWall
swift test                                 # birim testleri
scripts/build-app.sh                       # → dist/WorkshopWall.app (universal)
scripts/build-app.sh --install             # derle ve /Applications'a kopyala
VERSION=1.2.0 scripts/build-app.sh --zip   # sürüm zip'i + SHA-256
```

Dilerseniz `Package.swift` dosyasını Xcode'da açıp `WorkshopWall` şemasını çalıştırabilirsiniz. Proje yapısı ve teknik ayrıntılar için [İngilizce README](README.md#project-layout)'ye bakın.

## Katkı

Hata bildirimleri ve pull request'ler memnuniyetle karşılanır: [CONTRIBUTING.md](CONTRIBUTING.md). Özellikle yeni örnek duvar kağıtları ve çeviriler. Çeviri için İngilizce metinleri anahtar olarak kullanan bir `Resources/<dil>.lproj/Localizable.strings` dosyası ekleyin.

## Lisans

[MIT](LICENSE) © keremberkant.

Wallpaper Engine ilgili sahiplerinin ticari markasıdır; Steam ve SteamCMD, Valve Corporation'ın ticari markalarıdır. Ekran görüntülerinde bu depodaki özgün örnek duvar kağıtları kullanılmıştır. WorkshopWall'ın 1.0 sürümünün adı *Canlı Duvar*'dı; güncellediğinizde ayarlarınız ve kütüphaneniz korunur.
