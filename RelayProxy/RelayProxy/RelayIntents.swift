import AppIntents
import Foundation

enum RelayPayloadFormat: String, AppEnum {
    case json
    case input
    case callbackURL
    case id
    case action
    case rawURL

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Relay Payload Format")

    static var caseDisplayRepresentations: [RelayPayloadFormat: DisplayRepresentation] = [
        .json: "JSON",
        .input: "Input Text",
        .callbackURL: "Callback URL",
        .id: "Payload ID",
        .action: "Action",
        .rawURL: "Raw URL"
    ]
}

struct GetLatestRelayPayloadIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Latest Relay Payload"
    static var description = IntentDescription("Reads the latest deep-link payload saved by Relay Proxy.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Output Format", default: .json)
    var outputFormat: RelayPayloadFormat

    @Parameter(title: "Consume Payload", default: true)
    var consumePayload: Bool

    @Parameter(title: "Max Age Seconds", default: 20)
    var maxAgeSeconds: Int

    @Parameter(title: "Wait Milliseconds", default: 1200)
    var waitMilliseconds: Int

    init() {}

    init(outputFormat: RelayPayloadFormat = .json,
         consumePayload: Bool = true,
         maxAgeSeconds: Int = 20,
         waitMilliseconds: Int = 1200) {
        self.outputFormat = outputFormat
        self.consumePayload = consumePayload
        self.maxAgeSeconds = maxAgeSeconds
        self.waitMilliseconds = waitMilliseconds
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let maxAge = max(1, min(maxAgeSeconds, 300))
        let wait = max(0, min(waitMilliseconds, 5000))
        let startedAt = Date()
        let acceptableStart = startedAt.addingTimeInterval(-Double(maxAge))
        let deadline = startedAt.addingTimeInterval(TimeInterval(wait) / 1000.0)

        repeat {
            if let payload = PayloadStore.latest(),
               payload.consumedAt == nil,
               payload.timestamp >= acceptableStart,
               payload.timestamp.timeIntervalSinceNow >= -Double(maxAge) {
                let output = PayloadStore.output(for: payload, format: outputFormat)
                if consumePayload {
                    PayloadStore.markConsumed(id: payload.id)
                }
                return .result(value: output)
            }

            if Date() >= deadline { break }
            try await Task.sleep(nanoseconds: 100_000_000)
        } while true

        return .result(value: PayloadStore.noPayloadOutput())
    }
}

struct ClearRelayPayloadIntent: AppIntent {
    static var title: LocalizedStringResource = "Clear Relay Payloads"
    static var description = IntentDescription("Clears the saved Relay Proxy payload and local history.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        PayloadStore.clear()
        return .result(value: "Relay payloads cleared.")
    }
}

struct RelayProxyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetLatestRelayPayloadIntent(),
            phrases: [
                "Get relay payload in \(.applicationName)",
                "Read latest relay payload in \(.applicationName)"
            ],
            shortTitle: "Get Payload",
            systemImageName: "tray.and.arrow.down"
        )

        AppShortcut(
            intent: ClearRelayPayloadIntent(),
            phrases: [
                "Clear relay payloads in \(.applicationName)"
            ],
            shortTitle: "Clear Payloads",
            systemImageName: "trash"
        )
    }
}
