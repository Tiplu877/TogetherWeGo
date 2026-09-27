import SwiftUI
import FirebaseCore

@main
struct MyApp: App {
    @State private var store = TripStore()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            TripListView()
                .environment(store)
        }
    }
}
