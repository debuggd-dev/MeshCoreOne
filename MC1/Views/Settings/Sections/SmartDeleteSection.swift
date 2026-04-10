import SwiftUI

/// Settings section for Smart Delete (proactive device storage management)
struct SmartDeleteSection: View {
    @Environment(\.appState) private var appState
    @AppStorage("smartDeleteEnabled") private var isEnabled = false

    var body: some View {
        Section {
            Toggle(isOn: $isEnabled) {
                Text("Smart Delete")
            }
        } footer: {
            Text("Automatically deletes stale repeaters from the device to make space for new contacts when storage is full. Deleted nodes remain visible on the map.")
        }
    }
}

#Preview {
    Form {
        SmartDeleteSection()
    }
}
