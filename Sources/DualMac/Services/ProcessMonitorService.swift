import Foundation
import AppKit
import Combine

@MainActor
public final class ProcessMonitorService: ObservableObject {
    public static let shared = ProcessMonitorService()
    
    @Published public private(set) var runningProfileIds: Set<UUID> = []
    
    private var timer: Timer?
    private var isChecking = false
    
    private init() {
        startMonitoring()
    }
    
    public func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.updateRunningStatus()
            }
        }
    }
    
    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    public func isProfileRunning(_ profile: DualProfile) -> Bool {
        runningProfileIds.contains(profile.id)
    }
    
    public func updateRunningStatus() async {
        guard !isChecking else { return }
        let profiles = ProfileStorageService.shared.profiles
        guard !profiles.isEmpty else {
            runningProfileIds.removeAll()
            return
        }
        
        isChecking = true
        defer { isChecking = false }
        
        // Run process inspection entirely in background to never block the main UI thread
        let runningIds = await Task.detached(priority: .utility) { () -> Set<UUID> in
            var activeIds = Set<UUID>()
            
            // Check in-memory running applications first
            let runningApps = NSWorkspace.shared.runningApplications
            let runningBundlePaths = Set(runningApps.compactMap { $0.bundleURL?.path })
            
            for profile in profiles {
                // 1. If clone bundle path matches a running app
                if let clonePath = profile.cloneBundlePath, !clonePath.isEmpty {
                    if runningBundlePaths.contains(clonePath) {
                        activeIds.insert(profile.id)
                        continue
                    }
                }
                
                // 2. If profile data dir is specified, check with pgrep -q
                if let profileDir = profile.profileDataDir, !profileDir.isEmpty {
                    let proc = Process()
                    proc.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
                    proc.arguments = ["-q", "-f", profileDir]
                    proc.standardOutput = Pipe()
                    proc.standardError = Pipe()
                    
                    do {
                        try proc.run()
                        proc.waitUntilExit()
                        if proc.terminationStatus == 0 {
                            activeIds.insert(profile.id)
                        }
                    } catch {
                        // Ignore
                    }
                }
            }
            return activeIds
        }.value
        
        self.runningProfileIds = runningIds
    }
}
