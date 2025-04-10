import SwiftUI

@main
struct GutendexBooksApp: App {
    init() {
        // Configure URLCache at app launch
        URLCache.shared = URLCache(
            memoryCapacity: 50_000_000,   // ~50 MB
            diskCapacity: 100_000_000,    // ~100 MB
            directory: nil
        )
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
} 