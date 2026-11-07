import WorkshopWallCore
import SwiftUI

struct WallpaperCard: View {
    let wallpaper: Wallpaper
    let isCurrent: Bool
    @State private var hovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Thumbnail(url: wallpaper.preview, placeholderSymbol: symbol)
                .frame(height: 130)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isCurrent ? Color.accentColor : .clear, lineWidth: 3))
                .overlay(alignment: .topTrailing) { badge }
                .overlay {
                    if hovering && wallpaper.isPlayable && !isCurrent {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.white, .black.opacity(0.45))
                    }
                }
                .opacity(wallpaper.isPlayable ? 1 : 0.45)
                .scaleEffect(hovering && wallpaper.isPlayable ? 1.02 : 1)
                .animation(.easeOut(duration: 0.12), value: hovering)

            HStack(spacing: 4) {
                if isCurrent { Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.accentColor) }
                Text(wallpaper.title).lineLimit(1).font(.callout.weight(.medium))
            }
            if !wallpaper.isPlayable {
                Text(wallpaper.kind == .scene ? "Scene wallpapers can’t play on macOS" : "This format isn’t supported")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .help(wallpaper.isPlayable ? String(localized: "Click to apply") : "")
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    private var badge: some View {
        Text(badgeText)
            .font(.caption2.bold())
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(6)
    }

    private var symbol: String {
        switch wallpaper.kind {
        case .video: return "film"
        case .web: return "globe"
        case .image: return "photo"
        case .scene, .unsupported: return "questionmark.square.dashed"
        }
    }

    private var badgeText: LocalizedStringKey {
        switch wallpaper.kind {
        case .video: return "VIDEO"
        case .web: return "WEB"
        case .image: return "IMAGE"
        case .scene: return "SCENE"
        case .unsupported: return "?"
        }
    }
}
