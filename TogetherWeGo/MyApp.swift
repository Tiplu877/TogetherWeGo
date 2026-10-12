import SwiftUI
import FirebaseCore

@main
struct MyApp: App {
    @State private var store = TripStore()
    @State private var auth: AuthViewModel
    @State private var router = DeepLinkRouter()

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
            .environment(store)
            .environment(auth)
            .environment(router)
            .onOpenURL { url in
                router.handle(url)
            }
        }
    }
}
