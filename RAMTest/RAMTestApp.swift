import SwiftUI

@main
struct RAMTestApp: App {
    @StateObject private var filler = MemoryFiller()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(filler)
        }
    }
}
