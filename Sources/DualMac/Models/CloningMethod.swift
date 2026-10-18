import Foundation

public enum CloningMethod: String, Codable, CaseIterable, Identifiable, Sendable {
    case bundleDuplicate = "bundle_duplicate"
    case electronDataDir = "electron_data_dir"
    case multiInstance = "multi_instance"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .bundleDuplicate:
            return "Method B: App Bundle Duplicate (Recommended)"
        case .electronDataDir:
            return "Method A: Profile Data Isolation"
        case .multiInstance:
            return "Method C: Multi-Instance Fallback"
        }
    }
    
    public var shortTitle: String {
        switch self {
        case .bundleDuplicate:
            return "Clone App Bundle (Distinct Dock Icon)"
        case .electronDataDir:
            return "Lightweight Data-Dir (Shared Icon)"
        case .multiInstance:
            return "Multi-Instance (open -n)"
        }
    }
    
    public var description: String {
        switch self {
        case .bundleDuplicate:
            return "Recommended. Creates an independent bundle in ~/Applications/DualMac with its own badged Dock icon, unique bundle ID, and isolated session."
        case .electronDataDir:
            return "Creates a lightweight launcher that shares the original app bundle. Note: macOS Dock groups this under the original app's icon without badge."
        case .multiInstance:
            return "Launches a new instance using 'open -n -a'. Works only if app natively allows multiple sessions."
        }
    }
    
    public var iconName: String {
        switch self {
        case .electronDataDir:
            return "bolt.shield.fill"
        case .bundleDuplicate:
            return "square.on.square.fill"
        case .multiInstance:
            return "arrow.triangle.branch"
        }
    }
}
