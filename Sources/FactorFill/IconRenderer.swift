import AppKit

/// Draws the OpenFactor cube mark as a template NSImage for the menu bar.
///
/// Ported from OpenFactor's watch complication (`OpenFactorComplication.swift`):
/// an isometric cube whose three faces are told apart by opacity alone (top 1.0,
/// left 0.72, right 0.45), in unit proportions with width:height = √3/2 ≈ 0.866.
/// As a template image macOS paints the alpha with the menu-bar colour, so the
/// three opacities become three shades — the same "solid with a light on it" read.
enum IconRenderer {

    static func menuBarIcon(height: CGFloat = 18, dimmed: Bool = false) -> NSImage {
        let width = height * 0.866
        let scale: CGFloat = dimmed ? 0.35 : 1.0
        let image = NSImage(size: NSSize(width: width, height: height), flipped: true) { rect in
            drawCube(in: rect, opacityScale: scale)
            return true
        }
        image.isTemplate = true
        return image
    }

    private static func drawCube(in rect: CGRect, opacityScale: CGFloat) {
        let quarter = rect.minY + rect.height * 0.25
        let threeQuarters = rect.minY + rect.height * 0.75

        let north  = CGPoint(x: rect.midX, y: rect.minY)
        let east   = CGPoint(x: rect.maxX, y: quarter)
        let west   = CGPoint(x: rect.minX, y: quarter)
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        let south  = CGPoint(x: rect.midX, y: rect.maxY)

        func fill(_ points: [CGPoint], _ alpha: CGFloat) {
            let path = NSBezierPath()
            path.move(to: points[0])
            for p in points.dropFirst() { path.line(to: p) }
            path.close()
            NSColor.black.withAlphaComponent(alpha * opacityScale).setFill()
            path.fill()
        }

        fill([north, east, centre, west], 1.0)                                    // top
        fill([west, centre, south, CGPoint(x: rect.minX, y: threeQuarters)], 0.72) // left
        fill([east, centre, south, CGPoint(x: rect.maxX, y: threeQuarters)], 0.45) // right
    }
}
