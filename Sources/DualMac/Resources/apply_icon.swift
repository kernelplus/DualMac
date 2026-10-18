import Foundation
import AppKit

@main
struct ApplyIcon {
    static func main() {
        guard CommandLine.arguments.count >= 3 else {
            print("Usage: apply_icon <iconPath> <targetPath> [targetPath2...]")
            return
        }
        let iconPath = CommandLine.arguments[1]
        guard let img = NSImage(contentsOfFile: iconPath) else {
            print("Error: Could not load image from \(iconPath)")
            exit(1)
        }
        
        for i in 2..<CommandLine.arguments.count {
            let target = CommandLine.arguments[i]
            if FileManager.default.fileExists(atPath: target) {
                let ok = NSWorkspace.shared.setIcon(img, forFile: target, options: [])
                print("Applied icon to \(target): \(ok)")
            } else {
                print("Target not found: \(target)")
            }
        }
    }
}
