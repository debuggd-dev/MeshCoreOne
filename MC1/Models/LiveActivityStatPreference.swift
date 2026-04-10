import SwiftUI

public enum LiveActivityStatPreference: String, CaseIterable, Identifiable, Codable, Sendable {
    case packetsPerMinute = "Packets Per Minute"
    case lastHeardRepeater = "Last Repeater Heard"
    case totalNodes = "Total Nodes Found"
    
    public var id: String { rawValue }
}
