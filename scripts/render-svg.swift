#!/usr/bin/swift
import AppKit
import Foundation

guard CommandLine.arguments.count == 4,
      let pixels = Int(CommandLine.arguments[3]),
      pixels > 0 else {
    fputs("usage: render-svg.swift input.svg output.png pixels\n", stderr)
    exit(64)
}

let input = CommandLine.arguments[1]
let output = CommandLine.arguments[2]
guard let image = NSImage(contentsOfFile: input) else {
    fputs("Unable to load SVG: \(input)\n", stderr)
    exit(65)
}
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: pixels,
    pixelsHigh: pixels,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fputs("Unable to create bitmap\n", stderr)
    exit(70)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
NSColor.clear.setFill()
NSRect(x: 0, y: 0, width: pixels, height: pixels).fill()
image.draw(
    in: NSRect(x: 0, y: 0, width: pixels, height: pixels),
    from: NSRect(origin: .zero, size: image.size),
    operation: .sourceOver,
    fraction: 1
)
NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Unable to encode PNG\n", stderr)
    exit(70)
}
try png.write(to: URL(fileURLWithPath: output), options: .atomic)
