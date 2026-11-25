import SwiftUI

@main
struct iTunesSearchApp: App {
    var body: some Scene {
        WindowGroup {
            Text(CompositionRoot.layers.joined(separator: " · "))
                .padding()
        }
    }
}
