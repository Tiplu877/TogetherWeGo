import SwiftUI
import FirebaseCore

@main
struct MyApp: App {
    @State private var store = TripStore()
    @State private var auth: AuthViewModel

    init() {
        FirebaseApp.configure()                          // must run FIRST
        _auth = State(initialValue: AuthViewModel())     // now it's safe to use Firebase
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if auth.isSignedIn {
                    TripListView()
                } else {
                    AuthView()
                }
            }
            .environment(store)
            .environment(auth)
        }
    }
}
