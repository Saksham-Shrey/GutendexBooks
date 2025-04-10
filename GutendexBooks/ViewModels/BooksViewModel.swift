import Foundation
import SwiftUI

@MainActor
class BooksViewModel: ObservableObject {
    private let apiService = BooksAPIService()
    
    @Published var books: [Book] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasNextPage = false
    @Published var nextPageURL: String?
    
    // Book details state
    @Published var selectedBook: Book?
    @Published var isLoadingBookDetails = false
    
    private var loadTask: Task<Void, Never>?
    private var isInitialLoad = true
    
    deinit {
        loadTask?.cancel()
    }
    
    func loadBooks() async {
        if isLoading { return }
        
        // Cancel any existing load task
        loadTask?.cancel()
        
        isLoading = true
        errorMessage = nil
        
        // Create a new task for loading books
        loadTask = Task {
            do {
                // Use cache for first load, force refresh for manual pulls
                let useCache = isInitialLoad
                let response = try await apiService.fetchBooks(useCache: useCache)
                
                // Guard against task cancellation
                if Task.isCancelled { return }
                
                self.books = response.results
                self.nextPageURL = response.next
                self.hasNextPage = response.next != nil
                self.isInitialLoad = false
            } catch {
                if !Task.isCancelled {
                    self.errorMessage = handleError(error)
                }
            }
            
            self.isLoading = false
        }
        
        // Wait for task completion
        await loadTask?.value
    }
    
    func loadMoreBooks() async {
        guard hasNextPage, let nextPage = nextPageURL, !isLoading else { return }
        
        // Cancel any existing load task
        loadTask?.cancel()
        
        isLoading = true
        
        // Create a new task for loading more books
        loadTask = Task {
            do {
                // Small delay to prevent multiple rapid requests
                try await Task.sleep(for: .milliseconds(300))
                
                // Guard against task cancellation
                if Task.isCancelled { return }
                
                let response = try await apiService.fetchBooks(page: nextPage)
                
                // Guard against task cancellation again
                if Task.isCancelled { return }
                
                // Append new books to existing list
                self.books.append(contentsOf: response.results)
                self.nextPageURL = response.next
                self.hasNextPage = response.next != nil
            } catch {
                if !Task.isCancelled {
                    self.errorMessage = handleError(error)
                }
            }
            
            self.isLoading = false
        }
        
        // Wait for task completion
        await loadTask?.value
    }
    
    func loadBookDetails(id: Int) async {
        isLoadingBookDetails = true
        errorMessage = nil
        
        do {
            let book = try await apiService.fetchBookDetails(id: id)
            self.selectedBook = book
        } catch {
            self.errorMessage = handleError(error)
        }
        
        isLoadingBookDetails = false
    }
    
    func clearCache() async {
        do {
            let cache = BookCache.shared
            try await cache.clearCache()
        } catch {
            self.errorMessage = "Failed to clear cache: \(error.localizedDescription)"
        }
    }
    
    private func handleError(_ error: Error) -> String {
        if let apiError = error as? APIError {
            switch apiError {
            case .invalidURL:
                return "Invalid URL"
            case .invalidResponse:
                return "Invalid response from server"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .decodingError(let error):
                return "Failed to process data: \(error.localizedDescription)"
            case .cachingError(let error):
                return "Caching error: \(error.localizedDescription)"
            }
        }
        return "Unknown error: \(error.localizedDescription)"
    }
    
    func retryLoading() async {
        await loadBooks()
    }
} 