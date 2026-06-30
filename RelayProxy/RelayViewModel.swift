import Foundation
import SwiftUI

@MainActor
final class RelayViewModel: ObservableObject {
    @Published var latestPayload: RelayPayload?
    @Published var statusText: String

    init() {
        self.latestPayload = PayloadStore.latest()
        if let latestPayload {
            self.statusText = "Ready. Last payload: \(latestPayload.id)"
        } else {
            self.statusText = "Ready. No payload yet."
        }
    }

    func handle(url: URL) {
        let payload = RelayURLHandler.payload(from: url)
        PayloadStore.save(payload)
        latestPayload = payload
        statusText = "Saved payload: \(payload.id)"
    }

    func refresh() {
        latestPayload = PayloadStore.latest()
    }

    func clear() {
        PayloadStore.clear()
        latestPayload = nil
        statusText = "Cleared payload history."
    }
}
