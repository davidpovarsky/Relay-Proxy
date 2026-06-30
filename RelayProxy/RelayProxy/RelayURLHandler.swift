import Foundation

enum RelayURLHandler {
    static func payload(from url: URL) -> RelayPayload {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []

        var parameters: [String: String] = [:]
        for item in queryItems {
            parameters[item.name] = item.value ?? ""
        }

        let decodedBase64Payload = decodeBase64URL(parameters["payload_b64"])
        let payloadJSON = parameters["payload_json"]

        let input = firstValue(in: parameters, keys: [
            "input", "text", "q", "query", "body", "content", "payload"
        ]) ?? payloadJSON ?? decodedBase64Payload ?? ""

        let callbackURL = firstValue(in: parameters, keys: [
            "x-success", "x_success", "success", "callback", "return", "return_url", "returnURL"
        ])

        let action = parameters["action"] ?? components?.host ?? cleanPath(url.path)
        let source = parameters["source"] ?? parameters["x-source"] ?? parameters["x_source"]
        let id = parameters["id"] ?? UUID().uuidString

        if let decodedBase64Payload {
            parameters["payload_b64_decoded"] = decodedBase64Payload
        }

        return RelayPayload(
            id: id,
            input: input,
            callbackURL: callbackURL,
            action: action,
            source: source,
            rawURL: url.absoluteString,
            parameters: parameters,
            timestamp: Date(),
            consumedAt: nil
        )
    }

    private static func firstValue(in dictionary: [String: String], keys: [String]) -> String? {
        for key in keys {
            if let value = dictionary[key], !value.isEmpty {
                return value
            }
        }
        return nil
    }

    private static func cleanPath(_ path: String) -> String? {
        let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func decodeBase64URL(_ value: String?) -> String? {
        guard var base64 = value, !base64.isEmpty else { return nil }
        base64 = base64.replacingOccurrences(of: "-", with: "+")
        base64 = base64.replacingOccurrences(of: "_", with: "/")

        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }

        guard let data = Data(base64Encoded: base64) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
