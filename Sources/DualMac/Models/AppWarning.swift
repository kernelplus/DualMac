import Foundation

public struct AppWarning: Identifiable, Codable, Hashable, Sendable {
    public enum Severity: String, Codable, Sendable {
        case info
        case warning
        case critical
    }
    
    public let id: String
    public let title: String
    public let message: String
    public let severity: Severity
    public let recommendation: String
    
    public init(id: String, title: String, message: String, severity: Severity, recommendation: String) {
        self.id = id
        self.title = title
        self.message = message
        self.severity = severity
        self.recommendation = recommendation
    }
    
    public static func masReceipt() -> AppWarning {
        AppWarning(
            id: "mas_receipt",
            title: "Mac App Store App Detected",
            message: "This application contains a Mac App Store receipt (_MASReceipt). Ad-hoc re-signed clones cannot validate Apple ID receipts and will fail to receive App Store updates.",
            severity: .warning,
            recommendation: "DualMac will strip the _MASReceipt during cloning, but direct downloads from the developer's website work more reliably than Mac App Store versions."
        )
    }
    
    public static func appleSystemApp() -> AppWarning {
        AppWarning(
            id: "system_app",
            title: "Apple System Application",
            message: "This app is located on Apple's read-only Signed System Volume and protected by System Integrity Protection (SIP). Modifying or duplicating system apps is blocked.",
            severity: .critical,
            recommendation: "Duplicating Apple system apps is not supported."
        )
    }
    
    public static func teamIdKeychain(groups: [String]) -> AppWarning {
        AppWarning(
            id: "team_id_keychain",
            title: "Apple Team ID Keychain / Entitlements",
            message: "This app uses Apple Team ID-scoped Keychain access groups (\(groups.joined(separator: ", "))). Ad-hoc code signing cannot retain the Apple Developer Team ID.",
            severity: .warning,
            recommendation: "Cloned instances will not have access to passwords or tokens stored in the original app's keychain and cannot sync credentials."
        )
    }
    
    public static func applicationGroups(groups: [String]) -> AppWarning {
        AppWarning(
            id: "app_groups",
            title: "Application Groups Detected",
            message: "App groups (\(groups.joined(separator: ", "))) require matching Developer Team signatures. Helper processes may fail to communicate if entitlements are stripped.",
            severity: .info,
            recommendation: "If the clone experiences communication issues between its helper processes, Method A is preferred."
        )
    }
    
    public static func noAutoUpdates() -> AppWarning {
        AppWarning(
            id: "no_auto_updates",
            title: "Method B Clones Do Not Auto-Update",
            message: "Duplicated .app bundles in ~/Applications/DualMac are independent static copies with modified bundle identifiers. When the original application updates, the clone will remain on this version.",
            severity: .info,
            recommendation: "To update a Method B clone in the future, delete it and recreate it from the newly updated original app."
        )
    }
    
    public static func hardenedRuntime() -> AppWarning {
        AppWarning(
            id: "hardened_runtime",
            title: "Hardened Runtime & Anti-Tamper",
            message: "This app is signed with Hardened Runtime and library validation. If it performs internal signature or CDHash integrity verification, ad-hoc copies may abort on launch.",
            severity: .warning,
            recommendation: "Test with Method A or launch via fallback if internal tamper detection prevents Method B."
        )
    }
}
