// Draws the app icon (1024×1024 PNG). Usage: swift scripts/make-icon.swift out.png
import AppKit

let size: CGFloat = 1024
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon.png"

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size), bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext

// macOS icon grid: 824×824 body with ~185 corner radius, centered.
let body = CGRect(x: 100, y: 100, width: 824, height: 824)
let shape = CGPath(roundedRect: body, cornerWidth: 185, cornerHeight: 185, transform: nil)

// Shadow
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: NSColor.black.withAlphaComponent(0.35).cgColor)
ctx.addPath(shape); ctx.setFillColor(NSColor.black.cgColor); ctx.fillPath()
ctx.restoreGState()

ctx.saveGState()
ctx.addPath(shape); ctx.clip()

// Deep background
let bg = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: [NSColor(red: 0.04, green: 0.03, blue: 0.10, alpha: 1).cgColor,
                             NSColor(red: 0.01, green: 0.01, blue: 0.03, alpha: 1).cgColor] as CFArray,
                    locations: [0, 1])!
ctx.drawLinearGradient(bg, start: CGPoint(x: 0, y: size), end: CGPoint(x: size, y: 0), options: [])

// Flowing bands (inspired by liquid display wallpapers)
let bands: [(NSColor, CGFloat, CGFloat)] = [
    (NSColor(red: 1.00, green: 0.18, blue: 0.45, alpha: 1), 330, 30),
    (NSColor(red: 1.00, green: 0.78, blue: 0.10, alpha: 1), 420, 24),
    (NSColor(red: 0.62, green: 0.25, blue: 1.00, alpha: 1), 505, 30),
    (NSColor(red: 0.10, green: 0.85, blue: 1.00, alpha: 1), 590, 26),
    (NSColor(red: 0.20, green: 0.45, blue: 1.00, alpha: 1), 680, 32),
]
for (color, offset, width) in bands {
    let path = CGMutablePath()
    path.move(to: CGPoint(x: 40, y: offset - 120))
    path.addCurve(to: CGPoint(x: 1000, y: offset + 140),
                  control1: CGPoint(x: 380, y: offset + 330),
                  control2: CGPoint(x: 620, y: offset - 330))
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 40, color: color.withAlphaComponent(0.9).cgColor)
    ctx.addPath(path)
    ctx.setStrokeColor(color.cgColor)
    ctx.setLineWidth(width)
    ctx.setLineCap(.round)
    ctx.strokePath()
    ctx.restoreGState()
    // bright core
    ctx.addPath(path)
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.55).cgColor)
    ctx.setLineWidth(width * 0.22)
    ctx.strokePath()
}

// Glass play badge
let badge = CGRect(x: 612, y: 156, width: 236, height: 236)
ctx.setFillColor(NSColor.white.withAlphaComponent(0.92).cgColor)
ctx.fillEllipse(in: badge)
let tri = CGMutablePath()
tri.move(to: CGPoint(x: badge.midX - 34, y: badge.midY - 58))
tri.addLine(to: CGPoint(x: badge.midX - 34, y: badge.midY + 58))
tri.addLine(to: CGPoint(x: badge.midX + 62, y: badge.midY))
tri.closeSubpath()
ctx.addPath(tri)
ctx.setFillColor(NSColor(red: 0.08, green: 0.06, blue: 0.20, alpha: 1).cgColor)
ctx.fillPath()

// Subtle top highlight
let gloss = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                       colors: [NSColor.white.withAlphaComponent(0.16).cgColor, NSColor.white.withAlphaComponent(0).cgColor] as CFArray,
                       locations: [0, 1])!
ctx.drawLinearGradient(gloss, start: CGPoint(x: 0, y: 924), end: CGPoint(x: 0, y: 620), options: [])
ctx.restoreGState()

NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
