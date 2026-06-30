import Foundation
import SwiftUI

@MainActor
final class RelayViewModel: ObservableObject {
    @Published var latestPayload: RelayPayload?
    @Published var statusText: String

    init() {
        let storedPayload = PayloadStore.latest()
        self.latestPayload = storedPayload
        if let storedPayload {
            self.statusText = "Ready. Last payload: \(storedPayload.id)"
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
