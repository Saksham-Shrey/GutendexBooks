import SwiftUI

// Separate non-generic class to hold the static cache
final class ImageCache {
    static let shared = ImageCache()
    
    let cache = URLCache(
        memoryCapacity: 50_000_000, // ~50 MB memory space
        diskCapacity: 100_000_000,  // ~100 MB disk space
        directory: nil
    )
    
    private init() {}
}

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let scale: CGFloat
    private let transaction: Transaction
    private let content: (AsyncImagePhase) -> Content
    private let placeholder: () -> Placeholder
    @State private var imagePhase: AsyncImagePhase = .empty
    
    init(url: URL?,
         scale: CGFloat = 1.0,
         transaction: Transaction = Transaction(),
         @ViewBuilder content: @escaping (AsyncImagePhase) -> Content,
         @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.scale = scale
        self.transaction = transaction
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let url = url {
                content(imagePhase)
                    .onAppear {
                        loadImage(from: url)
                    }
                    .onChange(of: url) { _, newURL in
                        imagePhase = .empty
                        loadImage(from: newURL)
                    }
            } else {
                placeholder()
            }
        }
    }
    
    private func loadImage(from url: URL) {
        // Check if the image is in the cache
        let request = URLRequest(url: url)
        
        if let cachedResponse = ImageCache.shared.cache.cachedResponse(for: request),
           let image = UIImage(data: cachedResponse.data) {
            self.imagePhase = .success(Image(uiImage: image))
            return
        }
        
        // If not in cache, load it asynchronously
        Task(priority: .userInitiated) {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                // Store the result in cache
                if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                    let cachedResponse = CachedURLResponse(response: response, data: data)
                    ImageCache.shared.cache.storeCachedResponse(cachedResponse, for: request)
                }
                
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        withTransaction(transaction) {
                            self.imagePhase = .success(Image(uiImage: image))
                        }
                    }
                } else {
                    await MainActor.run {
                        withTransaction(transaction) {
                            self.imagePhase = .failure(URLError(.cannotDecodeContentData))
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    withTransaction(transaction) {
                        self.imagePhase = .failure(error)
                    }
                }
            }
        }
    }
}

// Extension to create a convenient placeholder usage
extension CachedAsyncImage where Placeholder == Image {
    init(url: URL?,
         scale: CGFloat = 1.0,
         transaction: Transaction = Transaction(),
         @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.url = url
        self.scale = scale
        self.transaction = transaction
        self.content = content
        self.placeholder = { Image(systemName: "book.closed") }
    }
} 
