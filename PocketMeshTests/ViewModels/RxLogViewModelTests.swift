import Foundation
import Testing
@testable import PocketMesh
@testable import PocketMeshServices

@MainActor
struct RxLogViewModelTests {

    // MARK: - buildNodeNameMap

    @Test("Empty contacts produces empty map")
    func buildNodeNameMap_empty() {
        let map = RxLogViewModel.buildNodeNameMap(from: [])
        #expect(map.isEmpty)
    }

    @Test("Single contact generates entries for 1, 2, and 3-byte prefixes")
    func buildNodeNameMap_singleContact() {
        let key = Data([0xAA, 0xBB, 0xCC, 0xDD])
        let contact = makeContact(name: "Alice", publicKey: key)
        let map = RxLogViewModel.buildNodeNameMap(from: [contact])

        #expect(map[Data([0xAA])] == "Alice")
        #expect(map[Data([0xAA, 0xBB])] == "Alice")
        #expect(map[Data([0xAA, 0xBB, 0xCC])] == "Alice")
    }

    @Test("Two contacts with different first bytes resolve at all prefix lengths")
    func buildNodeNameMap_distinctPrefixes() {
        let contacts = [
            makeContact(name: "Alice", publicKey: Data([0xAA, 0xBB, 0xCC, 0xDD])),
            makeContact(name: "Bob", publicKey: Data([0x11, 0x22, 0x33, 0x44]))
        ]
        let map = RxLogViewModel.buildNodeNameMap(from: contacts)

        #expect(map[Data([0xAA])] == "Alice")
        #expect(map[Data([0x11])] == "Bob")
        #expect(map[Data([0xAA, 0xBB])] == "Alice")
        #expect(map[Data([0x11, 0x22])] == "Bob")
        #expect(map[Data([0xAA, 0xBB, 0xCC])] == "Alice")
        #expect(map[Data([0x11, 0x22, 0x33])] == "Bob")
    }

    @Test("Two contacts sharing first byte omit 1-byte entry but resolve at 2 and 3 bytes")
    func buildNodeNameMap_sharedFirstByte() {
        let contacts = [
            makeContact(name: "Alice", publicKey: Data([0xAA, 0xBB, 0xCC, 0xDD])),
            makeContact(name: "Bob", publicKey: Data([0xAA, 0x22, 0x33, 0x44]))
        ]
        let map = RxLogViewModel.buildNodeNameMap(from: contacts)

        // 1-byte prefix is ambiguous — should not be in the map
        #expect(map[Data([0xAA])] == nil)

        // 2-byte prefixes are unique
        #expect(map[Data([0xAA, 0xBB])] == "Alice")
        #expect(map[Data([0xAA, 0x22])] == "Bob")

        // 3-byte prefixes are unique
        #expect(map[Data([0xAA, 0xBB, 0xCC])] == "Alice")
        #expect(map[Data([0xAA, 0x22, 0x33])] == "Bob")
    }

    @Test("Two contacts sharing first two bytes omit 1 and 2-byte entries but resolve at 3 bytes")
    func buildNodeNameMap_sharedTwoBytes() {
        let contacts = [
            makeContact(name: "Alice", publicKey: Data([0xAA, 0xBB, 0xCC, 0xDD])),
            makeContact(name: "Bob", publicKey: Data([0xAA, 0xBB, 0x33, 0x44]))
        ]
        let map = RxLogViewModel.buildNodeNameMap(from: contacts)

        #expect(map[Data([0xAA])] == nil)
        #expect(map[Data([0xAA, 0xBB])] == nil)
        #expect(map[Data([0xAA, 0xBB, 0xCC])] == "Alice")
        #expect(map[Data([0xAA, 0xBB, 0x33])] == "Bob")
    }

    @Test("Contact with short public key only generates entries for available lengths")
    func buildNodeNameMap_shortKey() {
        let contacts = [
            makeContact(name: "Short", publicKey: Data([0xAA, 0xBB]))
        ]
        let map = RxLogViewModel.buildNodeNameMap(from: contacts)

        #expect(map[Data([0xAA])] == "Short")
        #expect(map[Data([0xAA, 0xBB])] == "Short")
        // 3-byte prefix not generated since key only has 2 bytes
        #expect(map[Data([0xAA, 0xBB])] == "Short")
        #expect(map.count == 2)
    }

    @Test("Nickname takes precedence over name via displayName")
    func buildNodeNameMap_nickname() {
        let contact = makeContact(name: "Alice Jones", publicKey: Data([0xAA, 0xBB, 0xCC, 0xDD]), nickname: "AJ")
        let map = RxLogViewModel.buildNodeNameMap(from: [contact])

        #expect(map[Data([0xAA])] == "AJ")
    }

    // MARK: - Helpers

    private func makeContact(
        name: String,
        publicKey: Data,
        nickname: String? = nil
    ) -> ContactDTO {
        ContactDTO(
            id: UUID(),
            deviceID: UUID(),
            publicKey: publicKey,
            name: name,
            typeRawValue: 0,
            flags: 0,
            outPathLength: 0,
            outPath: Data(),
            lastAdvertTimestamp: 0,
            latitude: 0,
            longitude: 0,
            lastModified: 0,
            nickname: nickname,
            isBlocked: false,
            isMuted: false,
            isFavorite: false,
            lastMessageDate: nil,
            unreadCount: 0,
            ocvPreset: nil,
            customOCVArrayString: nil
        )
    }
}
