import Foundation

public struct CommandLogEntry: Identifiable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let command: String
    public let arguments: [String]
    public let exitCode: Int32
    public let output: String
    public let duration: TimeInterval
    
    public var isSuccess: Bool {
        exitCode == 0
    }
    
    public var fullCommandLine: String {
        ([command] + arguments.map { arg in
            if arg.contains(" ") || arg.contains("\"") {
                return "\"\(arg.replacingOccurrences(of: "\"", with: "\\\""))\""
            }
            return arg
        }).joined(separator: " ")
    }
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        command: String,
        arguments: [String] = [],
        exitCode: Int32 = 0,
        output: String = "",
        duration: TimeInterval = 0
    ) {
        self.id = id
        self.timestamp = timestamp
        self.command = command
        self.arguments = arguments
        self.exitCode = exitCode
        self.output = output
        self.duration = duration
    }
}
