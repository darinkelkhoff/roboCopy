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
    colorSpaceName: .calibratedRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fputs("Unable to create bitmap\n", stderr)
    exit(70)
}

NSGraphicsContext.saveGraphicsState()
guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    NSGraphicsContext.restoreGraphicsState()
    fputs("Unable to create graphics context\n", stderr)
    exit(70)
}
NSGraphicsContext.current = context
NSColor.clear.setFill()
NSRect(x: 0, y: 0, width: pixels, height: pixels).fill()
image.draw(
    in: NSRect(x: 0, y: 0, width: pixels, height: pixels),
    from: NSRect(origin: .zero, size: image.size),
    operation: .sourceOver,
    fraction: 1
)
NSGraphicsContext.restoreGraphicsState()

guard let sRGBBitmap = bitmap.converting(to: .sRGB, renderingIntent: .default) else {
    fputs("Unable to convert bitmap to sRGB\n", stderr)
    exit(70)
}
guard let png = sRGBBitmap.representation(using: .png, properties: [:]) else {
    fputs("Unable to encode PNG\n", stderr)
    exit(70)
}
do {
    try png.write(to: URL(fileURLWithPath: output), options: .atomic)
} catch {
    fputs("Unable to write PNG to \(output): \(error)\n", stderr)
    exit(74)
}
