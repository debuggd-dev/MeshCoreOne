import CoreLocation
import Foundation
import PocketMeshServices

/// Resolves repeater collisions by proximity and recency.
enum RepeaterResolver {
    /// Match using a PathHop: exact public key match first, then hash bytes fallback.
    static func bestMatch(
        for hop: PathHop,
        in repeaters: [ContactDTO],
        userLocation: CLLocation?
    ) -> ContactDTO? {
        if let key = hop.publicKey,
           let exact = repeaters.first(where: { $0.publicKey == key }) {
            return exact
        }
        return bestMatch(for: hop.hashBytes, in: repeaters, userLocation: userLocation)
    }

    /// Match using hash bytes (1–3 byte prefix)
    static func bestMatch(
        for hashBytes: Data,
        in repeaters: [ContactDTO],
        userLocation: CLLocation?
    ) -> ContactDTO? {
        let prefixLen = hashBytes.count
        let candidates = repeaters.compactMap { contact -> (ContactDTO, Double?)? in
            guard contact.publicKey.prefix(prefixLen) == hashBytes else { return nil }

            let distance: Double?
            if let userLocation, contact.hasLocation {
                let repeaterLocation = CLLocation(latitude: contact.latitude, longitude: contact.longitude)
                distance = userLocation.distance(from: repeaterLocation)
            } else {
                distance = nil
            }

            return (contact, distance)
        }

        guard !candidates.isEmpty else { return nil }

        let sorted = candidates.sorted { lhs, rhs in
            switch (lhs.1, rhs.1) {
            case let (left?, right?):
                if left != right { return left < right }
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                break
            }

            if lhs.0.lastAdvertTimestamp != rhs.0.lastAdvertTimestamp {
                return lhs.0.lastAdvertTimestamp > rhs.0.lastAdvertTimestamp
            }

            if lhs.0.lastModified != rhs.0.lastModified {
                return lhs.0.lastModified > rhs.0.lastModified
            }

            return lhs.0.displayName.localizedStandardCompare(rhs.0.displayName) == .orderedAscending
        }

        return sorted.first?.0
    }

    // MARK: - DiscoveredNodeDTO Overloads

    /// Match using a PathHop: exact public key match first, then hash bytes fallback.
    static func bestMatch(
        for hop: PathHop,
        in nodes: [DiscoveredNodeDTO],
        userLocation: CLLocation?
    ) -> DiscoveredNodeDTO? {
        if let key = hop.publicKey,
           let exact = nodes.first(where: { $0.publicKey == key }) {
            return exact
        }
        return bestMatch(for: hop.hashBytes, in: nodes, userLocation: userLocation)
    }

    /// Match using hash bytes (1–3 byte prefix)
    static func bestMatch(
        for hashBytes: Data,
        in nodes: [DiscoveredNodeDTO],
        userLocation: CLLocation?
    ) -> DiscoveredNodeDTO? {
        let prefixLen = hashBytes.count
        let candidates = nodes.compactMap { node -> (DiscoveredNodeDTO, Double?)? in
            guard node.publicKey.prefix(prefixLen) == hashBytes else { return nil }

            let distance: Double?
            if let userLocation, node.hasLocation {
                let nodeLocation = CLLocation(latitude: node.latitude, longitude: node.longitude)
                distance = userLocation.distance(from: nodeLocation)
            } else {
                distance = nil
            }

            return (node, distance)
        }

        guard !candidates.isEmpty else { return nil }

        let sorted = candidates.sorted { lhs, rhs in
            switch (lhs.1, rhs.1) {
            case let (left?, right?):
                if left != right { return left < right }
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                break
            }

            if lhs.0.lastAdvertTimestamp != rhs.0.lastAdvertTimestamp {
                return lhs.0.lastAdvertTimestamp > rhs.0.lastAdvertTimestamp
            }

            if lhs.0.lastHeard != rhs.0.lastHeard {
                return lhs.0.lastHeard > rhs.0.lastHeard
            }

            return lhs.0.name.localizedStandardCompare(rhs.0.name) == .orderedAscending
        }

        return sorted.first?.0
    }
}
