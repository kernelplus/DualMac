import SwiftUI

public struct DualProfilesView: View {
    @ObservedObject var profileStorage = ProfileStorageService.shared
    @ObservedObject var processMonitor = ProcessMonitorService.shared
    
    @State private var profileToDelete: DualProfile? = nil
    @State private var showingDeleteDialog = false
    
    @State private var profileToRename: DualProfile? = nil
    @State private var newProfileName: String = ""
    @State private var showingRenameDialog = false
    
    @State private var isolationResult: IsolationCheckResult? = nil
    @State private var showingIsolationDialog = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Dual Profiles")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(profileStorage.profiles.count) total · \(processMonitor.runningProfileIds.count) running")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            if profileStorage.profiles.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "square.on.square.dashed")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No Dual Profiles Created")
                        .font(.headline)
                    Text("Switch to 'Installed Apps' tab to create your first dual instance.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(profileStorage.profiles) { profile in
                    let isRunning = processMonitor.isProfileRunning(profile)
                    
                    HStack(spacing: 16) {
                        // Badged Icon
                        let baseIcon = NSWorkspace.shared.icon(forFile: profile.originalAppPath)
                        let badged = IconBadgeService.generateBadgedImage(
                            baseImage: baseIcon,
                            badge: profile.badgeConfig,
                            targetSize: 48
                        )
                        Image(nsImage: badged)
                            .resizable()
                            .frame(width: 44, height: 44)
                        
                        // Profile Info
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(profile.name)
                                    .font(.headline)
                                
                                Text(profile.originalAppName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                // Running status indicator
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(isRunning ? Color.green : Color.secondary.opacity(0.4))
                                        .frame(width: 7, height: 7)
                                    Text(isRunning ? "Running" : "Stopped")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(isRunning ? .green : .secondary)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(isRunning ? Color.green.opacity(0.12) : Color.secondary.opacity(0.1))
                                .cornerRadius(10)
                            }
                            
                            HStack(spacing: 12) {
                                Label(profile.method.shortTitle, systemImage: profile.method.iconName)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                if let launched = profile.lastLaunchedAt {
                                    Text("Last launched: \(launched, style: .time)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if let dataDir = profile.profileDataDir {
                                Text("Data: \(dataDir)")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                        
                        // Action Buttons
                        HStack(spacing: 10) {
                            // Verify isolation button
                            if profile.profileDataDir != nil {
                                Button(action: {
                                    verifyIsolation(for: profile)
                                }) {
                                    Image(systemName: "checkmark.shield")
                                }
                                .help("Verify Data Isolation (confirm original folder is untouched)")
                            }
                            
                            // Reveal in Finder
                            Button(action: {
                                revealProfile(profile)
                            }) {
                                Image(systemName: "folder")
                            }
                            .help("Reveal profile in Finder")
                            
                            // Rename
                            Button(action: {
                                profileToRename = profile
                                newProfileName = profile.name
                                showingRenameDialog = true
                            }) {
                                Image(systemName: "pencil")
                            }
                            .help("Rename profile")
                            
                            // Delete
                            Button(role: .destructive, action: {
                                profileToDelete = profile
                                showingDeleteDialog = true
                            }) {
                                Image(systemName: "trash")
                            }
                            .help("Delete profile")
                            
                            // Launch
                            Button(action: {
                                launchProfile(profile)
                            }) {
                                Label("Launch", systemImage: "play.fill")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .listStyle(.inset)
            }
        }
        // Delete Confirmation Dialog
        .confirmationDialog(
            "Delete Profile: \(profileToDelete?.name ?? "")?",
            isPresented: $showingDeleteDialog,
            titleVisibility: .visible
        ) {
            Button("Delete Profile & Data Folder", role: .destructive) {
                if let profile = profileToDelete {
                    profileStorage.deleteProfile(id: profile.id, deleteDataDirectory: true)
                }
            }
            
            Button("Delete Profile Only (Keep Data)") {
                if let profile = profileToDelete {
                    profileStorage.deleteProfile(id: profile.id, deleteDataDirectory: false)
                }
            }
            
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Would you also like to delete the profile's isolated data folder in ~/Library/Application Support/DualMac?")
        }
        // Rename Dialog
        .sheet(isPresented: $showingRenameDialog) {
            VStack(spacing: 16) {
                Text("Rename Profile")
                    .font(.headline)
                
                TextField("Profile Name", text: $newProfileName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 280)
                
                HStack {
                    Button("Cancel") {
                        showingRenameDialog = false
                    }
                    Button("Save") {
                        if var profile = profileToRename {
                            profile.name = newProfileName.trimmingCharacters(in: .whitespaces)
                            profileStorage.updateProfile(profile)
                        }
                        showingRenameDialog = false
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newProfileName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding()
            .frame(width: 320, height: 160)
        }
        // Isolation Verification Result Dialog
        .sheet(isPresented: $showingIsolationDialog) {
            if let result = isolationResult {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: result.isIsolated ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                            .font(.title)
                            .foregroundColor(result.isIsolated ? .green : .orange)
                        
                        Text(result.isIsolated ? "Data Isolation Confirmed!" : "Isolation Warning")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button("Close") {
                            showingIsolationDialog = false
                        }
                    }
                    
                    Text(result.summary)
                        .font(.body)
                        .foregroundColor(result.isIsolated ? .primary : .orange)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Original Folder: \(result.originalDataDir)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Original Files: \(result.originalFilesAfterCount) files (modifications detected: \(result.originalModifiedFiles.count))")
                            .font(.caption)
                            .foregroundColor(result.originalModifiedFiles.isEmpty ? .green : .red)
                        
                        if !result.originalModifiedFiles.isEmpty {
                            Text("Modified in original: \(result.originalModifiedFiles.joined(separator: ", "))")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                        
                        Text("Profile Folder: \(result.profileDataDir)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Profile Files: \(result.profileCreatedFilesCount) files created inside isolated profile")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    .padding(10)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                    
                    Spacer()
                }
                .padding()
                .frame(width: 480, height: 260)
            }
        }
    }
    
    private func launchProfile(_ profile: DualProfile) {
        Task {
            do {
                try await CloningEngine.launchProfile(profile)
            } catch {
                // Error logged in CommandRunner
            }
        }
    }
    
    private func revealProfile(_ profile: DualProfile) {
        if let clonePath = profile.cloneBundlePath, FileManager.default.fileExists(atPath: clonePath) {
            NSWorkspace.shared.selectFile(clonePath, inFileViewerRootedAtPath: "")
        } else if let dataDir = profile.profileDataDir, FileManager.default.fileExists(atPath: dataDir) {
            NSWorkspace.shared.selectFile(dataDir, inFileViewerRootedAtPath: "")
        }
    }
    
    private func verifyIsolation(for profile: DualProfile) {
        let result = CloningEngine.verifyIsolation(for: profile)
        self.isolationResult = result
        self.showingIsolationDialog = true
    }
}
