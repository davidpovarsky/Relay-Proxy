import SwiftUI

struct ContentView: View {
    @ObservedObject var model: RelayViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Status") {
                    Text(model.statusText)
                        .font(.body)
                    Text("Set a Shortcuts personal automation: When Relay Proxy is opened → Run Shortcut → Get Latest Relay Payload.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Latest Payload") {
                    if let payload = model.latestPayload {
                        LabeledContent("ID", value: payload.id)
                        LabeledContent("Action", value: payload.action ?? "")
                        LabeledContent("Source", value: payload.source ?? "")
                        LabeledContent("Consumed", value: payload.isConsumed ? "Yes" : "No")

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Input")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(payload.input.isEmpty ? "—" : payload.input)
                                .textSelection(.enabled)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Callback URL")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(payload.callbackURL ?? "—")
                                .font(.footnote)
                                .textSelection(.enabled)
                        }
                    } else {
                        ContentUnavailableView(
                            "No Payload",
                            systemImage: "tray",
                            description: Text("Open relay://run?input=Hello to save a payload.")
                        )
                    }
                }

                Section("URL Examples") {
                    Text("relay://run?input=Hello")
                        .font(.footnote.monospaced())
                        .textSelection(.enabled)
                    Text("relay://run?input=Hello&x-success=sourceapp%3A%2F%2Fcallback")
                        .font(.footnote.monospaced())
                        .textSelection(.enabled)
                }
            }
            .navigationTitle("Relay Proxy")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Refresh") {
                        model.refresh()
                    }
                    Button("Clear", role: .destructive) {
                        model.clear()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView(model: RelayViewModel())
}
