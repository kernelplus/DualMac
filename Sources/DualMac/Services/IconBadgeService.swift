import Foundation
import AppKit

public enum IconBadgeService {
    
    private static var cachedDualBadge: NSImage? = {
        // Try loading from Bundle Resources
        if let resPath = Bundle.main.path(forResource: "DualBadge", ofType: "png"),
           let img = NSImage(contentsOfFile: resPath) {
            return img
        }
        // Try loading from local Resources directory
        let localPaths = [
            "Resources/DualBadge.png",
            "Sources/DualMac/Resources/DualBadge.png",
            ("/Users" as NSString).appendingPathComponent("\(NSUserName())/Documents/Dual App Mac/Resources/DualBadge.png")
        ]
        for p in localPaths {
            if FileManager.default.fileExists(atPath: p), let img = NSImage(contentsOfFile: p) {
                return img
            }
        }
        return nil
    }()
    
    /// Parses a hex color string like "#2563EB" into NSColor
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
        let badgeDiameter = targetSize * 0.42
        let margin = targetSize * 0.02
        let badgeRect = NSRect(
            x: targetSize - badgeDiameter - margin,
            y: margin,
            width: badgeDiameter,
            height: badgeDiameter
        )
        
        let ctx = NSGraphicsContext.current?.cgContext
        
        if badge.useDualIconBadge, let dualImg = cachedDualBadge {
            // Draw official Dual blue "D" badge image with drop shadow
            ctx?.saveGState()
            let shadowScale = max(targetSize / 1024.0, 0.1)
            ctx?.setShadow(
                offset: CGSize(width: -6.0 * shadowScale, height: 8.0 * shadowScale),
                blur: 18.0 * shadowScale,
                color: NSColor.black.withAlphaComponent(0.45).cgColor
            )
            dualImg.draw(in: badgeRect,
                         from: NSRect(origin: .zero, size: dualImg.size),
                         operation: .sourceOver,
                         fraction: 1.0)
            ctx?.restoreGState()
        } else {
            // Vector fallback for badge
            let cornerRadius = badgeDiameter * 0.28
            let badgePath = CGPath(roundedRect: NSRect(origin: .zero, size: badgeRect.size),
                                   cornerWidth: cornerRadius,
                                   cornerHeight: cornerRadius,
                                   transform: nil)
            
            ctx?.saveGState()
            ctx?.translateBy(x: badgeRect.origin.x, y: badgeRect.origin.y)
            ctx?.setShadow(offset: CGSize(width: -2, height: 4), blur: 8, color: NSColor.black.withAlphaComponent(0.40).cgColor)
            
            // Subtle white border
            ctx?.addPath(badgePath)
            ctx?.setFillColor(color(fromHex: badge.colorHex).cgColor)
            ctx?.fillPath()
            
            ctx?.setStrokeColor(NSColor.white.withAlphaComponent(0.9).cgColor)
            ctx?.setLineWidth(targetSize > 64 ? 2.5 : 1.5)
            ctx?.addPath(badgePath)
            ctx?.strokePath()
            
            // Draw label ("D" or custom label)
            let displayLabel = badge.label.isEmpty ? "D" : badge.label
            let fontSize = badgeDiameter * (displayLabel.count > 2 ? 0.38 : 0.56)
            let font = NSFont.systemFont(ofSize: fontSize, weight: .heavy)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.white,
                .paragraphStyle: paragraphStyle
            ]
            
            let str = NSAttributedString(string: displayLabel, attributes: attributes)
            let strSize = str.size()
            let strRect = NSRect(
                x: (badgeDiameter - strSize.width) / 2,
                y: (badgeDiameter - strSize.height) / 2,
                width: strSize.width,
                height: strSize.height
            )
            str.draw(in: strRect)
            ctx?.restoreGState()
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
        let fm = FileManager.default
        
        // Find best source icon: direct .icns from bundle resources if available
        var baseIcon: NSImage? = nil
        let infoPlistPath = "\(originalAppPath)/Contents/Info.plist"
        if let data = fm.contents(atPath: infoPlistPath),
           let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
           let iconFile = plist["CFBundleIconFile"] as? String {
            let finalIconName = iconFile.hasSuffix(".icns") ? iconFile : "\(iconFile).icns"
            let directIcnsPath = "\(originalAppPath)/Contents/Resources/\(finalIconName)"
            if fm.fileExists(atPath: directIcnsPath) {
                baseIcon = NSImage(contentsOfFile: directIcnsPath)
            }
        }
        let originalIcon = baseIcon ?? NSWorkspace.shared.icon(forFile: originalAppPath)
        originalIcon.size = NSSize(width: 1024, height: 1024)
        
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
