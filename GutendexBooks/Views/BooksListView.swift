import SwiftUI
import UIKit

struct BooksListView: View {
    @StateObject private var viewModel = BooksViewModel()
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var scrollViewOffset: CGFloat = 0
    @State private var startOffset: CGFloat = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemBackground).opacity(0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack {
                    // Custom search bar
                    searchBar
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Books list
                    booksList
                }
                .navigationTitle(viewModel.isSearchActive ? "Search Results" : "Popular Books")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    if viewModel.isSearchActive {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Clear") {
                                Task {
                                    await viewModel.clearSearch()
                                    searchText = ""
                                }
                            }
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadBooks()
                }
            }
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search books...", text: $searchText)
                    .onChange(of: searchText) { _, newValue in
                        // Update viewModel's searchQuery when user types
                        viewModel.searchQuery = newValue
                    }
                    .onSubmit {
                        Task {
                            isSearching = true
                            await viewModel.searchBooks(query: searchText)
                        }
                    }
                    .submitLabel(.search)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Search") {
                                Task {
                                    isSearching = true
                                    await viewModel.searchBooks(query: searchText)
                                    // Dismiss keyboard
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                }
                            }
                            .disabled(searchText.isEmpty)
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        Task {
                            isSearching = false
                            await viewModel.clearSearch()
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 3)
            )
        }
    }
    
    // MARK: - Books List
    private var booksList: some View {
        ScrollView {
            ScrollViewReader { scrollViewProxy in
                // Offset tracking
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self, 
                        value: geometry.frame(in: .named("scrollView")).minY
                    )
                }
                .frame(height: 0)
                
                if viewModel.isLoading && viewModel.books.isEmpty {
                    VStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                        Text("Loading books...")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(height: 300)
                } else if let error = viewModel.errorMessage, viewModel.books.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Something went wrong")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(error)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        Button {
                            Task {
                                await viewModel.retryLoading()
                            }
                        } label: {
                            Text("Try Again")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(height: 44)
                                .frame(maxWidth: 200)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "B39B77"), Color(hex: "8D7862")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(color: Color(hex: "B39B77").opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                        Spacer()
                    }
                    .padding()
                    .frame(height: 400)
                } else if viewModel.books.isEmpty && viewModel.isSearchActive {
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No results found")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Try a different search term")
                            .foregroundColor(.secondary)
                        
                        Button {
                            Task {
                                searchText = ""
                                await viewModel.clearSearch()
                            }
                        } label: {
                            Text("Clear Search")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(height: 44)
                                .frame(maxWidth: 200)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "B39B77"), Color(hex: "8D7862")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(color: Color(hex: "B39B77").opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                        Spacer()
                    }
                    .padding()
                    .frame(height: 400)
                } else {
                    VStack {
                        // Show loading overlay at the top when searching
                        if viewModel.isLoading && viewModel.isSearchActive {
                            HStack {
                                ProgressView()
                                    .padding(.trailing, 8)
                                Text("Searching...")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        }
                        
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.books) { book in
                                NavigationLink(destination: BookDetailView(book: book)) {
                                    BookCard(book: book)
                                        .background(Color(.systemBackground))
                                }
                                .buttonStyle(ScaleButtonStyle())
                                .id(book.id) // Important for ScrollViewReader
                                
                                // Check if this is the last item
                                if book.id == viewModel.books.last?.id && viewModel.hasNextPage {
                                    ProgressView()
                                        .onAppear {
                                            if !viewModel.isLoading {
                                                Task {
                                                    await viewModel.loadMoreBooks()
                                                }
                                            }
                                        }
                                        .padding()
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }
        }
        .coordinateSpace(name: "scrollView")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            // Store the initial offset when the view first loads
            if startOffset == 0 {
                startOffset = value
            }
            
            // Track our scroll offset
            scrollViewOffset = value
            
            // Load more items if we're at the bottom
            let scrollThreshold: CGFloat = 200
            let offset = startOffset - scrollViewOffset
            
            // If we're at the end, load more if available
            if offset > scrollThreshold && viewModel.hasNextPage && !viewModel.isLoading {
                Task {
                    await viewModel.loadMoreBooks()
                }
            }
        }
        .refreshable {
            if viewModel.isSearchActive {
                await viewModel.searchBooks(query: searchText)
            } else {
                await viewModel.loadBooks()
            }
        }
    }
}

// MARK: - Scroll Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Custom Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .brightness(configuration.isPressed ? -0.05 : 0)
    }
}


#Preview {
    BooksListView()
} 
