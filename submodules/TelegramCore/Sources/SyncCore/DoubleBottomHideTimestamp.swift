import Foundation
import Postbox

public struct DoubleBottomHideTimestamp: Codable, Equatable {
    enum CodingKeys: String, CodingKey {
        case timestamp = "t"
    }

    public var timestamp: Int64
    
    public static var defaultValue: DoubleBottomHideTimestamp {
        return DoubleBottomHideTimestamp(timestamp: 0)
    }
    
    init(timestamp: Int64) {
        self.timestamp = timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.timestamp = try container.decode(Int64.self, forKey: .timestamp)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
    
        try container.encode(timestamp, forKey: .timestamp)
    }
    
    public static func ==(lhs: DoubleBottomHideTimestamp, rhs: DoubleBottomHideTimestamp) -> Bool {
        if lhs.timestamp != rhs.timestamp {
            return false
        }
        return true
    }
}
