import Foundation

public struct DualProfile: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public let originalAppPath: String
    public let originalAppName: String
    public let originalBundleId: String
    public var method: CloningMethod
    public let isElectron: Bool
    public var profileDataDir: String?
    public var cloneBundlePath: String?
    public var badgeConfig: BadgeConfig
    public let createdAt: Date
    public var lastLaunchedAt: Date?
    
    public init(
        id: UUID = UUID(),
        name: String,
        originalAppPath: String,
        originalAppName: String,
        originalBundleId: String,
        method: CloningMethod,
        isElectron: Bool,
        profileDataDir: String? = nil,
        cloneBundlePath: String? = nil,
        badgeConfig: BadgeConfig = BadgeConfig(),
        createdAt: Date = Date(),
        lastLaunchedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.originalAppPath = originalAppPath
        self.originalAppName = originalAppName
        self.originalBundleId = originalBundleId
        self.method = method
        self.isElectron = isElectron
        self.profileDataDir = profileDataDir
        self.cloneBundlePath = cloneBundlePath
        self.badgeConfig = badgeConfig
        self.createdAt = createdAt
        self.lastLaunchedAt = lastLaunchedAt
    }
}
