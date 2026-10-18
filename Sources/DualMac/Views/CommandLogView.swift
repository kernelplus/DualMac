import SwiftUI

public struct CommandLogView: View {
    @ObservedObject var commandRunner = CommandRunner.shared
    @State private var searchText = ""
    
    var filteredLogs: [CommandLogEntry] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return commandRunner.logs
        }
        return commandRunner.logs.filter {
            $0.fullCommandLine.localizedCaseInsensitiveContains(searchText) ||
            $0.output.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack {
                Text("In-App Shell Command Log")
                    .font(.headline)
                
                Spacer()
                
                TextField("Search logs...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                
                Button(action: {
                    let fullText = commandRunner.logs.map { "[\($0.timestamp)] \($0.fullCommandLine)\nOutput:\n\($0.output)\nExit: \($0.exitCode)\n" }.joined(separator: "\n---\n")
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(fullText, forType: .string)
                }) {
                    Label("Copy All", systemImage: "doc.on.doc")
                }
                
                Button(role: .destructive, action: {
                    commandRunner.clearLogs()
                }) {
                    Label("Clear", systemImage: "trash")
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Log list
            if filteredLogs.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "terminal")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No shell commands logged yet.")
                        .foregroundColor(.secondary)
                    Text("Every command executed by DualMac (codesign, open, cp, plutil, iconutil) will appear here.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredLogs) { entry in
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Duration: \(String(format: "%.3f", entry.duration))s")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button("Copy Command") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(entry.fullCommandLine, forType: .string)
                                }
                                .buttonStyle(.borderless)
                                .font(.caption)
                            }
                            
                            if !entry.output.isEmpty {
                                ScrollView(.horizontal, showsIndicators: true) {
                                    Text(entry.output)
                                        .font(.system(.caption, design: .monospaced))
                                        .padding(8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(NSColor.controlBackgroundColor))
                                        .cornerRadius(6)
                                }
                                .frame(maxHeight: 180)
                            } else {
                                Text("(No output / exit code \(entry.exitCode))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(entry.isSuccess ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            
                            Text(entry.timestamp, style: .time)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                            
                            Text(entry.fullCommandLine)
                                .font(.system(.callout, design: .monospaced))
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text("exit \(entry.exitCode)")
                                .font(.system(.caption2, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(entry.isSuccess ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                                .foregroundColor(entry.isSuccess ? .green : .red)
                                .cornerRadius(4)
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
    }
}
