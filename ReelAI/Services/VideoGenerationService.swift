import Foundation
import FirebaseFunctions

enum VideoGenerationError: LocalizedError {
    case invalidPromptText(String)
    case invalidDuration(Int)
    case invalidRatio(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidPromptText(let text):
            return "Prompt text must be less than or equal to 512 characters. Current length: \(text.utf16.count)"
        case .invalidDuration(let duration):
            return "Duration must be either 5 or 10 seconds. Received: \(duration)"
        case .invalidRatio(let ratio):
            return "Ratio must be either '1280:768' or '768:1280'. Received: \(ratio)"
        }
    }
}

class VideoGenerationService: ObservableObject {
    private let functions = Functions.functions()
    
    @Published var isLoading = false
    @Published var error: Error?
    
    // Generate video from images
    func generateVideo(promptImage: URL, 
                       promptText: String,
                       watermark: Bool = false,
                       duration: Int = 5,
                       ratio: String = "768:1280") async throws -> String {
        isLoading = true
        defer { isLoading = false }
        
        // Validate prompt text length
        guard promptText.utf16.count <= 512 else {
            throw VideoGenerationError.invalidPromptText(promptText)
        }
        
        // Validate duration
        guard duration == 5 || duration == 10 else {
            throw VideoGenerationError.invalidDuration(duration)
        }
        
        // Validate ratio
        guard ratio == "1280:768" || ratio == "768:1280" else {
            throw VideoGenerationError.invalidRatio(ratio)
        }
        
        let data: [String: Any] = [
            "promptImage": promptImage.absoluteString,
            "promptText": promptText,
            "watermark": watermark,
            "duration": duration,
            "ratio": ratio
        ]
        
        do {
            let result = try await functions.httpsCallable("imageToVideoFunc")
                .call(data)
            
            guard let taskId = result.data as? String else {
                throw NSError(domain: "VideoGenerationError",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Invalid task ID received"])
            }
            
            return taskId
        } catch {
            self.error = error
            throw error
        }
    }
    
    // Get task status and result
    func getTaskStatus(taskId: String) async throws -> [String: Any] {
        do {
            let result = try await functions.httpsCallable("getTaskFunc/\(taskId)")
                .call()
            
            guard let taskStatus = result.data as? [String: Any] else {
                throw NSError(domain: "VideoGenerationError",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Invalid task status received"])
            }
            
            return taskStatus
        } catch {
            self.error = error
            throw error
        }
    }
    
    // Delete a task
    func deleteTask(taskId: String) async throws {
        do {
            _ = try await functions.httpsCallable("deleteTaskFunc/\(taskId)")
                .call()
        } catch {
            self.error = error
            throw error
        }
    }
} 
