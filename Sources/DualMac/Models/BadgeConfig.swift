import Foundation

public struct BadgeConfig: Codable, Hashable, Sendable {
    public var label: String
    public var colorHex: String
    public var shape: String // "circle" or "roundedRectangle"
    public var position: String // "bottomRight" or "topRight"
    public var useDualIconBadge: Bool
    
    enum CodingKeys: String, CodingKey {
        case label, colorHex, shape, position, useDualIconBadge
    }
    
    public init(
        label: String = "D",
        colorHex: String = "#2563EB", // Vibrant Royal Blue matching Dual badge
        shape: String = "roundedRectangle",
        position: String = "bottomRight",
        useDualIconBadge: Bool = true
    ) {
        self.label = label
        self.colorHex = colorHex
        self.shape = shape
        self.position = position
        self.useDualIconBadge = useDualIconBadge
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.label = try container.decodeIfPresent(String.self, forKey: .label) ?? "D"
        self.colorHex = try container.decodeIfPresent(String.self, forKey: .colorHex) ?? "#2563EB"
        self.shape = try container.decodeIfPresent(String.self, forKey: .shape) ?? "roundedRectangle"
        self.position = try container.decodeIfPresent(String.self, forKey: .position) ?? "bottomRight"
        self.useDualIconBadge = try container.decodeIfPresent(Bool.self, forKey: .useDualIconBadge) ?? true
    }
    
    public static let presetColors: [String] = [
        "#2563EB", // Dual Blue (Official)
        "#007AFF", // System Blue
        "#FF9500", // Orange
        "#AF52DE", // Purple
        "#34C759", // Green
        "#FF2D55", // Pink
        "#5856D6", // Indigo
        "#00C7BE", // Mint
        "#FF3B30"  // Red
    ]
}
