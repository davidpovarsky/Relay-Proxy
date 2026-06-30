import Foundation

struct RelayPayload: Codable, Identifiable, Equatable {
    var id: String
    var input: String
    var callbackURL: String?
    var action: String?
    var source: String?
    var rawURL: String
    var parameters: [String: String]
    var timestamp: Date
    var consumedAt: Date?

    var isConsumed: Bool {
        consumedAt != nil
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
