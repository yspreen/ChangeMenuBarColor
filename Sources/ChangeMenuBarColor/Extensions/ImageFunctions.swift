//
//  ChangeMenuBarColor+ImageManipulation.swift
//  ChangeMenuBarColor
//
//  Created by Igor Kulman on 19.11.2020.
//

import Cocoa
import Foundation

#if canImport(Accessibility)
    import Accessibility
#endif

func getMainDisplayScale() -> CGFloat {
    return NSScreen.main?.backingScaleFactor ?? 1
}

func createGradientImage(startColor: NSColor, endColor: NSColor, width: CGFloat, height: CGFloat)
    -> NSImage?
{
    guard let context = createContext(width: width, height: height) else {
        Log.error("Could not create graphical context for gradient image")
        return nil
    }

    context.drawLinearGradient(
        CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [startColor.cgColor, endColor.cgColor] as CFArray, locations: [0.0, 1.0])!,
        start: CGPoint(x: 0, y: 0), end: CGPoint(x: width, y: 0), options: [])

    guard let composedImage = context.makeImage() else {
        Log.error("Could not create composed image for gradient image")
        return nil
    }

    return NSImage(cgImage: composedImage, size: CGSize(width: width, height: height))
}

func createSolidImage(color: NSColor, width: CGFloat, height: CGFloat) -> NSImage? {
    // Choose notch radius for inverse rounding in the empty space below the bar.
    let notchRadius: CGFloat = height / 3
    // Place the solid bar in the upper part: its bottom edge is at y = notchRadius.
    let barRect = CGRect(x: 0, y: notchRadius, width: width, height: height)

    guard let context = createContext(width: width, height: height + notchRadius) else {
        Log.error("Could not create graphical context for solid color image")
        return nil
    }

    // 1. Draw the solid rectangular bar.
    context.setFillColor(color.cgColor)
    context.fill(barRect)

    // 2. Create and fill the bottom shape with inverse rounded corners.
    let bottomPath = CGMutablePath()
    // Start at the left bottom of the bar.
    bottomPath.move(to: CGPoint(x: 0, y: notchRadius))
    // Left edge down.
    bottomPath.addLine(to: CGPoint(x: 0, y: 0))
    // Bottom left corner: move right.
    bottomPath.addLine(to: CGPoint(x: notchRadius, y: 0))
    // Add a filled quarter circle for left inverse corner.
    bottomPath.addArc(
        center: CGPoint(x: notchRadius, y: 0),
        radius: notchRadius,
        startAngle: .pi,
        endAngle: .pi / 2,
        clockwise: true)
    // Line from the end of left arc to start of right arc.
    bottomPath.addLine(to: CGPoint(x: width - notchRadius, y: notchRadius))
    // Add quarter circle for right inverse corner.
    bottomPath.addArc(
        center: CGPoint(x: width - notchRadius, y: 0),
        radius: notchRadius,
        startAngle: .pi / 2,
        endAngle: 0,
        clockwise: true)
    // Right edge up.
    bottomPath.addLine(to: CGPoint(x: width, y: 0))
    bottomPath.addLine(to: CGPoint(x: width, y: notchRadius))
    // Close the path back to the bar’s bottom edge.
    bottomPath.closeSubpath()

    context.addPath(bottomPath)
    context.fillPath()

    guard let composedImage = context.makeImage() else {
        Log.error("Could not create composed image for solid color image")
        return nil
    }

    return NSImage(cgImage: composedImage, size: CGSize(width: width, height: height + notchRadius))
}

func combineImages(baseImage: NSImage, addedImage: NSImage) -> NSImage? {
    guard let context = createContext(width: baseImage.size.width, height: baseImage.size.height)
    else {
        Log.error("Could not create graphical context when merging images")
        return nil
    }

    guard let baseImageCGImage = baseImage.cgImage, let addedImageCGImage = addedImage.cgImage
    else {
        Log.error("Could not create cgImage when merging images")
        return nil
    }

    context.draw(
        baseImageCGImage,
        in: CGRect(x: 0, y: 0, width: baseImage.size.width, height: baseImage.size.height))
    context.draw(
        addedImageCGImage,
        in: CGRect(
            x: 0, y: baseImage.size.height - addedImage.size.height, width: addedImage.size.width,
            height: addedImage.size.height))

    guard let composedImage = context.makeImage() else {
        Log.error("Could not create composed image when merging with the wallpaper")
        return nil
    }

    return NSImage(cgImage: composedImage, size: baseImage.size)
}

func createContext(width: CGFloat, height: CGFloat) -> CGContext? {
    let imageWidth = Int(width)
    let imageHeight = Int(height)

    // set up CG parameters
    let bitsPerComponent: Int = 16
    let bytesPerPixel: Int = 8
    let bytesPerRow: Int = imageWidth * bytesPerPixel

    // Create a CGBitmapContext for drawing
    return CGContext(
        data: nil,
        width: imageWidth,
        height: imageHeight,
        bitsPerComponent: bitsPerComponent,
        bytesPerRow: bytesPerRow,
				space: CGColorSpaceCreateDeviceRGB(),
				bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
}

func colorName(_ color: NSColor) -> String {
    if #available(OSX 11.0, *) {
        return AXNameFromColor(color.cgColor)
    } else {
        return color.description
    }
}
