import Foundation

public struct BadgeConfig: Codable, Hashable, Sendable {
    public var label: String
    public var colorHex: String
    public var shape: String // "circle" or "roundedRectangle"
    public var position: String // "bottomRight" or "topRight"
    
    public init(
        label: String = "2",
        colorHex: String = "#FF9500", // Apple System Orange default
        shape: String = "circle",
        position: String = "bottomRight"
    ) {
        self.label = label
        self.colorHex = colorHex
        self.shape = shape
        self.position = position
    }
    
    public static let presetColors: [String] = [
        "#007AFF", // Blue
        "#FF9500", // Orange
        "#AF52DE", // Purple
        "#34C759", // Green
        "#FF2D55", // Pink
        "#5856D6", // Indigo
        "#00C7BE", // Mint
        "#FF3B30"  // Red
    ]
}
