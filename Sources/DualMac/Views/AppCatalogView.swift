import SwiftUI

public struct AppCatalogView: View {
    @ObservedObject var scanner = AppScannerService.shared
    @State private var searchText: String = ""
    @State private var selectedFilter: AppFilter = .all
    @State private var selectedAppId: String? = nil
    
    public let onProfileCreated: (DualProfile) -> Void
    
    public enum AppFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case electronChromium = "Electron / Chromium"
        case native = "Native"
        case withWarnings = "With Warnings"
        
        public var id: String { rawValue }
    }
    
    public init(onProfileCreated: @escaping (DualProfile) -> Void) {
        self.onProfileCreated = onProfileCreated
    }
    
    var filteredApps: [InstalledApp] {
        scanner.installedApps.filter { app in
            let matchesSearch = searchText.isEmpty ||
                app.name.localizedCaseInsensitiveContains(searchText) ||
                app.bundleId.localizedCaseInsensitiveContains(searchText)
            
            guard matchesSearch else { return false }
            
            switch selectedFilter {
            case .all:
                return true
            case .electronChromium:
                return app.isElectron || app.isChromium
            case .native:
                return !app.isElectron && !app.isChromium
            case .withWarnings:
                return !app.warnings.isEmpty
            }
        }
    }
    
    var selectedApp: InstalledApp? {
        scanner.installedApps.first { $0.id == selectedAppId }
    }
    
    public var body: some View {
        HSplitView {
            // Left list
            VStack(spacing: 0) {
                // Search and Filter Bar
                VStack(spacing: 8) {
                    HStack {
                        TextField("Search installed apps...", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                        
                        Button(action: {
                            Task {
                                await scanner.scan()
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .help("Rescan Applications folders")
                    }
                    
                    Picker("", selection: $selectedFilter) {
                        ForEach(AppFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(10)
                .background(Color(NSColor.windowBackgroundColor))
                
                Divider()
                
                if scanner.isScanning {
                    VStack(spacing: 12) {
                        Spacer()
                        ProgressView("Scanning Applications...")
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredApps.isEmpty {
                    VStack(spacing: 10) {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No matching apps found")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredApps, selection: $selectedAppId) { app in
                        HStack(spacing: 12) {
                            Image(nsImage: app.icon)
                                .resizable()
                                .frame(width: 32, height: 32)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(app.name)
                                    .font(.headline)
                                Text(app.bundleId)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            if app.isElectron {
                                Text("Electron")
                                    .font(.system(size: 10, weight: .semibold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.15))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            } else if app.isChromium {
                                Text("Chromium")
                                    .font(.system(size: 10, weight: .semibold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.15))
                                    .foregroundColor(.green)
                                    .cornerRadius(4)
                            }
                            
                            if app.hasMasReceipt {
                                Image(systemName: "cart.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .help("Mac App Store app (_MASReceipt present)")
                            }
                        }
                        .padding(.vertical, 2)
                        .tag(app.id)
                    }
                    .listStyle(.inset)
                }
            }
            .frame(minWidth: 320, idealWidth: 360, maxWidth: 450)
            
            // Right detail
            if let app = selectedApp {
                AppDetailView(app: app) { profile in
                    onProfileCreated(profile)
                }
                .frame(minWidth: 450)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "macwindow.on.rectangle")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Select an app to view details and create a clone")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            if selectedAppId == nil, let first = scanner.installedApps.first {
                selectedAppId = first.id
            }
        }
    }
}
