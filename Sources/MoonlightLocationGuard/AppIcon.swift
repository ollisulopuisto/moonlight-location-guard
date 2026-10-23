import AppKit

/// Gaming-style menu-bar icon: a shield "guard" with pause-bar motif.
/// Inactive = blue outline; active (streaming / location off) = red filled.
enum AppIcon {
    static let size: CGFloat = 18

    static var inactive: NSImage { draw(filled: false, color: .systemBlue) }
    static var active: NSImage  { draw(filled: true,  color: .systemRed) }

    private static func draw(filled: Bool, color: NSColor) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        defer { image.unlockFocus() }
        guard let ctx = NSGraphicsContext.current?.cgContext else { return image }

        ctx.setAllowsAntialiasing(true)
        let w = size, h = size
        let cx = w / 2

        // Shield outline: rounded top, pointed bottom.
        let shield = CGMutablePath()
        shield.move(to: CGPoint(x: cx, y: 2))
        shield.addCurve(to: CGPoint(x: 4, y: 10),
                        control1: CGPoint(x: cx - 5, y: 2),
                        control2: CGPoint(x: 4, y: 6))
        shield.addLine(to: CGPoint(x: 4, y: h - 4))
        shield.addCurve(to: CGPoint(x: cx, y: h - 1),
                        control1: CGPoint(x: 4, y: h - 2),
                        control2: CGPoint(x: cx - 3, y: h - 2))
        shield.addCurve(to: CGPoint(x: w - 4, y: h - 4),
                        control1: CGPoint(x: cx + 3, y: h - 2),
                        control2: CGPoint(x: w - 4, y: h - 2))
        shield.addLine(to: CGPoint(x: w - 4, y: 10))
        shield.addCurve(to: CGPoint(x: cx, y: 2),
                        control1: CGPoint(x: w - 4, y: 6),
                        control2: CGPoint(x: cx + 5, y: 2))
        shield.closeSubpath()

        ctx.addPath(shield)
        if filled {
            ctx.setFillColor(color.cgColor)
            ctx.fillPath()
        } else {
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(1.6)
            ctx.strokePath()
        }

        // Inner "guard bars" — vertical pair like a pause/game guard symbol.
        let barW: CGFloat = 2, barH: CGFloat = 7, gap: CGFloat = 3
        let totalW = barW * 2 + gap
        let startX = cx - totalW / 2
        let startY = (h - barH) / 2 + 1

        let bars = CGMutablePath()
        bars.addRect(CGRect(x: startX, y: startY, width: barW, height: barH))
        bars.addRect(CGRect(x: startX + barW + gap, y: startY, width: barW, height: barH))

        ctx.addPath(bars)
        if filled {
            ctx.setFillColor(NSColor.white.cgColor)
            ctx.fillPath()
        } else {
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(1.2)
            ctx.strokePath()
        }

        return image
    }
}
