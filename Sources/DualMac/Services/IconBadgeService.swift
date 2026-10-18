import Foundation
import AppKit

public enum IconBadgeService {
    
    /// Parses a hex color string like "#FF9500" into NSColor
    public static func color(fromHex hex: String) -> NSColor {
        var cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanHex.hasPrefix("#") {
            cleanHex.removeFirst()
        }
        
        var rgbValue: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&rgbValue)
        
        let r = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgbValue & 0x0000FF) / 255.0
        
        return NSColor(calibratedRed: r, green: g, blue: b, alpha: 1.0)
    }
    
    /// Generates an in-memory preview NSImage with the specified badge
    public static func generateBadgedImage(baseImage: NSImage, badge: BadgeConfig, targetSize: CGFloat = 128) -> NSImage {
        let size = NSSize(width: targetSize, height: targetSize)
        let badgedImage = NSImage(size: size)
        
        badgedImage.lockFocus()
        
        // 1. Draw base icon
        baseImage.draw(in: NSRect(origin: .zero, size: size),
                       from: NSRect(origin: .zero, size: baseImage.size),
                       operation: .copy,
                       fraction: 1.0)
        
        // 2. Draw badge in bottom right corner
        let badgeDiameter = targetSize * 0.40
        let margin = targetSize * 0.04
        let badgeRect = NSRect(
            x: targetSize - badgeDiameter - margin,
            y: margin,
            width: badgeDiameter,
            height: badgeDiameter
        )
        
        // Draw white border for high contrast
        let borderPath: NSBezierPath
        if badge.shape == "roundedRectangle" {
            borderPath = NSBezierPath(roundedRect: badgeRect.insetBy(dx: -1.5, dy: -1.5), xRadius: badgeDiameter * 0.25, yRadius: badgeDiameter * 0.25)
        } else {
            borderPath = NSBezierPath(ovalIn: badgeRect.insetBy(dx: -1.5, dy: -1.5))
        }
        NSColor.white.withAlphaComponent(0.9).setStroke()
        borderPath.lineWidth = targetSize > 64 ? 3.0 : 1.5
        borderPath.stroke()
        
        // Draw badge background
        let fillPath: NSBezierPath
        if badge.shape == "roundedRectangle" {
            fillPath = NSBezierPath(roundedRect: badgeRect, xRadius: badgeDiameter * 0.25, yRadius: badgeDiameter * 0.25)
        } else {
            fillPath = NSBezierPath(ovalIn: badgeRect)
        }
        color(fromHex: badge.colorHex).setFill()
        fillPath.fill()
        
        // Draw badge label
        if !badge.label.isEmpty {
            let fontSize = badgeDiameter * (badge.label.count > 2 ? 0.40 : 0.55)
            let font = NSFont.boldSystemFont(ofSize: fontSize)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.white,
                .paragraphStyle: paragraphStyle
            ]
            
            let str = NSAttributedString(string: badge.label, attributes: attributes)
            let strSize = str.size()
            let strRect = NSRect(
                x: badgeRect.midX - strSize.width / 2,
                y: badgeRect.midY - strSize.height / 2 + (targetSize > 64 ? 1 : 0),
                width: strSize.width,
                height: strSize.height
            )
            str.draw(in: strRect)
        }
        
        badgedImage.unlockFocus()
        return badgedImage
    }
    
    /// Creates a complete .icns file with badges at all standard resolutions
    public static func createBadgedIcns(
        originalAppPath: String,
        badge: BadgeConfig,
        outputIcnsPath: String
    ) async throws {
        let originalIcon = NSWorkspace.shared.icon(forFile: originalAppPath)
        let fm = FileManager.default
        let tempDir = "\(NSTemporaryDirectory())DualMac_icon_\(UUID().uuidString).iconset"
        
        try fm.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        defer {
            try? fm.removeItem(atPath: tempDir)
        }
        
        let sizes: [(points: CGFloat, scale: CGFloat, name: String)] = [
            (16, 1, "icon_16x16.png"),
            (16, 2, "icon_16x16@2x.png"),
            (32, 1, "icon_32x32.png"),
            (32, 2, "icon_32x32@2x.png"),
            (128, 1, "icon_128x128.png"),
            (128, 2, "icon_128x128@2x.png"),
            (256, 1, "icon_256x256.png"),
            (256, 2, "icon_256x256@2x.png"),
            (512, 1, "icon_512x512.png"),
            (512, 2, "icon_512x512@2x.png")
        ]
        
        for item in sizes {
            let pixelSize = item.points * item.scale
            let badged = generateBadgedImage(baseImage: originalIcon, badge: badge, targetSize: pixelSize)
            
            guard let tiffData = badged.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let pngData = bitmap.representation(using: .png, properties: [:]) else {
                continue
            }
            
            let filePath = "\(tempDir)/\(item.name)"
            try pngData.write(to: URL(fileURLWithPath: filePath))
        }
        
        // Execute iconutil to compile into .icns
        try await CommandRunner.shared.run("/usr/bin/iconutil", arguments: ["-c", "icns", tempDir, "-o", outputIcnsPath])
    }
}
