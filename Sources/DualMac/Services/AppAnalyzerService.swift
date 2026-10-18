import Foundation
import AppKit

public struct AppAnalysisResult: Sendable {
    public let bundleId: String
    public let name: String
    public let version: String
    public let executableName: String
    public let iconFileName: String?
    public let isElectron: Bool
    public let isChromium: Bool
    public let isAppleApp: Bool
    public let hasMasReceipt: Bool
    public let recommendedMethod: CloningMethod
    public let warnings: [AppWarning]
    public let entitlements: [String]
}

public enum AppAnalyzerService {
    
    public static func analyze(appPath: String) -> AppAnalysisResult {
        let fm = FileManager.default
        let infoPlistPath = "\(appPath)/Contents/Info.plist"
        
        var bundleId = ""
        var appName = (appPath as NSString).lastPathComponent.replacingOccurrences(of: ".app", with: "")
        var version = "1.0"
        var executableName = ""
        var iconFileName: String? = nil
        
        if let data = fm.contents(atPath: infoPlistPath),
           let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
            bundleId = plist["CFBundleIdentifier"] as? String ?? ""
            if let displayName = plist["CFBundleDisplayName"] as? String, !displayName.isEmpty {
                appName = displayName
            } else if let name = plist["CFBundleName"] as? String, !name.isEmpty {
                appName = name
            }
            version = plist["CFBundleShortVersionString"] as? String ?? plist["CFBundleVersion"] as? String ?? "1.0"
            executableName = plist["CFBundleExecutable"] as? String ?? ""
            iconFileName = plist["CFBundleIconFile"] as? String
        }
        
        // 1. Check for Electron Framework or app.asar
        let electronFramework = "\(appPath)/Contents/Frameworks/Electron Framework.framework"
        let appAsar = "\(appPath)/Contents/Resources/app.asar"
        let isElectron = fm.fileExists(atPath: electronFramework) || fm.fileExists(atPath: appAsar)
        
        // 2. Check for Chromium Frameworks
        let chromeFramework = "\(appPath)/Contents/Frameworks/Google Chrome Framework.framework"
        let cefFramework = "\(appPath)/Contents/Frameworks/Chromium Embedded Framework.framework"
        let chromiumFramework = "\(appPath)/Contents/Frameworks/Chromium Framework.framework"
        let isChromium = fm.fileExists(atPath: chromeFramework) || fm.fileExists(atPath: cefFramework) || fm.fileExists(atPath: chromiumFramework)
        
        // 3. Check for MAS Receipt
        let masReceiptPath = "\(appPath)/Contents/_MASReceipt"
        let hasMasReceipt = fm.fileExists(atPath: masReceiptPath)
        
        // 4. Check if Apple System App
        let isAppleApp = appPath.hasPrefix("/System/") || bundleId.hasPrefix("com.apple.")
        
        // 5. Inspect Code Signature & Entitlements
        var detectedEntitlements: [String] = []
        var warnings: [AppWarning] = []
        
        let pipe = Pipe()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        process.arguments = ["-d", "--entitlements", ":-", appPath]
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        var entData = Data()
        if let _ = try? process.run() {
            entData = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
        }
        if let entPlist = try? PropertyListSerialization.propertyList(from: entData, options: [], format: nil) as? [String: Any] {
            detectedEntitlements = Array(entPlist.keys)
            
            // Check Keychain access groups
            if let keychainGroups = entPlist["keychain-access-groups"] as? [String], !keychainGroups.isEmpty {
                warnings.append(.teamIdKeychain(groups: keychainGroups))
            }
            
            // Check Application groups
            if let appGroups = entPlist["com.apple.security.application-groups"] as? [String], !appGroups.isEmpty {
                warnings.append(.applicationGroups(groups: appGroups))
            }
        }
        
        // Check MAS receipt warning
        if hasMasReceipt {
            warnings.append(.masReceipt())
        }
        
        // Check Apple system app warning
        if isAppleApp {
            warnings.append(.appleSystemApp())
        }
        
        // Always include note that Method B clones do not auto-update
        warnings.append(.noAutoUpdates())
        
        // Determine recommended method: Bundle duplication is required for a distinct Dock icon,
        // distinct name, and independent Dock tile (including Electron and Chromium apps).
        let recommendedMethod: CloningMethod
        if isAppleApp {
            recommendedMethod = .multiInstance
        } else {
            recommendedMethod = .bundleDuplicate
        }
        
        return AppAnalysisResult(
            bundleId: bundleId,
            name: appName,
            version: version,
            executableName: executableName,
            iconFileName: iconFileName,
            isElectron: isElectron,
            isChromium: isChromium,
            isAppleApp: isAppleApp,
            hasMasReceipt: hasMasReceipt,
            recommendedMethod: recommendedMethod,
            warnings: warnings,
            entitlements: detectedEntitlements
        )
    }
}
