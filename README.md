# GutendexBooks

## Overview

GutendexBooks is a modern iOS application that allows users to explore and read classic literature from Project Gutenberg's extensive collection through the Gutendex API. The app offers a visually appealing interface with rich features like searching, filtering, downloading, and reading books across multiple formats.

## Features

- **Browse and Discover**: Explore thousands of classic books from Project Gutenberg's collection
- **Detailed Book Information**: View comprehensive details about each book including:
  - Cover images
  - Author information
  - Publication year
  - Subjects and categories
  - Available languages
  - Download statistics
- **Multiple Format Support**: Access books in various formats:
  - EPUB
  - PDF
  - Plain Text
  - HTML
  - Images
  - Audio (when available)
- **Download Management**: Download any available format directly to your device for offline reading
  - Progress indicators during download
  - Download status tracking
  - Organized local storage
- **Responsive Design**: Beautiful UI that adapts to different iOS devices
- **Advanced UI Features**:
  - Elegant book cards with dynamic shadows and animations
  - Flow layout for subject tags
  - Cached image loading for performance
  - Gradient effects and modern design language

## Technical Specifications

### Requirements
- iOS 15.0+ / macOS 12.0+
- Swift 5.5+
- Xcode 13.0+

### Architecture
- **MVVM Architecture**: Clear separation between Views, ViewModels, and Models
- **SwiftUI Framework**: Modern declarative UI
- **Combine Framework**: Reactive programming for data flows
- **Asynchronous Programming**: Using Swift's modern async/await pattern

### Project Structure
```
GutendexBooks/
├── App/               # App entry points and configuration
├── Models/            # Data models and structures
├── ViewModels/        # Business logic and data transformation
├── Views/             # UI components and screens
├── Services/          # Network and system services
├── Utils/             # Utility functions and extensions
└── Assets/            # Images and resources
```

## Key Components

### Models
- `Book`: Represents a book with all its metadata
- `Person`: Represents authors and translators
- `BooksResponse`: API response structure

### Views
- `BooksListView`: Main browsing interface
- `BookDetailView`: Detailed view of a selected book with download options
- `BookCard`: Reusable component for book preview
- `CachedAsyncImage`: Performance-optimized image loading

### Services
- `BooksAPIService`: Handles API communication
- `FileDownloadService`: Manages book downloads and file storage

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/GutendexBooks.git
cd GutendexBooks
```

2. Open the project in Xcode:
```bash
open GutendexBooks.xcodeproj
```

3. Select a simulator or connected device and press Run (⌘R)

## Usage Guide

### Browsing Books
- Launch the app to see a curated list of popular books
- Use the search bar to find specific titles or authors
- Scroll through the list to discover new books

### Book Details
1. Tap on any book to view its detailed information
2. Explore the book's metadata, languages, and subjects
3. View available formats for reading or downloading

### Downloading Books
1. Navigate to a book's detail page
2. Scroll to the "Available Formats" section
3. Tap the "Download" button next to your preferred format
4. Wait for the download to complete (a progress indicator will be shown)
5. Once downloaded, the button will change to "Downloaded"

### Accessing Downloaded Books
Downloaded books are stored in the app's Documents directory and can be accessed through:
- The Files app (iOS)
- iTunes File Sharing (when connected to a computer)
- The app's built-in reader (for supported formats)

## Implementation Details

### Download Functionality
The app implements a robust download system that:
- Handles various file formats appropriately
- Provides clear visual feedback during downloads
- Manages file naming to avoid conflicts
- Stores files in accessible locations
- Preserves download state between sessions
- Handles connection errors gracefully

### Asynchronous Image Loading
To ensure smooth scrolling and performance:
- Images are loaded asynchronously
- Results are cached to minimize network requests
- Placeholders are shown during loading
- Failed loads are handled gracefully

### UI/UX Design
The app follows Apple's Human Interface Guidelines with:
- Intuitive navigation
- Consistent visual hierarchy
- Appropriate use of system controls
- Adaptive layouts for different devices
- Dark/light mode support

## Security and Privacy

GutendexBooks respects user privacy and implements:
- Secure HTTPS connections to the Gutendex API
- Minimal data collection (only what's needed for app functionality)
- No user account requirements or personal data storage
- Transparent file access permissions

## Acknowledgments

- [Project Gutenberg](https://www.gutenberg.org/) for making classic literature freely available
- [Gutendex API](https://gutendex.com/) for providing a modern REST API to access Project Gutenberg
- All the authors and contributors to the classic works available in the app

## License

[Specify your license here]

---

*Note: This app is for educational purposes and is not affiliated with Project Gutenberg.* 