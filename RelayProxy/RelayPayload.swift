import Foundation

struct RelayPayload: Codable, Identifiable, Equatable {
    var id: String
    var input: String
    var callbackURL: String?
    var action: String?
    var source: String?
    var sourceBundleID: String?
    var sourceAppName: String?
    var shortcutName: String?
    var shortcutIcon: String?
    var shortcutEmoji: String?
    var shortcutColor: String?
    var callbackMode: String?
    var rawURL: String
    var parameters: [String: String]
    var timestamp: Date
    var consumedAt: Date?

    var isConsumed: Bool {
        consumedAt != nil
    }

    var displayShortcutName: String {
        shortcutName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? shortcutName! : "Automation"
    }

    var displaySourceName: String {
        if let sourceAppName, !sourceAppName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return sourceAppName
        }
        if let source, !source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return source
        }
        return sourceBundleID ?? "Unknown"
    }

    var displaySymbolName: String {
        let candidate = shortcutIcon?.trimmingCharacters(in: .whitespacesAndNewlines)
        return candidate?.isEmpty == false ? candidate! : "bolt.circle.fill"
    }
}

struct RelayPayloadResponse: Codable {
    var ok: Bool
    var payload: RelayPayload?
    var error: String?

    static func success(_ payload: RelayPayload) -> RelayPayloadResponse {
        RelayPayloadResponse(ok: true, payload: payload, error: nil)
    }

    static func failure(_ message: String) -> RelayPayloadResponse {
        RelayPayloadResponse(ok: false, payload: nil, error: message)
    }
}
