import SwiftUI

@main
struct FocusAppApp: App {
    @StateObject private var timerStore = FocusTimerStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(timerStore)
        }
    }
}
