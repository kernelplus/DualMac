import Foundation
import AppKit

@MainActor
public enum CloningEngine {
    
    private static var originalSnapshots: [UUID: [String: Date]] = [:]
    
    public static func dualAppsDirectory() -> String {
        let path = ("~/Applications/DualMac" as NSString).expandingTildeInPath
        try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        return path
    }
    
    public static func profilesDirectory() -> String {
        let path = ("~/Library/Application Support/DualMac/Profiles" as NSString).expandingTildeInPath
        try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        return path
    }
    
    private static func slugify(_ text: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return text.lowercased()
            .components(separatedBy: allowed.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }
    
    public static func createProfile(
        for app: InstalledApp,
        name: String,
        method: CloningMethod,
        badge: BadgeConfig
    ) async throws -> DualProfile {
        let fm = FileManager.default
        let profileSlug = slugify(name)
        let profileId = UUID()
        
        let originalDataDir = IsolationVerifierService.defaultDataDirectory(
            appName: app.name,
            bundleId: app.bundleId
        )
        // Record baseline snapshot of original data folder before profile creation/launch
        let baselineSnapshot = IsolationVerifierService.takeSnapshot(directoryPath: originalDataDir)
        originalSnapshots[profileId] = baselineSnapshot
        
        var profileDataDir: String? = nil
        var cloneBundlePath: String? = nil
        
        // ISOLATION FIX: For any Electron app, ALWAYS use --user-data-dir, even when using Method B.
        if method == .electronDataDir || app.isElectron || app.isChromium {
            let targetDir = "\(profilesDirectory())/\(app.bundleId)/\(profileSlug)"
            try fm.createDirectory(atPath: targetDir, withIntermediateDirectories: true)
            profileDataDir = targetDir
        }
        
        switch method {
        case .electronDataDir:
            // Method A: Create a lightweight launcher app in ~/Applications/DualMac
            let launcherAppName = "\(app.name) – \(name).app"
            let launcherAppPath = "\(dualAppsDirectory())/\(launcherAppName)"
            
            try? fm.removeItem(atPath: launcherAppPath)
            let macosDir = "\(launcherAppPath)/Contents/MacOS"
            let resourcesDir = "\(launcherAppPath)/Contents/Resources"
            try fm.createDirectory(atPath: macosDir, withIntermediateDirectories: true)
            try fm.createDirectory(atPath: resourcesDir, withIntermediateDirectories: true)
            
            // 1. Info.plist
            let launcherBundleId = "\(app.bundleId).dual.\(profileSlug).launcher"
            let infoPlistContent = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>CFBundleIdentifier</key>
                <string>\(launcherBundleId)</string>
                <key>CFBundleName</key>
                <string>\(app.name) – \(name)</string>
                <key>CFBundleDisplayName</key>
                <string>\(app.name) – \(name)</string>
                <key>CFBundleExecutable</key>
                <string>launcher</string>
                <key>CFBundleIconFile</key>
                <string>AppIcon.icns</string>
                <key>CFBundlePackageType</key>
                <string>APPL</string>
                <key>LSMinimumSystemVersion</key>
                <string>14.0</string>
            </dict>
            </plist>
            """
            try infoPlistContent.write(to: URL(fileURLWithPath: "\(launcherAppPath)/Contents/Info.plist"), atomically: true, encoding: .utf8)
            
            // 2. Badged Icon
            let icnsPath = "\(resourcesDir)/AppIcon.icns"
            try await IconBadgeService.createBadgedIcns(
                originalAppPath: app.path,
                badge: badge,
                outputIcnsPath: icnsPath
            )
            
            let badgedPreview = IconBadgeService.generateBadgedImage(
                baseImage: NSWorkspace.shared.icon(forFile: app.path),
                badge: badge,
                targetSize: 512
            )
            _ = NSWorkspace.shared.setIcon(badgedPreview, forFile: launcherAppPath, options: [])
            
            // 3. Compile Launcher Binary
            let cSource = """
            #include <stdlib.h>
            #include <unistd.h>
            int main(int argc, char *argv[]) {
                char *args[] = {
                    "/usr/bin/open",
                    "-n",
                    "-a",
                    "\(app.path)",
                    "--args",
                    "--user-data-dir=\(profileDataDir ?? "")",
                    NULL
                };
                execv("/usr/bin/open", args);
                return 0;
            }
            """
            let tempCSrc = "\(NSTemporaryDirectory())launcher_\(UUID().uuidString).c"
            try cSource.write(to: URL(fileURLWithPath: tempCSrc), atomically: true, encoding: .utf8)
            let launcherBin = "\(macosDir)/launcher"
            try await CommandRunner.shared.run("/usr/bin/clang", arguments: [tempCSrc, "-o", launcherBin])
            try? fm.removeItem(atPath: tempCSrc)
            
            // 4. Code Sign & Register
            try await CommandRunner.shared.run("/usr/bin/codesign", arguments: ["--force", "--sign", "-", launcherAppPath])
            let lsregister = "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
            if fm.fileExists(atPath: lsregister) {
                _ = try? await CommandRunner.shared.run(lsregister, arguments: ["-f", launcherAppPath])
            }
            _ = try? await CommandRunner.shared.run("/usr/bin/touch", arguments: [launcherAppPath])
            
            cloneBundlePath = launcherAppPath
            
        case .bundleDuplicate:
            // Method B: Full bundle duplication into ~/Applications/DualMac
            let cloneAppName = "\(app.name) – \(name).app"
            let targetBundlePath = "\(dualAppsDirectory())/\(cloneAppName)"
            
            try? fm.removeItem(atPath: targetBundlePath)
            
            // Copy bundle safely (Hard Rule: original in /Applications is NEVER modified)
            try await CommandRunner.shared.run("/bin/cp", arguments: ["-R", "-p", app.path, targetBundlePath])
            
            // Remove MAS receipt if present
            let masReceipt = "\(targetBundlePath)/Contents/_MASReceipt"
            if fm.fileExists(atPath: masReceipt) {
                try? fm.removeItem(atPath: masReceipt)
            }
            
            // Modify Info.plist
            let infoPlist = "\(targetBundlePath)/Contents/Info.plist"
            let newBundleId = "\(app.bundleId).dual.\(profileSlug)"
            let newDisplayName = "\(app.name) – \(name)"
            
            try await CommandRunner.shared.run("/usr/bin/plutil", arguments: ["-replace", "CFBundleIdentifier", "-string", newBundleId, infoPlist])
            try await CommandRunner.shared.run("/usr/bin/plutil", arguments: ["-replace", "CFBundleDisplayName", "-string", newDisplayName, infoPlist])
            
            // For non-Electron apps, we also update CFBundleName.
            // For Electron / Chromium apps, Electron dynamically locates its helper processes via CFBundleName
            // ("<CFBundleName> Helper.app"). Keeping CFBundleName as the base name prevents Electron from failing
            // with "[FATAL:electron_main_delegate_mac.mm:66] Unable to find helper app", while CFBundleDisplayName
            // provides the full "App – Dual" name in Finder and the Dock.
            if !app.isElectron && !app.isChromium {
                try await CommandRunner.shared.run("/usr/bin/plutil", arguments: ["-replace", "CFBundleName", "-string", newDisplayName, infoPlist])
            }
            
            // Remove CFBundleIconName and Assets.car if present:
            // On macOS 11+, apps with CFBundleIconName and Assets.car ignore CFBundleIconFile (.icns)
            // and load the unbadged icon from the compiled catalog. Removing CFBundleIconName and Assets.car
            // ensures macOS loads the newly badged .icns file.
            _ = try? await CommandRunner.shared.run("/usr/bin/plutil", arguments: ["-remove", "CFBundleIconName", infoPlist])
            let assetsCar = "\(targetBundlePath)/Contents/Resources/Assets.car"
            if fm.fileExists(atPath: assetsCar) {
                try? fm.removeItem(atPath: assetsCar)
            }
            
            // Badge app icon
            let analysis = AppAnalyzerService.analyze(appPath: app.path)
            let iconFileName = analysis.iconFileName ?? "AppIcon.icns"
            let finalIconName = iconFileName.hasSuffix(".icns") ? iconFileName : "\(iconFileName).icns"
            let targetIcns = "\(targetBundlePath)/Contents/Resources/\(finalIconName)"
            
            _ = try? await CommandRunner.shared.run("/usr/bin/plutil", arguments: ["-replace", "CFBundleIconFile", "-string", finalIconName, infoPlist])
            
            try await IconBadgeService.createBadgedIcns(
                originalAppPath: app.path,
                badge: badge,
                outputIcnsPath: targetIcns
            )
            
            let badgedClonePreview = IconBadgeService.generateBadgedImage(
                baseImage: NSWorkspace.shared.icon(forFile: app.path),
                badge: badge,
                targetSize: 512
            )
            _ = NSWorkspace.shared.setIcon(badgedClonePreview, forFile: targetBundlePath, options: [])
            
            // Clear quarantine attribute
            try await CommandRunner.shared.run("/usr/bin/xattr", arguments: ["-cr", targetBundlePath])
            
            // Re-sign ad-hoc
            try await CommandRunner.shared.run("/usr/bin/codesign", arguments: ["--force", "--deep", "--sign", "-", targetBundlePath])
            
            // Register with LaunchServices
            let lsregister = "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
            if fm.fileExists(atPath: lsregister) {
                _ = try? await CommandRunner.shared.run(lsregister, arguments: ["-f", targetBundlePath])
            }
            _ = try? await CommandRunner.shared.run("/usr/bin/touch", arguments: [targetBundlePath])
            
            cloneBundlePath = targetBundlePath
            
        case .multiInstance:
            // Method C: Multi-instance fallback
            cloneBundlePath = nil
        }
        
        let profile = DualProfile(
            id: profileId,
            name: name,
            originalAppPath: app.path,
            originalAppName: app.name,
            originalBundleId: app.bundleId,
            method: method,
            isElectron: app.isElectron || app.isChromium,
            profileDataDir: profileDataDir,
            cloneBundlePath: cloneBundlePath,
            badgeConfig: badge,
            createdAt: Date(),
            lastLaunchedAt: nil
        )
        
        ProfileStorageService.shared.addProfile(profile)
        return profile
    }
    
    public static func launchProfile(_ profile: DualProfile) async throws {
        var args: [String] = ["-n"]
        
        let targetApp: String
        if let clonePath = profile.cloneBundlePath, FileManager.default.fileExists(atPath: clonePath) {
            targetApp = clonePath
        } else {
            targetApp = profile.originalAppPath
        }
        
        args.append(contentsOf: ["-a", targetApp])
        
        if let profileDir = profile.profileDataDir, (profile.isElectron || profile.method == .electronDataDir) {
            args.append(contentsOf: ["--args", "--user-data-dir=\(profileDir)"])
        }
        
        try await CommandRunner.shared.run("/usr/bin/open", arguments: args)
        
        var updated = profile
        updated.lastLaunchedAt = Date()
        ProfileStorageService.shared.updateProfile(updated)
        
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await ProcessMonitorService.shared.updateRunningStatus()
        }
    }
    
    public static func verifyIsolation(for profile: DualProfile) -> IsolationCheckResult? {
        guard let profileDir = profile.profileDataDir else { return nil }
        let originalDir = IsolationVerifierService.defaultDataDirectory(
            appName: profile.originalAppName,
            bundleId: profile.originalBundleId
        )
        let baseline = originalSnapshots[profile.id] ?? [:]
        return IsolationVerifierService.verifyIsolation(
            appName: profile.originalAppName,
            originalDir: originalDir,
            originalSnapshotBefore: baseline,
            profileDir: profileDir
        )
    }
}
