import SwiftUI

@main
struct UltraMirrorApp: App {
    init() {
        StreamRelay.shared.start()
        BackgroundKeepAlive.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
