import Foundation
import SwiftUI
import Combine

@MainActor
public final class CommandRunner: ObservableObject {
    public static let shared = CommandRunner()
    
    @Published public private(set) var logs: [CommandLogEntry] = []
    
    private init() {}
    
    public func clearLogs() {
        logs.removeAll()
    }
    
    /// Executes a command and logs it. Guards against unauthorized sudo usage.
    @discardableResult
    public func run(
        _ executable: String,
        arguments: [String] = [],
        currentDirectory: String? = nil,
        allowSudo: Bool = false
    ) async throws -> (exitCode: Int32, output: String) {
        // Enforce hard rule: Never execute sudo unless explicitly authorized
        if executable.contains("sudo") || arguments.contains(where: { $0.contains("sudo") }) {
            if !allowSudo {
                let errorMsg = "Command execution blocked: 'sudo' commands require explicit user confirmation."
                let entry = CommandLogEntry(
                    command: executable,
                    arguments: arguments,
                    exitCode: -1,
                    output: errorMsg,
                    duration: 0
                )
                logs.insert(entry, at: 0)
                throw NSError(domain: "DualMac.Security", code: 403, userInfo: [NSLocalizedDescriptionKey: errorMsg])
            }
        }
        
        let startTime = Date()
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        
        if let dir = currentDirectory {
            process.currentDirectoryURL = URL(fileURLWithPath: dir)
        }
        
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try process.run()
                    process.waitUntilExit()
                    
                    let stdoutData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                    let stderrData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    
                    let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
                    let stderr = String(data: stderrData, encoding: .utf8) ?? ""
                    
                    var combinedOutput = stdout
                    if !stderr.isEmpty {
                        if !combinedOutput.isEmpty {
                            combinedOutput += "\n"
                        }
                        combinedOutput += stderr
                    }
                    
                    let exitCode = process.terminationStatus
                    let duration = Date().timeIntervalSince(startTime)
                    
                    Task { @MainActor in
                        let entry = CommandLogEntry(
                            command: executable,
                            arguments: arguments,
                            exitCode: exitCode,
                            output: combinedOutput.trimmingCharacters(in: .whitespacesAndNewlines),
                            duration: duration
                        )
                        self.logs.insert(entry, at: 0)
                        continuation.resume(returning: (exitCode, combinedOutput))
                    }
                } catch {
                    let duration = Date().timeIntervalSince(startTime)
                    Task { @MainActor in
                        let entry = CommandLogEntry(
                            command: executable,
                            arguments: arguments,
                            exitCode: -1,
                            output: "Error: \(error.localizedDescription)",
                            duration: duration
                        )
                        self.logs.insert(entry, at: 0)
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}
