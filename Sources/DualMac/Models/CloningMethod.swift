import Foundation

public enum CloningMethod: String, Codable, CaseIterable, Identifiable, Sendable {
    case electronDataDir = "electron_data_dir"
    case bundleDuplicate = "bundle_duplicate"
    case multiInstance = "multi_instance"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .electronDataDir:
            return "Method A: Profile Data Isolation"
        case .bundleDuplicate:
            return "Method B: App Bundle Duplicate"
        case .multiInstance:
            return "Method C: Multi-Instance Fallback"
        }
    }
    
    public var shortTitle: String {
        switch self {
        case .electronDataDir:
            return "Data Isolation (--user-data-dir)"
        case .bundleDuplicate:
            return "Clone App Bundle"
        case .multiInstance:
            return "Multi-Instance (open -n)"
        }
    }
    
    public var description: String {
        switch self {
        case .electronDataDir:
            return "Recommended for Electron & Chromium apps. Isolates data into a separate profile folder with zero bundle copying (saves 300MB–1.5GB)."
        case .bundleDuplicate:
            return "Duplicates the .app bundle to ~/Applications/DualMac, changes CFBundleIdentifier, removes DRM receipt, re-signs ad-hoc, and badges the icon."
        case .multiInstance:
            return "Launches a new instance using 'open -n -a' without duplicating files or passing custom arguments. Works only if app natively allows multiple sessions."
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
