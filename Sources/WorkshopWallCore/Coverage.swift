import CoreGraphics

/// Decides whether a display is hidden behind application windows, so playback can pause
/// (full-screen apps, maximized windows). Rectangles use the same coordinate space.
public enum Coverage {
    /// `true` when one window, or the union of the given windows along a full row or column,
    /// hides almost all of `screen`. Leaves room for the menu bar and the Dock.
    public static func isCovered(screen: CGRect, by windows: [CGRect],
                                 edgeTolerance: CGFloat = 4, verticalAllowance: CGFloat = 140) -> Bool {
        guard screen.width > 0, screen.height > 0 else { return false }
        for window in windows {
            let i = window.intersection(screen)
            guard !i.isNull else { continue }
            if i.width >= screen.width - edgeTolerance && i.height >= screen.height - verticalAllowance {
                return true
            }
        }
        // Fallback: total covered area (overlaps counted once on a coarse grid).
        return coveredFraction(screen: screen, by: windows) >= 0.97
    }

    /// Fraction of `screen` covered by `windows`, sampled on a 32×20 grid (cheap and good enough).
    public static func coveredFraction(screen: CGRect, by windows: [CGRect]) -> Double {
        let cols = 32, rows = 20
        var hits = 0
        for r in 0..<rows {
            for c in 0..<cols {
                let p = CGPoint(x: screen.minX + (CGFloat(c) + 0.5) * screen.width / CGFloat(cols),
                                y: screen.minY + (CGFloat(r) + 0.5) * screen.height / CGFloat(rows))
                if windows.contains(where: { $0.contains(p) }) { hits += 1 }
            }
        }
        return Double(hits) / Double(cols * rows)
    }
}
