import AppKit

// Renders a full-bleed 1024 source into a macOS-styled icon: the artwork scaled
// to the standard 824-of-1024 grid, centered, clipped to the rounded-rect mask.
// Usage: swift style-icon.swift <source.png> <out.png>

guard CommandLine.arguments.count == 3 else {
    FileHandle.standardError.write("usage: swift style-icon.swift <source.png> <out.png>\n".data(using: .utf8)!)
    exit(1)
}
let srcPath = CommandLine.arguments[1]
let outPath = CommandLine.arguments[2]

guard let src = NSImage(contentsOfFile: srcPath) else {
    FileHandle.standardError.write("could not load \(srcPath)\n".data(using: .utf8)!)
    exit(1)
}

let side: CGFloat = 1024
let inset: CGFloat = 100          // → 824 artwork, the macOS icon grid
let radius: CGFloat = 185         // macOS rounded-rect corner radius at this size

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(side), pixelsHigh: Int(side),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
rep.size = NSSize(width: side, height: side)

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let rect = NSRect(x: inset, y: inset, width: side - inset * 2, height: side - inset * 2)
NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).addClip()
src.draw(in: rect, from: .zero, operation: .copy, fraction: 1.0)
NSGraphicsContext.restoreGraphicsState()

guard let data = rep.representation(using: .png, properties: [:]) else { exit(1) }
try! data.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")
