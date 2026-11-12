#!/usr/bin/env swift

import AppKit
import CoreGraphics
import Foundation

private let designSize: CGFloat = 1024
private let canvasSize = Int(designSize)
private let iconPath = "App/Resources/AppIcon.icns"

private func makeContext(pixelSize: Int) -> CGContext {
    guard let context = CGContext(
        data: nil,
        width: pixelSize,
        height: pixelSize,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        fatalError("Unable to create bitmap context")
    }
    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)
    context.interpolationQuality = .high
    return context
}

private func drawGlyph(in context: CGContext) {
    let glyph = CGMutablePath()
    glyph.move(to: CGPoint(x: 402, y: 348))
    glyph.addLine(to: CGPoint(x: 282, y: 500))
    glyph.addLine(to: CGPoint(x: 402, y: 652))

    glyph.move(to: CGPoint(x: 552, y: 318))
    glyph.addLine(to: CGPoint(x: 472, y: 682))

    glyph.move(to: CGPoint(x: 622, y: 348))
    glyph.addLine(to: CGPoint(x: 742, y: 500))
    glyph.addLine(to: CGPoint(x: 622, y: 652))

    context.saveGState()
    context.setShadow(
        offset: CGSize(width: 0, height: -6),
        blur: 12,
        color: NSColor.black.withAlphaComponent(0.16).cgColor
    )
    context.addPath(glyph)
    context.setLineWidth(56)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.setStrokeColor(NSColor.white.withAlphaComponent(0.98).cgColor)
    context.strokePath()
    context.restoreGState()
}

private func drawIcon(in context: CGContext, pixelSize: Int) {
    let scale = CGFloat(pixelSize) / designSize
    context.translateBy(x: 0, y: CGFloat(pixelSize))
    context.scaleBy(x: scale, y: -scale)

    let rect = CGRect(x: 100, y: 100, width: 824, height: 824)
    let radius: CGFloat = 185.4
    let shape = CGPath(
        roundedRect: rect,
        cornerWidth: radius,
        cornerHeight: radius,
        transform: nil
    )

    context.saveGState()
    context.setShadow(
        offset: CGSize(width: 0, height: -12),
        blur: 28,
        color: NSColor.black.withAlphaComponent(0.26).cgColor
    )
    context.addPath(shape)
    context.setFillColor(NSColor.black.cgColor)
    context.fillPath()
    context.restoreGState()

    context.saveGState()
    context.addPath(shape)
    context.clip()

    let colors = [
        NSColor(srgbRed: 0.42, green: 0.66, blue: 1.00, alpha: 1).cgColor,
        NSColor(srgbRed: 0.25, green: 0.44, blue: 0.96, alpha: 1).cgColor,
        NSColor(srgbRed: 0.14, green: 0.24, blue: 0.78, alpha: 1).cgColor,
    ] as CFArray
    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: colors,
        locations: [0, 0.52, 1]
    )!
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: 150, y: 110),
        end: CGPoint(x: 900, y: 910),
        options: []
    )

    let highlightColors = [
        NSColor.white.withAlphaComponent(0.28).cgColor,
        NSColor.white.withAlphaComponent(0.0).cgColor,
    ] as CFArray
    let highlight = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: highlightColors,
        locations: [0, 1]
    )!
    context.drawRadialGradient(
        highlight,
        startCenter: CGPoint(x: 320, y: 180),
        startRadius: 0,
        endCenter: CGPoint(x: 320, y: 180),
        endRadius: 640,
        options: []
    )

    let shadeColors = [
        NSColor.black.withAlphaComponent(0.0).cgColor,
        NSColor.black.withAlphaComponent(0.14).cgColor,
    ] as CFArray
    let shade = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: shadeColors,
        locations: [0, 1]
    )!
    context.drawLinearGradient(
        shade,
        start: CGPoint(x: 512, y: 600),
        end: CGPoint(x: 512, y: 924),
        options: []
    )
    context.restoreGState()

    context.saveGState()
    let border = CGPath(
        roundedRect: rect.insetBy(dx: 1.5, dy: 1.5),
        cornerWidth: radius - 1.5,
        cornerHeight: radius - 1.5,
        transform: nil
    )
    context.addPath(border)
    context.setLineWidth(3)
    context.setStrokeColor(NSColor.white.withAlphaComponent(0.20).cgColor)
    context.strokePath()
    context.restoreGState()

    drawGlyph(in: context)
}

private func writePNG(_ image: CGImage, to url: URL) {
    let bitmap = NSBitmapImageRep(cgImage: image)
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Unable to encode PNG")
    }
    try! data.write(to: url)
}

private func renderIcon(pixelSize: Int) -> CGImage {
    let context = makeContext(pixelSize: pixelSize)
    drawIcon(in: context, pixelSize: pixelSize)
    return context.makeImage()!
}

private func writeICNS(entries: [(type: String, url: URL)], to path: String) {
    var body = Data()
    for entry in entries {
        let png = try! Data(contentsOf: entry.url)
        body.append(entry.type.data(using: .ascii)!)
        var length = UInt32(png.count + 8).bigEndian
        body.append(Data(bytes: &length, count: 4))
        body.append(png)
    }

    var data = Data("icns".utf8)
    var total = UInt32(body.count + 8).bigEndian
    data.append(Data(bytes: &total, count: 4))
    data.append(body)
    try! data.write(to: URL(fileURLWithPath: path))
}

let iconset = URL(fileURLWithPath: "build/AppIcon.iconset", isDirectory: true)
try? FileManager.default.removeItem(at: iconset)
try! FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

let variants: [(name: String, type: String, size: Int)] = [
    ("icon_16x16.png", "icp4", 16),
    ("icon_32x32.png", "icp5", 32),
    ("icon_32x32@2x.png", "icp6", 64),
    ("icon_128x128.png", "ic07", 128),
    ("icon_256x256.png", "ic08", 256),
    ("icon_512x512.png", "ic09", 512),
    ("icon_512x512@2x.png", "ic10", 1024),
]

for variant in variants {
    let image = renderIcon(pixelSize: variant.size)
    writePNG(image, to: iconset.appendingPathComponent(variant.name))
}

let previewURL = URL(fileURLWithPath: "/tmp/devpreview-icon-1024.png")
writePNG(renderIcon(pixelSize: canvasSize), to: previewURL)

try! FileManager.default.createDirectory(
    at: URL(fileURLWithPath: "App/Resources", isDirectory: true),
    withIntermediateDirectories: true
)
writeICNS(
    entries: variants.map { ($0.type, iconset.appendingPathComponent($0.name)) },
    to: iconPath
)

let attributes = try! FileManager.default.attributesOfItem(atPath: iconPath)
let size = attributes[.size] as? Int ?? 0
print("Wrote \(iconPath) (\(size) bytes)")
print("Wrote preview \(previewURL.path)")
