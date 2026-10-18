import SwiftUI
import AppKit

@main
struct DualMacApp: App {
    var body: some Scene {
        WindowGroup("DualMac") {
            MainView()
                .frame(minWidth: 920, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
    }
}
