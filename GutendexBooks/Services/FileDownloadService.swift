import Foundation

enum DownloadError: Error {
    case invalidURL
    case downloadFailed(Error)
    case fileSystemError(Error)
    case unsupportedFileType
}

class FileDownloadService {
    static let shared = FileDownloadService()
    
    private init() {}
    
    func downloadFile(from urlString: String, withName fileName: String, completion: @escaping (Result<URL, DownloadError>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        
        // Check if file type is supported
        let fileExtension = URL(fileURLWithPath: fileName).pathExtension
        if fileExtension.isEmpty {
            completion(.failure(.unsupportedFileType))
            return
        }
        
        let task = URLSession.shared.downloadTask(with: url) { tempLocalURL, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(.downloadFailed(error)))
                }
                return
            }
            
            guard let tempLocalURL = tempLocalURL else {
                DispatchQueue.main.async {
                    completion(.failure(.downloadFailed(NSError(domain: "FileDownloadService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No file downloaded"]))))
                }
                return
            }
            
            do {
                // Get the Documents directory
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                
                // Create a destination URL with the provided file name
                let destinationURL = documentsDirectory.appendingPathComponent(fileName)
                
                // Remove any existing file at the destination
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                
                // Copy the downloaded file to the destination
                try FileManager.default.copyItem(at: tempLocalURL, to: destinationURL)
                
                DispatchQueue.main.async {
                    completion(.success(destinationURL))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.fileSystemError(error)))
                }
            }
        }
        
        task.resume()
    }
    
    func getDownloadedFiles() -> [URL] {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            return fileURLs
        } catch {
            print("Error getting downloaded files: \(error)")
            return []
        }
    }
    
    func isFileDownloaded(fileName: String) -> Bool {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
} 