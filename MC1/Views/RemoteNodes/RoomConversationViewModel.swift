import SwiftUI
import MC1Services

/// ViewModel for room conversation operations
@Observable
@MainActor
final class RoomConversationViewModel {

    // MARK: - Properties

    /// Current room session
    var session: RemoteNodeSessionDTO?

    /// Room messages
    var messages: [RoomMessageDTO] = []

    /// Loading state
    var isLoading = false

    /// Whether data has been loaded at least once (prevents empty state flash)
    var hasLoadedOnce = false

    /// Error message if any
    var errorMessage: String?

    /// Message text being composed
    var composingText = ""

    /// Whether a message is being sent
    var isSending = false

    // MARK: - Dependencies

    private var roomServerService: RoomServerService?
    private var dataStore: DataStore?
    private var syncCoordinator: SyncCoordinator?
    private var notificationService: NotificationService?

    // MARK: - Initialization

    init() {}

    /// Configure with services from AppState
    func configure(appState: AppState) {
        self.roomServerService = appState.services?.roomServerService
        self.dataStore = appState.services?.dataStore
        self.syncCoordinator = appState.syncCoordinator
        self.notificationService = appState.services?.notificationService
    }

    /// Number of messages to fetch per page
    let pageSize = 200

    /// Whether more messages exist beyond what's loaded
    var hasMoreMessages = true

    /// Current pagination offset
    private var currentOffset = 0

    // MARK: - Messages

    /// Load initial messages for the current session
    func loadMessages(for session: RemoteNodeSessionDTO) async {
        guard let roomServerService else { return }

        self.session = session
        isLoading = true
        errorMessage = nil
        currentOffset = 0
        hasMoreMessages = true

        do {
            let fetchedMessages = try await roomServerService.fetchMessages(sessionID: session.id, limit: pageSize, offset: 0)
            messages = fetchedMessages
            currentOffset = fetchedMessages.count
            hasMoreMessages = fetchedMessages.count == pageSize

            // Clear unread count and update badge
            try await roomServerService.markAsRead(sessionID: session.id)
            await notificationService?.updateBadgeCount()
            syncCoordinator?.notifyConversationsChanged()
        } catch {
            errorMessage = error.localizedDescription
        }

        hasLoadedOnce = true
        isLoading = false
    }

    /// Load older messages (pagination)
    func loadOlderMessages() async {
        guard let roomServerService, let session = session, hasMoreMessages, !isLoading else { return }
        
        do {
            let olderMessages = try await roomServerService.fetchMessages(sessionID: session.id, limit: pageSize, offset: currentOffset)
            
            // Filter duplicates
            let existingIDs = Set(messages.map(\.id))
            let uniqueOlder = olderMessages.filter { !existingIDs.contains($0.id) }
            
            // Prepend to messages
            messages.insert(contentsOf: uniqueOlder, at: 0)
            currentOffset += olderMessages.count
            hasMoreMessages = olderMessages.count == pageSize
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Optimistically append a message if not already present.
    /// Called synchronously before async reload to ensure ChatTableView
    /// sees the new count immediately for unread tracking.
    func appendMessageIfNew(_ message: RoomMessageDTO) {
        guard !messages.contains(where: { $0.id == message.id }) else { return }
        messages.append(message)
    }

    /// Send a message to the current room
    func sendMessage(text: String) async {
        guard let session,
              let roomServerService,
              !text.isEmpty else {
            composingText = text
            return
        }

        isSending = true
        errorMessage = nil

        do {
            let message = try await roomServerService.postMessage(sessionID: session.id, text: text)

            // Add to local array
            messages.append(message)
        } catch {
            errorMessage = error.localizedDescription
        }

        isSending = false
    }

    /// Refresh messages for current session
    func refreshMessages() async {
        guard let session else { return }
        await loadMessages(for: session)
    }

    /// Refresh session state from database
    func refreshSession() async {
        guard let session, let dataStore else { return }

        if let updated = try? await dataStore.fetchRemoteNodeSession(id: session.id) {
            self.session = updated
        }
    }

    /// Handle message event and update if relevant to current session
    func handleEvent(_ event: MessageEvent) async {
        guard let session else { return }

        switch event {
        case .roomMessageStatusUpdated(let messageID):
            if messages.contains(where: { $0.id == messageID }) {
                await loadMessages(for: session)
            }

        case .roomMessageFailed(let messageID):
            if messages.contains(where: { $0.id == messageID }) {
                await loadMessages(for: session)
            }

        default:
            break
        }
    }

    /// Retry sending a failed room message
    func retryMessage(id: UUID) async {
        guard let roomServerService else { return }

        do {
            let updatedMessage = try await roomServerService.retryMessage(id: id)
            // Update local array
            if let index = messages.firstIndex(where: { $0.id == id }) {
                messages[index] = updatedMessage
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Timestamp Helpers

    /// Time gap (in seconds) that breaks message grouping for timestamps.
    static let messageGroupingGapSeconds = 300

    /// Determines if a timestamp should be shown for a message at the given index.
    /// Shows timestamp for first message or when there's a gap > 5 minutes.
    static func shouldShowTimestamp(at index: Int, in messages: [RoomMessageDTO]) -> Bool {
        guard index > 0 else { return true }

        let currentMessage = messages[index]
        let previousMessage = messages[index - 1]

        let gap = abs(Int(currentMessage.timestamp) - Int(previousMessage.timestamp))
        return gap > messageGroupingGapSeconds
    }
}
