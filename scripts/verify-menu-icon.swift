#!/usr/bin/swift
import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("usage: verify-menu-icon.swift image.png\n", stderr)
    exit(64)
}

let input = CommandLine.arguments[1]
guard let image = NSImage(contentsOfFile: input),
      let data = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: data) else {
    fputs("Unable to load PNG: \(input)\n", stderr)
    exit(65)
}

guard bitmap.pixelsWide == 46, bitmap.pixelsHigh == 36 else {
    fputs(
        "Expected 46x36 pixels, got \(bitmap.pixelsWide)x\(bitmap.pixelsHigh)\n",
        stderr
    )
    exit(1)
}

var visiblePixels = 0
for y in 0..<bitmap.pixelsHigh {
    for x in 0..<bitmap.pixelsWide {
        if (bitmap.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0.1 {
            visiblePixels += 1
        }
    }
}

let totalPixels = bitmap.pixelsWide * bitmap.pixelsHigh
let coverage = Double(visiblePixels) / Double(totalPixels)
guard coverage > 0.15, coverage < 0.75 else {
    fputs("Unexpected visible-pixel coverage: \(coverage)\n", stderr)
    exit(1)
}

print("Verified 46x36 menu icon with \(visiblePixels) visible pixels")
