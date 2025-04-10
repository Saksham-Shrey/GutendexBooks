import Foundation

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case decodingError(Error)
    case cachingError(Error)
}

actor BooksAPIService {
    private let baseURL = "https://gutendex.com/books"
    private let cache = BookCache.shared
    
    func fetchBooks(page: String? = nil, useCache: Bool = true) async throws -> BooksResponse {
        let urlString = page ?? baseURL
        
        // Check cache for first page
        if useCache && page == nil {
            if let cachedResponse = try? await cache.getCachedBooks() {
                return cachedResponse
            }
        }
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw APIError.invalidResponse
            }
            
            do {
                let decoder = JSONDecoder()
                let booksResponse = try decoder.decode(BooksResponse.self, from: data)
                
                // Save to cache if this is the first page
                if page == nil {
                    Task {
                        try await cache.cacheBooks(booksResponse)
                    }
                }
                
                return booksResponse
            } catch {
                throw APIError.decodingError(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    func fetchBookDetails(id: Int) async throws -> Book {
        // Check cache first
        if let cachedBook = try? await cache.getCachedBookDetails(id: id) {
            return cachedBook
        }
        
        let urlString = "\(baseURL)/\(id)"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw APIError.invalidResponse
            }
            
            do {
                let decoder = JSONDecoder()
                let book = try decoder.decode(Book.self, from: data)
                
                // Cache the book details
                Task {
                    try await cache.cacheBookDetails(book)
                }
                
                return book
            } catch {
                throw APIError.decodingError(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    func searchBooks(parameters: BookSearchParameters) async throws -> BooksResponse {
        var components = URLComponents(string: baseURL)
        components?.queryItems = parameters.toQueryItems()
        
        guard let url = components?.url else {
            throw APIError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw APIError.invalidResponse
            }
            
            do {
                let decoder = JSONDecoder()
                let booksResponse = try decoder.decode(BooksResponse.self, from: data)
                return booksResponse
            } catch {
                throw APIError.decodingError(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
}

// MARK: - Book Cache
actor BookCache {
    static let shared = BookCache()
    
    private let fileManager = FileManager.default
    private var cachesDirectory: URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("books_cache", isDirectory: true)
    }
    
    private init() {
        createCacheDirectoryIfNeeded()
    }
    
    private nonisolated func createCacheDirectoryIfNeeded() {
        // Using a local copy of cachesDirectory since 'self.cachesDirectory' is actor-isolated
        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("books_cache", isDirectory: true)
            
        if !FileManager.default.fileExists(atPath: cachesDir.path) {
            do {
                try FileManager.default.createDirectory(at: cachesDir, withIntermediateDirectories: true)
            } catch {
                print("Failed to create cache directory: \(error)")
            }
        }
    }
    
    func cacheBooks(_ response: BooksResponse) async throws {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(response)
            let fileURL = cachesDirectory.appendingPathComponent("books_list.json")
            try data.write(to: fileURL)
        } catch {
            throw APIError.cachingError(error)
        }
    }
    
    func getCachedBooks() async throws -> BooksResponse? {
        let fileURL = cachesDirectory.appendingPathComponent("books_list.json")
        
        if !fileManager.fileExists(atPath: fileURL.path) {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            return try decoder.decode(BooksResponse.self, from: data)
        } catch {
            throw APIError.cachingError(error)
        }
    }
    
    func cacheBookDetails(_ book: Book) async throws {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(book)
            let fileURL = cachesDirectory.appendingPathComponent("book_\(book.id).json")
            try data.write(to: fileURL)
        } catch {
            throw APIError.cachingError(error)
        }
    }
    
    func getCachedBookDetails(id: Int) async throws -> Book? {
        let fileURL = cachesDirectory.appendingPathComponent("book_\(id).json")
        
        if !fileManager.fileExists(atPath: fileURL.path) {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            return try decoder.decode(Book.self, from: data)
        } catch {
            throw APIError.cachingError(error)
        }
    }
    
    func clearCache() async throws {
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: cachesDirectory, includingPropertiesForKeys: nil)
            for fileURL in fileURLs {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            throw APIError.cachingError(error)
        }
    }
}

// MARK: - Search Parameters
struct BookSearchParameters {
    var searchQuery: String?
    var languages: [String]?
    var authorYearStart: Int?
    var authorYearEnd: Int?
    var topic: String?
    var mimeType: String?
    var sort: BookSort?
    var ids: [Int]?
    var copyright: [Bool?]?
    
    enum BookSort: String {
        case popular = "popular"
        case ascending = "ascending"
        case descending = "descending"
    }
    
    func toQueryItems() -> [URLQueryItem] {
        var queryItems = [URLQueryItem]()
        
        if let searchQuery = searchQuery, !searchQuery.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: searchQuery))
        }
        
        if let languages = languages, !languages.isEmpty {
            queryItems.append(URLQueryItem(name: "languages", value: languages.joined(separator: ",")))
        }
        
        if let authorYearStart = authorYearStart {
            queryItems.append(URLQueryItem(name: "author_year_start", value: String(authorYearStart)))
        }
        
        if let authorYearEnd = authorYearEnd {
            queryItems.append(URLQueryItem(name: "author_year_end", value: String(authorYearEnd)))
        }
        
        if let topic = topic, !topic.isEmpty {
            queryItems.append(URLQueryItem(name: "topic", value: topic))
        }
        
        if let mimeType = mimeType, !mimeType.isEmpty {
            queryItems.append(URLQueryItem(name: "mime_type", value: mimeType))
        }
        
        if let sort = sort {
            queryItems.append(URLQueryItem(name: "sort", value: sort.rawValue))
        }
        
        if let ids = ids, !ids.isEmpty {
            queryItems.append(URLQueryItem(name: "ids", value: ids.map { String($0) }.joined(separator: ",")))
        }
        
        if let copyright = copyright, !copyright.isEmpty {
            let copyrightValues = copyright.map { value -> String in
                if let value = value {
                    return value ? "true" : "false"
                } else {
                    return "null"
                }
            }
            queryItems.append(URLQueryItem(name: "copyright", value: copyrightValues.joined(separator: ",")))
        }
        
        return queryItems
    }
} 