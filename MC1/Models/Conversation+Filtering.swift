import Foundation

extension Array where Element == Conversation {
    /// Filters conversations by category and search text
    /// - Parameters:
    ///   - filter: Filter category
    ///   - searchText: Search string to match against display names
    ///   - matchingMessageConversationIDs: Optional set of conversation IDs that contain matching messages
    /// - Returns: Filtered array of conversations
    func filtered(by filter: ChatFilter, searchText: String, matchingMessageConversationIDs: Set<UUID>? = nil) -> [Conversation] {
        // When searching, ignore the selected filter and search all conversations
        if !searchText.isEmpty {
            return self.filter { conversation in
                conversation.displayName.localizedStandardContains(searchText) ||
                (matchingMessageConversationIDs?.contains(conversation.id) == true)
            }
        }

        switch filter {
        case .all:
            return self
        case .unread:
            return self.filter { $0.unreadCount > 0 && !$0.isMuted }
        case .directMessages:
            return self.filter {
                if case .direct = $0 { return true }
                return false
            }
        case .channels:
            return self.filter {
                if case .channel = $0 { return true }
                if case .room = $0 { return true }
                return false
            }
        }
    }
}
