import Foundation
import AppKit

@MainActor
public final class AppScannerService: ObservableObject {
    public static let shared = AppScannerService()
    
    @Published public private(set) var installedApps: [InstalledApp] = []
    @Published public private(set) var isScanning: Bool = false
    
    private init() {}
    
    public func scan() async {
        guard !isScanning else { return }
        isScanning = true
        defer { isScanning = false }
        
        let scanned = await Task.detached(priority: .userInitiated) { () -> [InstalledApp] in
            let appDirs = [
                "/Applications",
                ("/Users" as NSString).appendingPathComponent("\(NSUserName())/Applications")
            ]
            
            var apps: [InstalledApp] = []
            let fm = FileManager.default
            
            for dir in appDirs {
                guard let contents = try? fm.contentsOfDirectory(atPath: dir) else { continue }
                for item in contents where item.hasSuffix(".app") {
                    let fullPath = "\(dir)/\(item)"
                    
                    // Skip DualMac itself and cloned apps directory
                    if item == "DualMac.app" || fullPath.contains("/DualMac/") {
                        continue
                    }
                    
                    let analysis = AppAnalyzerService.analyze(appPath: fullPath)
                    let icon = NSWorkspace.shared.icon(forFile: fullPath)
                    icon.size = NSSize(width: 64, height: 64)
                    
                    let app = InstalledApp(
                        id: analysis.bundleId.isEmpty ? fullPath : analysis.bundleId,
                        name: analysis.name,
                        path: fullPath,
                        bundleId: analysis.bundleId,
                        version: analysis.version,
                        icon: icon,
                        isElectron: analysis.isElectron,
                        isChromium: analysis.isChromium,
                        isAppleApp: analysis.isAppleApp,
                        hasMasReceipt: analysis.hasMasReceipt,
                        recommendedMethod: analysis.recommendedMethod,
                        warnings: analysis.warnings,
                        entitlements: analysis.entitlements
                    )
                    apps.append(app)
                }
            }
            
            return apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }.value
        
        self.installedApps = scanned
    }
}
