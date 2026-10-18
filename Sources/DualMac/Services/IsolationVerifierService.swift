import Foundation

public enum IsolationVerifierService {
    
    /// Resolves the default Application Support directory for an app based on product name or bundle ID
    public static func defaultDataDirectory(appName: String, bundleId: String) -> String {
        let appSupport = ("~/Library/Application Support" as NSString).expandingTildeInPath
        let productDir = "\(appSupport)/\(appName)"
        let bundleDir = "\(appSupport)/\(bundleId)"
        
        let fm = FileManager.default
        if fm.fileExists(atPath: productDir) {
            return productDir
        } else if fm.fileExists(atPath: bundleDir) {
            return bundleDir
        }
        return productDir
    }
    
    /// Takes a recursive snapshot of file relative paths and modification dates
    public static func takeSnapshot(directoryPath: String) -> [String: Date] {
        let fm = FileManager.default
        var snapshot: [String: Date] = [:]
        
        guard fm.fileExists(atPath: directoryPath),
              let enumerator = fm.enumerator(
                at: URL(fileURLWithPath: directoryPath),
                includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
                options: [.skipsHiddenFiles]
              ) else {
            return snapshot
        }
        
        let baseLength = directoryPath.count
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .contentModificationDateKey]),
                  resourceValues.isRegularFile == true,
                  let modDate = resourceValues.contentModificationDate else {
                continue
            }
            
            let fullPath = fileURL.path
            let relativePath = String(fullPath.dropFirst(baseLength))
            snapshot[relativePath] = modDate
        }
        
        return snapshot
    }
    
    /// Compares before & after snapshots of original dir, and verifies profile dir population
    public static func verifyIsolation(
        appName: String,
        originalDir: String,
        originalSnapshotBefore: [String: Date],
        profileDir: String
    ) -> IsolationCheckResult {
        let snapshotAfter = takeSnapshot(directoryPath: originalDir)
        var modifiedOrNewFiles: [String] = []
        
        for (file, dateAfter) in snapshotAfter {
            if let dateBefore = originalSnapshotBefore[file] {
                // If modified by more than 1 second
                if dateAfter.timeIntervalSince(dateBefore) > 1.0 {
                    modifiedOrNewFiles.append(file)
                }
            } else {
                modifiedOrNewFiles.append("NEW: \(file)")
            }
        }
        
        let profileSnapshot = takeSnapshot(directoryPath: profileDir)
        let profileFilesCount = profileSnapshot.count
        
        let isIsolated = modifiedOrNewFiles.isEmpty && profileFilesCount > 0
        let summary: String
        if isIsolated {
            summary = "PASS: Perfect isolation. Original folder had 0 modifications. Profile folder populated with \(profileFilesCount) files."
        } else if !modifiedOrNewFiles.isEmpty {
            summary = "FAIL: Original data folder was modified (\(modifiedOrNewFiles.count) files changed/created: \(modifiedOrNewFiles.prefix(3).joined(separator: ", ")))."
        } else {
            summary = "PENDING: Profile folder has not yet written files (\(profileFilesCount) files found)."
        }
        
        return IsolationCheckResult(
            appName: appName,
            originalDataDir: originalDir,
            profileDataDir: profileDir,
            originalFilesBeforeCount: originalSnapshotBefore.count,
            originalFilesAfterCount: snapshotAfter.count,
            originalModifiedFiles: modifiedOrNewFiles,
            profileCreatedFilesCount: profileFilesCount,
            isIsolated: isIsolated,
            summary: summary
        )
    }
}
