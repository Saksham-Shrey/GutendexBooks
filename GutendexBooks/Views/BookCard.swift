import SwiftUI

struct BookCard: View {
    let book: Book
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top, spacing: 16) {
                // Book thumbnail with 3D effect
                CachedAsyncImage(url: book.thumbnailURL) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                            Image(systemName: "book.closed")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(LinearGradient(
                                    colors: [Color(hex: "B39B77").opacity(0.5), Color(hex: "8D7862").opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing), lineWidth: 2)
                        )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(color: .black.opacity(0.2), radius: 5, x: 3, y: 3)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(LinearGradient(
                                        colors: [Color(hex: "B39B77").opacity(0.5), Color(hex: "8D7862").opacity(0.5)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing), lineWidth: 2)
                            )
                    case .failure:
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 100, height: 150)
                .rotation3DEffect(.degrees(5), axis: (x: 0, y: 1, z: 0))
                
                // Book details
                VStack(alignment: .leading, spacing: 8) {
                    Text(book.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    Text(book.authorNames)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    // Publication year
                    if let author = book.authors.first, let birthYear = author.birthYear {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundColor(Color(hex: "A2815A"))
                            Text("Publication circa \(birthYear)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Download count badge
                    HStack {
                        Spacer()
                        Text("\(book.downloadCount) downloads")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "B39B77").opacity(0.7), Color(hex: "8D7862").opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    .ultraThinMaterial
                )
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}
 
