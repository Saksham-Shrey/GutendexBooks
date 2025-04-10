import Foundation

// MARK: - API Response
struct BooksResponse: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [Book]
}

// MARK: - Book
struct Book: Codable, Identifiable {
    let id: Int
    let title: String
    let subjects: [String]
    let authors: [Person]
    let summaries: [String]
    let translators: [Person]
    let bookshelves: [String]
    let languages: [String]
    let copyright: Bool?
    let mediaType: String
    let formats: [String: String]
    let downloadCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id, title, subjects, authors, translators, bookshelves, languages, copyright, formats
        case mediaType = "media_type"
        case downloadCount = "download_count"
        case summaries
    }
    
    // Helper computed properties
    var thumbnailURL: URL? {
        if let jpgURL = formats["image/jpeg"] {
            return URL(string: jpgURL)
        }
        return nil
    }
    
    var authorNames: String {
        authors.map { $0.name }.joined(separator: ", ")
    }
    
    var description: String {
        summaries.first ?? "No description available"
    }
}

// MARK: - Person
struct Person: Codable {
    let birthYear: Int?
    let deathYear: Int?
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case birthYear = "birth_year"
        case deathYear = "death_year"
    }
} 