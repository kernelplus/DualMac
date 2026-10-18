import Foundation
import AppKit

public struct InstalledApp: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let path: String
    public let bundleId: String
    public let version: String
    public let icon: NSImage
    public let isElectron: Bool
    public let isChromium: Bool
    public let isAppleApp: Bool
    public let hasMasReceipt: Bool
    public let recommendedMethod: CloningMethod
    public let warnings: [AppWarning]
    public let entitlements: [String]
    
    public init(
        id: String,
        name: String,
        path: String,
        bundleId: String,
        version: String,
        icon: NSImage,
        isElectron: Bool,
        isChromium: Bool,
        isAppleApp: Bool,
        hasMasReceipt: Bool,
        recommendedMethod: CloningMethod,
        warnings: [AppWarning] = [],
        entitlements: [String] = []
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.bundleId = bundleId
        self.version = version
        self.icon = icon
        self.isElectron = isElectron
        self.isChromium = isChromium
        self.isAppleApp = isAppleApp
        self.hasMasReceipt = hasMasReceipt
        self.recommendedMethod = recommendedMethod
        self.warnings = warnings
        self.entitlements = entitlements
    }
}
