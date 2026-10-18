import Foundation

public struct IsolationCheckResult: Identifiable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let appName: String
    public let originalDataDir: String
    public let profileDataDir: String
    public let originalFilesBeforeCount: Int
    public let originalFilesAfterCount: Int
    public let originalModifiedFiles: [String]
    public let profileCreatedFilesCount: Int
    public let isIsolated: Bool
    public let summary: String
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        appName: String,
        originalDataDir: String,
        profileDataDir: String,
        originalFilesBeforeCount: Int,
        originalFilesAfterCount: Int,
        originalModifiedFiles: [String],
        profileCreatedFilesCount: Int,
        isIsolated: Bool,
        summary: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.appName = appName
        self.originalDataDir = originalDataDir
        self.profileDataDir = profileDataDir
        self.originalFilesBeforeCount = originalFilesBeforeCount
        self.originalFilesAfterCount = originalFilesAfterCount
        self.originalModifiedFiles = originalModifiedFiles
        self.profileCreatedFilesCount = profileCreatedFilesCount
        self.isIsolated = isIsolated
        self.summary = summary
    }
}
