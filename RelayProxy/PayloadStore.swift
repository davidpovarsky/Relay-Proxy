import Foundation

enum PayloadStore {
    private static let latestPayloadKey = "RelayProxy.latestPayload"
    private static let historyKey = "RelayProxy.payloadHistory"
    private static let historyLimit = 50

    private static var defaults: UserDefaults {
        UserDefaults.standard
    }

    static func save(_ payload: RelayPayload) {
        var freshPayload = payload
        freshPayload.consumedAt = nil
        saveLatest(freshPayload)

        var items = history()
        items.removeAll { $0.id == freshPayload.id }
        items.insert(freshPayload, at: 0)
        if items.count > historyLimit {
            items = Array(items.prefix(historyLimit))
        }
        saveHistory(items)
    }

    static func latest() -> RelayPayload? {
        guard let data = defaults.data(forKey: latestPayloadKey) else { return nil }
        return try? decoder.decode(RelayPayload.self, from: data)
    }

    static func history() -> [RelayPayload] {
        guard let data = defaults.data(forKey: historyKey) else { return [] }
        return (try? decoder.decode([RelayPayload].self, from: data)) ?? []
    }

    static func markConsumed(id: String) {
        let consumedAt = Date()

        if var latestPayload = latest(), latestPayload.id == id {
            latestPayload.consumedAt = consumedAt
            saveLatest(latestPayload)
        }

        var items = history()
        for index in items.indices where items[index].id == id {
            items[index].consumedAt = consumedAt
        }
        saveHistory(items)
    }

    static func clear() {
        defaults.removeObject(forKey: latestPayloadKey)
        defaults.removeObject(forKey: historyKey)
    }

    static func output(for payload: RelayPayload, format: RelayPayloadFormat) -> String {
        switch format {
        case .json:
            return jsonString(RelayPayloadResponse.success(payload))
        case .input:
            return payload.input
        case .callbackURL:
            return payload.callbackURL ?? ""
        case .id:
            return payload.id
        case .action:
            return payload.action ?? ""
        case .rawURL:
            return payload.rawURL
        }
    }

    static func noPayloadOutput() -> String {
        jsonString(RelayPayloadResponse.failure("No fresh unconsumed relay payload was found."))
    }

    static func jsonString<T: Encodable>(_ value: T) -> String {
        do {
            let data = try encoder.encode(value)
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            return "{\"ok\":false,\"error\":\"JSON encoding failed\"}"
        }
    }

    private static func saveLatest(_ payload: RelayPayload) {
        guard let data = try? encoder.encode(payload) else { return }
        defaults.set(data, forKey: latestPayloadKey)
    }

    private static func saveHistory(_ items: [RelayPayload]) {
        guard let data = try? encoder.encode(items) else { return }
        defaults.set(data, forKey: historyKey)
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
