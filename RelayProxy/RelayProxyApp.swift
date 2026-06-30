import SwiftUI

@main
struct RelayProxyApp: App {
    @StateObject private var model = RelayViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .onOpenURL { url in
                    model.handle(url: url)
                }
        }
    }
}
