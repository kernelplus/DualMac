import Foundation
import Combine

@MainActor
public final class ProfileStorageService: ObservableObject {
    public static let shared = ProfileStorageService()
    
    @Published public private(set) var profiles: [DualProfile] = []
    
    private let storagePath: String
    
    private init() {
        let appSupport = ("~/Library/Application Support/DualMac" as NSString).expandingTildeInPath
        self.storagePath = "\(appSupport)/profiles.json"
        
        try? FileManager.default.createDirectory(atPath: appSupport, withIntermediateDirectories: true)
        load()
    }
    
    public func load() {
        let fm = FileManager.default
        guard fm.fileExists(atPath: storagePath),
              let data = fm.contents(atPath: storagePath),
              let loaded = try? JSONDecoder().decode([DualProfile].self, from: data) else {
            return
        }
        self.profiles = loaded
    }
    
    public func save() {
        guard let data = try? JSONEncoder().encode(profiles) else { return }
        try? data.write(to: URL(fileURLWithPath: storagePath))
    }
    
    public func addProfile(_ profile: DualProfile) {
        profiles.removeAll { $0.id == profile.id }
        profiles.append(profile)
        save()
    }
    
    public func updateProfile(_ profile: DualProfile) {
        if let idx = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[idx] = profile
            save()
        }
    }
    
    public func deleteProfile(id: UUID, deleteDataDirectory: Bool) {
        guard let profile = profiles.first(where: { $0.id == id }) else { return }
        let fm = FileManager.default
        
        // Remove cloned bundle if it exists in ~/Applications/DualMac
        if let clonePath = profile.cloneBundlePath, fm.fileExists(atPath: clonePath) {
            // Safety check: only delete if inside DualMac folder
            if clonePath.contains("/DualMac/") {
                try? fm.removeItem(atPath: clonePath)
            }
        }
        
        // Remove profile data directory if requested
        if deleteDataDirectory, let dataDir = profile.profileDataDir, fm.fileExists(atPath: dataDir) {
            if dataDir.contains("/DualMac/Profiles/") {
                try? fm.removeItem(atPath: dataDir)
            }
        }
        
        profiles.removeAll { $0.id == id }
        save()
    }
}
