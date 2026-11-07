import AppKit
import AVFoundation
import WorkshopWallCore
import WebKit

/// Content of one display: a video layer, a web view or an image.
@MainActor
final class WallpaperView: NSView {
    private var playerLayer: AVPlayerLayer?
    private var webView: WKWebView?
    private var imageView: NSImageView?
    private var paused = false

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        autoresizingMask = [.width, .height]
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    /// Shows a wallpaper. Videos use a player shared by all displays, so the clip is decoded only once.
    func show(_ wallpaper: Wallpaper, sharedPlayer: AVPlayer?, muted: Bool) {
        clear()
        guard let file = wallpaper.file else { return }
        switch wallpaper.kind {
        case .video:
            guard let sharedPlayer else { return }
            let layer = AVPlayerLayer(player: sharedPlayer)
            layer.videoGravity = .resizeAspectFill
            layer.frame = bounds
            layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
            self.layer?.addSublayer(layer)
            playerLayer = layer
        case .web:
            showWeb(wallpaper, file: file, muted: muted)
        case .image:
            let view = NSImageView(frame: bounds)
            view.autoresizingMask = [.width, .height]
            view.imageScaling = .scaleProportionallyUpOrDown
            view.animates = !paused
            view.image = NSImage(contentsOf: file)
            view.wantsLayer = true
            view.layer?.contentsGravity = .resizeAspectFill
            addSubview(view)
            imageView = view
            fillImage()
        case .scene, .unsupported:
            break
        }
    }

    private func showWeb(_ wallpaper: Wallpaper, file: URL, muted: Bool) {
        let config = WKWebViewConfiguration()
        config.mediaTypesRequiringUserActionForPlayback = []
        config.suppressesIncrementalRendering = true
        // Wallpaper Engine web wallpapers load images from their own folder into canvas/WebGL, which
        // WebKit blocks for file:// pages by default. Reads stay limited to the wallpaper's folder by
        // `allowingReadAccessTo:` and WebKit's sandbox (verified: files elsewhere cannot be read).
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.userContentController.addUserScript(WKUserScript(
            source: Self.wallpaperEngineShim(properties: wallpaper.webPropertiesJSON, muted: muted),
            injectionTime: .atDocumentStart, forMainFrameOnly: true))

        let web = WKWebView(frame: bounds, configuration: config)
        web.autoresizingMask = [.width, .height]
        web.setValue(false, forKey: "drawsBackground")
        web.loadFileURL(file, allowingReadAccessTo: wallpaper.folder)
        addSubview(web)
        webView = web
    }

    /// The parts of Wallpaper Engine's web API that wallpapers commonly call.
    private static func wallpaperEngineShim(properties: String, muted: Bool) -> String {
        """
        (function () {
          var props = \(properties);
          var noop = function () {};
          ['wallpaperRegisterAudioListener', 'wallpaperRegisterMediaStatusListener',
           'wallpaperRegisterMediaPropertiesListener', 'wallpaperRegisterMediaThumbnailListener',
           'wallpaperRegisterMediaPlaybackListener', 'wallpaperRegisterMediaTimelineListener']
            .forEach(function (n) { if (!window[n]) window[n] = noop; });
          window.__workshopWallSetPaused = function (p) {
            try { var l = window.wallpaperPropertyListener; if (l && l.setPaused) l.setPaused(p); } catch (e) {}
            document.querySelectorAll('video,audio').forEach(function (m) { p ? m.pause() : m.play().catch(noop); });
          };
          window.__workshopWallSetMuted = function (m) {
            document.querySelectorAll('video,audio').forEach(function (e) { e.muted = m; });
          };
          window.addEventListener('load', function () {
            setTimeout(function () {
              try { var l = window.wallpaperPropertyListener; if (l && l.applyUserProperties) l.applyUserProperties(props); } catch (e) {}
              window.__workshopWallSetMuted(\(muted));
            }, 50);
          });
        })();
        """
    }

    override func layout() {
        super.layout()
        fillImage()
    }

    /// Aspect-fill for still images (NSImageView only offers aspect-fit).
    private func fillImage() {
        guard let imageView, let size = imageView.image?.size, size.width > 0, size.height > 0 else { return }
        let scale = max(bounds.width / size.width, bounds.height / size.height)
        let w = size.width * scale, h = size.height * scale
        imageView.frame = NSRect(x: (bounds.width - w) / 2, y: (bounds.height - h) / 2, width: w, height: h)
    }

    func setPaused(_ paused: Bool) {
        guard paused != self.paused else { return }
        self.paused = paused
        webView?.evaluateJavaScript("window.__workshopWallSetPaused && window.__workshopWallSetPaused(\(paused))")
        imageView?.animates = !paused
    }

    func setMuted(_ muted: Bool) {
        webView?.evaluateJavaScript("window.__workshopWallSetMuted && window.__workshopWallSetMuted(\(muted))")
    }

    func clear() {
        playerLayer?.player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        webView?.stopLoading()
        webView?.removeFromSuperview()
        webView = nil
        imageView?.removeFromSuperview()
        imageView = nil
    }
}
