import SwiftUI

public enum NavigationSection: String, CaseIterable, Identifiable {
    case apps = "Installed Apps"
    case profiles = "Dual Profiles"
    case logs = "Activity Logs"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .apps:
            return "square.grid.2x2.fill"
        case .profiles:
            return "square.on.square.fill"
        case .logs:
            return "terminal.fill"
        }
    }
}

public struct MainView: View {
    @State private var selectedSection: NavigationSection = .apps
    @ObservedObject var scanner = AppScannerService.shared
    @ObservedObject var profileStorage = ProfileStorageService.shared
    @ObservedObject var commandRunner = CommandRunner.shared
    @ObservedObject var processMonitor = ProcessMonitorService.shared
    
    public init() {}
    
    public var body: some View {
        NavigationSplitView {
            List(NavigationSection.allCases, selection: $selectedSection) { section in
                NavigationLink(value: section) {
                    HStack {
                        Label(section.rawValue, systemImage: section.iconName)
                        Spacer()
                        
                        switch section {
                        case .apps:
                            Text("\(scanner.installedApps.count)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        case .profiles:
                            HStack(spacing: 4) {
                                if !processMonitor.runningProfileIds.isEmpty {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 6, height: 6)
                                }
                                Text("\(profileStorage.profiles.count)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        case .logs:
                            Text("\(commandRunner.logs.count)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 260)
        } detail: {
            switch selectedSection {
            case .apps:
                AppCatalogView { createdProfile in
                    selectedSection = .profiles
                }
            case .profiles:
                DualProfilesView()
            case .logs:
                CommandLogView()
            }
        }
        .task {
            if scanner.installedApps.isEmpty {
                await scanner.scan()
            }
        }
    }
}
