import SwiftUI

struct BookDetailView: View {
    let book: Book
    @State private var scrollOffset: CGFloat = 0
    @State private var isDownloading = false
    @State private var downloadStatus: [String: DownloadStatus] = [:]
    @State private var activeAlert: AlertItem?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: - Header with Image
                ZStack(alignment: .bottom) {
                    // Background Cover Image with Gradient Overlay
                    CachedAsyncImage(url: book.thumbnailURL) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 300)
                                .clipped()
                                .blur(radius: 3)
                        } else {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "B39B77").opacity(0.7), Color(hex: "8D7862").opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 300)
                        }
                    }
                    .overlay(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Book Cover and Title
                    HStack(alignment: .bottom, spacing: 20) {
                        // Book Cover with 3D effect
                        CachedAsyncImage(url: book.thumbnailURL) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 180)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .shadow(color: .black.opacity(0.4), radius: 10, x: 5, y: 5)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.white.opacity(0.6), .white.opacity(0.2)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.gray.opacity(0.3))
                                    Image(systemName: "book.closed")
                                        .font(.largeTitle)
                                        .foregroundColor(.white)
                                }
                                .frame(width: 120, height: 180)
                                .shadow(color: .black.opacity(0.4), radius: 10, x: 5, y: 5)
                            }
                        }
                        .rotation3DEffect(.degrees(8), axis: (x: 0, y: 1, z: 0))
                        .offset(y: 30)
                        
                        // Title and Author
                        VStack(alignment: .leading, spacing: 8) {
                            Text(book.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .lineLimit(3)
                            
                            Text(book.authorNames)
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                            
                            // Publication year if available
                            if let author = book.authors.first, let birthYear = author.birthYear {
                                Text("Publication circa \(birthYear)")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.trailing)
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal)
                }
                .frame(height: 330)
                
                // MARK: - Download Count 
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color(hex: "A2815A"))
                    
                    Text("\(book.downloadCount) Downloads")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // MARK: - Description
                VStack(alignment: .leading, spacing: 10) {
                    Text("About This Book")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text(book.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineSpacing(5)
                }
                .padding(.horizontal)
                
                // MARK: - Subjects & Languages
                VStack(alignment: .leading, spacing: 16) {
                    // Subjects
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Subjects")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(book.subjects.prefix(10), id: \.self) { subject in
                                Text(subject)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color(hex: "B39B77").opacity(0.6), Color(hex: "8D7862").opacity(0.6)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    )
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                    // Languages
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Available Languages")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        HStack {
                            ForEach(book.languages, id: \.self) { language in
                                Text(languageName(for: language))
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.ultraThinMaterial)
                                    )
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // MARK: - Formats
                VStack(alignment: .leading, spacing: 10) {
                    Text("Available Formats")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(book.formats.keys.sorted(), id: \.self) { format in
                            if let formatURL = book.formats[format], !formatURL.isEmpty {
                                HStack {
                                    Image(systemName: formatIcon(for: format))
                                        .foregroundColor(Color(hex: "A2815A"))
                                    
                                    Text(formatName(for: format))
                                        .font(.subheadline)
                                    
                                    Spacer()
                                    
                                    // Download button
                                    Button(action: {
                                        downloadFile(format: format, url: formatURL)
                                    }) {
                                        HStack {
                                            if let status = downloadStatus[format], status == .downloading {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle())
                                                    .scaleEffect(0.8)
                                            } else {
                                                Image(systemName: downloadButtonIcon(for: format))
                                                    .foregroundColor(.white)
                                            }
                                            
                                            Text(downloadButtonText(for: format))
                                                .font(.footnote)
                                                .foregroundColor(.white)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color(hex: "A2815A"))
                                        )
                                    }
                                    .disabled(isDownloading && downloadStatus[format] != .downloading)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 50)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $activeAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            checkExistingDownloads()
        }
    }
    
    // Initialize downloadStatus for each format
    private func checkExistingDownloads() {
        for format in book.formats.keys {
            let fileExtension = fileExtension(for: format)
            let fileName = "\(book.id)_\(book.title.replacingOccurrences(of: " ", with: "_"))\(fileExtension)"
            if FileDownloadService.shared.isFileDownloaded(fileName: fileName) {
                downloadStatus[format] = .downloaded
            } else {
                downloadStatus[format] = .notDownloaded
            }
        }
    }
    
    // MARK: - Download Logic
    enum DownloadStatus {
        case notDownloaded
        case downloading
        case downloaded
    }
    
    private func downloadFile(format: String, url: String) {
        let fileExtension = fileExtension(for: format)
        let fileName = "\(book.id)_\(book.title.replacingOccurrences(of: " ", with: "_"))\(fileExtension)"
        
        downloadStatus[format] = .downloading
        isDownloading = true
        
        FileDownloadService.shared.downloadFile(from: url, withName: fileName) { result in
            isDownloading = false
            
            switch result {
                case .success(_):
                downloadStatus[format] = .downloaded
                activeAlert = AlertItem(
                    title: "Download Complete",
                    message: "The file has been saved to your device."
                )
            case .failure(let error):
                downloadStatus[format] = .notDownloaded
                activeAlert = AlertItem(
                    title: "Download Failed",
                    message: "Failed to download the file: \(error.localizedDescription)"
                )
            }
        }
    }
    
    private func downloadButtonIcon(for format: String) -> String {
        guard let status = downloadStatus[format] else {
            return isFileDownloaded(format: format) ? "checkmark.circle" : "arrow.down.circle"
        }
        
        switch status {
        case .notDownloaded:
            return "arrow.down.circle"
        case .downloading:
            return "hourglass"
        case .downloaded:
            return "checkmark.circle"
        }
    }
    
    private func downloadButtonText(for format: String) -> String {
        guard let status = downloadStatus[format] else {
            return isFileDownloaded(format: format) ? "Downloaded" : "Download"
        }
        
        switch status {
        case .notDownloaded:
            return "Download"
        case .downloading:
            return "Downloading..."
        case .downloaded:
            return "Downloaded"
        }
    }
    
    private func isFileDownloaded(format: String) -> Bool {
        let fileExtension = fileExtension(for: format)
        let fileName = "\(book.id)_\(book.title.replacingOccurrences(of: " ", with: "_"))\(fileExtension)"
        return FileDownloadService.shared.isFileDownloaded(fileName: fileName)
    }
    
    private func fileExtension(for mimeType: String) -> String {
        if mimeType.contains("text/html") {
            return ".html"
        } else if mimeType.contains("text/plain") {
            return ".txt"
        } else if mimeType.contains("application/epub") {
            return ".epub"
        } else if mimeType.contains("application/pdf") {
            return ".pdf"
        } else if mimeType.contains("image/jpeg") {
            return ".jpg"
        } else if mimeType.contains("audio") {
            return ".mp3"
        } else {
            return ""
        }
    }
    
    private func languageName(for code: String) -> String {
        let languages = [
            "en": "English",
            "fr": "French",
            "de": "German",
            "it": "Italian",
            "es": "Spanish",
            "pt": "Portuguese",
            "ru": "Russian",
            "zh": "Chinese",
            "ja": "Japanese"
        ]
        
        return languages[code.lowercased()] ?? code.uppercased()
    }
    
    private func formatIcon(for mimeType: String) -> String {
        if mimeType.contains("text/html") {
            return "doc.richtext"
        } else if mimeType.contains("text/plain") {
            return "doc.text"
        } else if mimeType.contains("application/epub") {
            return "book"
        } else if mimeType.contains("application/pdf") {
            return "doc.fill"
        } else if mimeType.contains("image") {
            return "photo"
        } else if mimeType.contains("audio") {
            return "headphones"
        } else {
            return "doc"
        }
    }
    
    private func formatName(for mimeType: String) -> String {
        if mimeType.contains("text/html") {
            return "HTML"
        } else if mimeType.contains("text/plain") {
            return "Plain Text"
        } else if mimeType.contains("application/epub") {
            return "EPUB"
        } else if mimeType.contains("application/pdf") {
            return "PDF"
        } else if mimeType.contains("image/jpeg") {
            return "JPEG Image"
        } else if mimeType.contains("audio") {
            return "Audio"
        } else {
            return mimeType
        }
    }
}

// MARK: - Alert Item
struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 10
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > width {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
        }
        
        height = currentY + rowHeight
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            
            rowHeight = max(rowHeight, size.height)
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + spacing
        }
    }
}

