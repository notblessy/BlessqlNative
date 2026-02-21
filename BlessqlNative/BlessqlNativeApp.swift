import SwiftUI
import SwiftData

@main
struct BlessqlNativeApp: App {
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup(id: "connection") {
            ConnectionView()
        }
        .modelContainer(for: Connection.self)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 700, height: 500)

        WindowGroup(id: "dashboard") {
            ContentView()
                .onDisappear {
                    openWindow(id: "connection")
                }
        }
        .defaultSize(width: 1200, height: 800)
    }
}
