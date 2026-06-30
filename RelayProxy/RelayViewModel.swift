import Foundation
import SwiftUI
import UIKit

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

        if let callbackURLString = payload.callbackURL,
           let callbackURL = URL(string: callbackURLString) {
            let delayMilliseconds = callbackDelayMilliseconds(from: payload.parameters)
            statusText = "Saved payload: \(payload.id). Returning in \(delayMilliseconds) ms."
            openCallback(callbackURL, afterMilliseconds: delayMilliseconds)
        } else {
            statusText = "Saved payload: \(payload.id)"
        }
    }

    func refresh() {
        latestPayload = PayloadStore.latest()
    }

    func clear() {
        PayloadStore.clear()
        latestPayload = nil
        statusText = "Cleared payload history."
    }

    private func callbackDelayMilliseconds(from parameters: [String: String]) -> Int {
        let keys = ["returnDelayMs", "return_delay_ms", "callbackDelayMs", "callback_delay_ms", "delay_ms"]
        for key in keys {
            if let value = parameters[key], let milliseconds = Int(value) {
                return min(max(milliseconds, 0), 5000)
            }
        }
        return 250
    }

    private func openCallback(_ callbackURL: URL, afterMilliseconds delayMilliseconds: Int) {
        Task { @MainActor in
            if delayMilliseconds > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delayMilliseconds) * 1_000_000)
            }
            UIApplication.shared.open(callbackURL, options: [:]) { [weak self] success in
                Task { @MainActor in
                    if success {
                        self?.statusText = "Returned to callback URL."
                    } else {
                        self?.statusText = "Saved payload, but failed to open callback URL."
                    }
                }
            }
        }
    }
}
