import Foundation
import FirebaseStorage
import SwiftUI

class StorageService: ObservableObject {
    private let storage = Storage.storage()
    @Published var videos: [VideoModel] = []
    private let fileManager = FileManager.default
    
    private var localVideoDirectory: URL? {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("cached_videos")
    }
    
    init() {
        // Create videos directory if it doesn't exist
        if let directory = localVideoDirectory {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }
    
    func fetchVideos() async {
        let storageRef = storage.reference().child("videos")
        
        do {
            let result = try await storageRef.listAll()
            
            // Clear existing videos
            DispatchQueue.main.async {
                self.videos.removeAll()
            }
            
            // Process each video item
            for item in result.items {
                let downloadURL = try await item.downloadURL()
                let metadata = try await item.getMetadata()
                
                // Download and save the video locally
                if let localURL = try? await downloadAndSaveVideo(from: downloadURL, filename: item.name) {
                    let video = VideoModel(
                        id: item.name,
                        url: localURL, // Use local URL instead of Firebase URL
                        remoteURL: downloadURL,
                        name: item.name,
                        size: metadata.size,
                        contentType: metadata.contentType ?? "video/mp4",
                        createdAt: metadata.timeCreated ?? Date()
                    )
                    
                    DispatchQueue.main.async {
                        self.videos.append(video)
                    }
                }
            }
        } catch {
            print("Error fetching videos: \(error)")
        }
    }
    
    private func downloadAndSaveVideo(from remoteURL: URL, filename: String) async throws -> URL? {
        guard let directory = localVideoDirectory else { return nil }
        
        let localURL = directory.appendingPathComponent(filename)
        
        // Check if file already exists locally
        if fileManager.fileExists(atPath: localURL.path) {
            print("Video already exists locally: \(filename)")
            return localURL
        }
        
        // Download the file
        print("Downloading video: \(filename)")
        let (downloadedURL, _) = try await URLSession.shared.download(from: remoteURL)
        
        // Move the downloaded file to our permanent location
        try fileManager.moveItem(at: downloadedURL, to: localURL)
        print("Video downloaded and saved: \(filename)")
        
        return localURL
    }
}

struct VideoModel: Identifiable {
    let id: String
    let url: URL // Local URL
    let remoteURL: URL // Firebase Storage URL
    let name: String
    let size: Int64
    let contentType: String
    let createdAt: Date
} 