import AppKit

/// Draws the OpenFactor cube mark as a template NSImage for the menu bar.
///
/// Ported from OpenFactor's watch complication (`OpenFactorComplication.swift`):
/// an isometric cube whose three faces are told apart by opacity alone (top 1.0,
/// left 0.72, right 0.45), in unit proportions with width:height = √3/2 ≈ 0.866.
/// As a template image macOS paints the alpha with the menu-bar colour.
enum IconRenderer {

    enum State {
        case active          // filled cube
        case disabled        // dimmed cube
        case needsAttention  // hollow (outline) cube + exclamation badge
    }

    static func menuBarIcon(_ state: State, height: CGFloat = 18) -> NSImage {
        switch state {
        case .active:         return filledCube(height: height, opacityScale: 1.0)
        case .disabled:       return filledCube(height: height, opacityScale: 0.35)
        case .needsAttention: return attention(height: height)
        }
    }

    // MARK: Geometry

    /// The three face polygons of the cube in the given rect (SwiftUI y-down order).
    private static func faces(in rect: CGRect) -> [[CGPoint]] {
        let quarter = rect.minY + rect.height * 0.25
        let threeQuarters = rect.minY + rect.height * 0.75
        let north  = CGPoint(x: rect.midX, y: rect.minY)
        let east   = CGPoint(x: rect.maxX, y: quarter)
        let west   = CGPoint(x: rect.minX, y: quarter)
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        let south  = CGPoint(x: rect.midX, y: rect.maxY)
        return [
            [north, east, centre, west],                                    // top
            [west, centre, south, CGPoint(x: rect.minX, y: threeQuarters)], // left
            [east, centre, south, CGPoint(x: rect.maxX, y: threeQuarters)], // right
        ]
    }

    private static func polygon(_ points: [CGPoint]) -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: points[0])
        for p in points.dropFirst() { path.line(to: p) }
        path.close()
        return path
    }

    // MARK: Variants

    private static func filledCube(height: CGFloat, opacityScale: CGFloat) -> NSImage {
        let width = height * 0.866
        let image = NSImage(size: NSSize(width: width, height: height), flipped: true) { rect in
            let alphas: [CGFloat] = [1.0, 0.72, 0.45]
            for (i, face) in faces(in: rect).enumerated() {
                NSColor.black.withAlphaComponent(alphas[i] * opacityScale).setFill()
                polygon(face).fill()
            }
            return true
        }
        image.isTemplate = true
        return image
    }

    /// Hollow wireframe cube with an exclamation mark to its right — the
    /// "needs your attention" state, mirroring the Wi-Fi menu-bar convention.
    private static func attention(height: CGFloat) -> NSImage {
        let cubeWidth = height * 0.866
        let gap = height * 0.10
        let exWidth = height * 0.42
        let width = cubeWidth + gap + exWidth

        let image = NSImage(size: NSSize(width: width, height: height), flipped: true) { _ in
            // Wireframe cube (slightly inset so the stroke isn't clipped).
            let inset = height * 0.06
            let cubeRect = CGRect(x: inset, y: inset, width: cubeWidth - inset * 2, height: height - inset * 2)
            NSColor.black.setStroke()
            for face in faces(in: cubeRect) {
                let p = polygon(face)
                p.lineWidth = height * 0.085
                p.lineJoinStyle = .round
                p.stroke()
            }

            // Exclamation mark.
            let region = CGRect(x: cubeWidth + gap, y: 0, width: exWidth, height: height)
            drawExclamation(in: region)
            return true
        }
        image.isTemplate = true
        return image
    }

    private static func drawExclamation(in r: CGRect) {
        let stemW = r.width * 0.42
        let stemTop = r.minY + r.height * 0.14
        let stemBottom = r.minY + r.height * 0.62
        let stem = NSBezierPath(
            roundedRect: CGRect(x: r.midX - stemW / 2, y: stemTop, width: stemW, height: stemBottom - stemTop),
            xRadius: stemW / 2, yRadius: stemW / 2)
        NSColor.black.setFill()
        stem.fill()

        let dotD = stemW * 1.05
        let dot = NSBezierPath(ovalIn: CGRect(
            x: r.midX - dotD / 2, y: r.minY + r.height * 0.74, width: dotD, height: dotD))
        dot.fill()
    }
}
