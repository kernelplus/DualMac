import SwiftUI

public struct AppDetailView: View {
    public let app: InstalledApp
    public let onProfileCreated: (DualProfile) -> Void
    
    @State private var showingCreateSheet = false
    
    public init(app: InstalledApp, onProfileCreated: @escaping (DualProfile) -> Void) {
        self.app = app
        self.onProfileCreated = onProfileCreated
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack(spacing: 20) {
                    Image(nsImage: app.icon)
                        .resizable()
                        .frame(width: 72, height: 72)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(app.bundleId)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            Text("v\(app.version)")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(4)
                            
                            if app.isElectron {
                                Text("Electron App")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.15))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            } else if app.isChromium {
                                Text("Chromium App")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.15))
                                    .foregroundColor(.green)
                                    .cornerRadius(4)
                            } else {
                                Text("Native macOS")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.purple.opacity(0.15))
                                    .foregroundColor(.purple)
                                    .cornerRadius(4)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showingCreateSheet = true
                    }) {
                        Label("Create Dual Profile", systemImage: "plus.square.fill.on.square.fill")
                            .font(.headline)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                .cornerRadius(10)
                
                // Recommended Method Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: app.recommendedMethod.iconName)
                            .font(.title3)
                            .foregroundColor(.accentColor)
                        Text("Recommended Strategy: \(app.recommendedMethod.title)")
                            .font(.headline)
                    }
                    Text(app.recommendedMethod.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.accentColor.opacity(0.08))
                .cornerRadius(8)
                
                // Warnings Section
                if !app.warnings.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Compatibility Analysis & Warnings")
                            .font(.headline)
                        
                        ForEach(app.warnings) { warning in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: warning.severity == .critical ? "xmark.octagon.fill" : (warning.severity == .warning ? "exclamationmark.triangle.fill" : "info.circle.fill"))
                                    .foregroundColor(warning.severity == .critical ? .red : (warning.severity == .warning ? .orange : .blue))
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(warning.title)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text(warning.message)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(warning.recommendation)
                                        .font(.caption2)
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                        }
                    }
                }
                
                // App Details / Paths
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bundle Details")
                        .font(.headline)
                    
                    Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                        GridRow {
                            Text("Path:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(app.path)
                                .font(.caption)
                                .textSelection(.enabled)
                        }
                        GridRow {
                            Text("MAS Receipt:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(app.hasMasReceipt ? "Yes (_MASReceipt present)" : "None")
                                .font(.caption)
                        }
                        if !app.entitlements.isEmpty {
                            GridRow(alignment: .top) {
                                Text("Entitlements:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(app.entitlements.joined(separator: ", "))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                .cornerRadius(8)
            }
            .padding()
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateProfileSheet(app: app) { profile in
                onProfileCreated(profile)
            }
        }
    }
}
