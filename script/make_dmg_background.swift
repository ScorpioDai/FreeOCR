#!/usr/bin/env swift

import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("usage: make_dmg_background.swift <output.png>\n".utf8))
    exit(2)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let canvas = NSSize(width: 700, height: 460)
let rect = NSRect(origin: .zero, size: canvas)
let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(canvas.width),
    pixelsHigh: Int(canvas.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
)!
bitmap.size = canvas
let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = graphicsContext

let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.985, green: 0.992, blue: 1.0, alpha: 1),
    NSColor(calibratedRed: 0.91, green: 0.95, blue: 1.0, alpha: 1)
])!
gradient.draw(in: rect, angle: -90)

let glow = NSBezierPath(roundedRect: NSRect(x: 56, y: 94, width: 588, height: 238), xRadius: 36, yRadius: 36)
NSColor.white.withAlphaComponent(0.58).setFill()
glow.fill()
NSColor(calibratedRed: 0.55, green: 0.72, blue: 0.96, alpha: 0.22).setStroke()
glow.lineWidth = 1
glow.stroke()

func drawCentered(_ text: String, y: CGFloat, attributes: [NSAttributedString.Key: Any]) {
    let size = text.size(withAttributes: attributes)
    text.draw(
        at: NSPoint(x: (canvas.width - size.width) / 2, y: y),
        withAttributes: attributes
    )
}

let titleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 27, weight: .semibold),
    .foregroundColor: NSColor(calibratedWhite: 0.11, alpha: 1)
]
let subtitleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 16, weight: .medium),
    .foregroundColor: NSColor(calibratedWhite: 0.34, alpha: 1)
]
let hintAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 12, weight: .semibold),
    .foregroundColor: NSColor(calibratedRed: 0.16, green: 0.46, blue: 0.88, alpha: 0.88),
    .kern: 1.2
]
let footerAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 12, weight: .medium),
    .foregroundColor: NSColor(calibratedWhite: 0.45, alpha: 1)
]

drawCentered("Drag FreeOCR to Applications", y: 391, attributes: titleAttributes)
drawCentered("将 FreeOCR 拖入“应用程序”文件夹", y: 362, attributes: subtitleAttributes)
drawCentered("DRAG TO INSTALL", y: 142, attributes: hintAttributes)
drawCentered("macOS 26+  •  Apple Silicon", y: 28, attributes: footerAttributes)

let arrowColor = NSColor(calibratedRed: 0.12, green: 0.5, blue: 0.98, alpha: 0.96)
arrowColor.setStroke()
arrowColor.setFill()

let shaft = NSBezierPath()
shaft.move(to: NSPoint(x: 292, y: 229))
shaft.line(to: NSPoint(x: 402, y: 229))
shaft.lineWidth = 7
shaft.lineCapStyle = .round
shaft.stroke()

let arrowHead = NSBezierPath()
arrowHead.move(to: NSPoint(x: 392, y: 250))
arrowHead.line(to: NSPoint(x: 420, y: 229))
arrowHead.line(to: NSPoint(x: 392, y: 208))
arrowHead.close()
arrowHead.fill()

graphicsContext.flushGraphics()
NSGraphicsContext.restoreGraphicsState()

guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("Could not render DMG background\n".utf8))
    exit(1)
}

try pngData.write(to: outputURL, options: .atomic)
