import ActivityKit
import Foundation

struct MeshStatusAttributes: ActivityAttributes, Sendable {
    let deviceName: String

    struct ContentState: Codable, Hashable, Sendable {
        var isConnected: Bool
        var batteryPercent: Int?
        var packetsPerMinute: Int // Legacy field for backwards compatibility
        var unreadCount: Int
        var disconnectedDate: Date?
        
        var primaryStatValue: String?
        var primaryStatLabel: String?
        var primaryStatIcon: String?

        var antennaIconName: String {
            isConnected
                ? "antenna.radiowaves.left.and.right"
                : "antenna.radiowaves.left.and.right.slash"
        }
    }
}
