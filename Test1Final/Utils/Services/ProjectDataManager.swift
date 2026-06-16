import Foundation
import UIKit

class ProjectDataManager {
    static let shared = ProjectDataManager()
    
    private let apiService = APIService()
    
    private init() {}
    
    // MARK: - Fetch Project
    func fetchProject(id: Int) async throws -> ProjectDetail {
        // 1. check data project trong cache local
        if let localProject = LocalFileManager.loadProject(projectId: id) {
            if !localProject.photos.isEmpty {
                return localProject
            }
        }
        
        // 2. download project từ API
        let data = try await apiService.postAPI(projectId: id)
        
        // 3. save project data -> local cache
        LocalFileManager.saveProject(project: data)
        
        return data
    }
    
    // MARK: - Download Image
    func downloadImage(urlString: String) async throws -> UIImage {
        let safeImageName = urlString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? UUID().uuidString
        
        // 1. check local
        if let savedImage = LocalFileManager.loadImage(imageName: safeImageName) {
            return savedImage
        }
        
        // 2. dowload
        var finalUrlString = urlString
        if finalUrlString.hasPrefix("http://") {
            finalUrlString = finalUrlString.replacingOccurrences(of: "http://", with: "https://")
        }
        let encodedString = finalUrlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? finalUrlString
        
        guard let url = URL(string: encodedString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        // 3. save in local
        LocalFileManager.saveImage(image: image, imageName: safeImageName)
        return image
    }
    
    // MARK: - Delete File
    func deleteImageFile(urlString: String) {
        if urlString.hasPrefix("http") {
            let safeName = urlString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
            LocalFileManager.deleteImage(imageName: safeName)
        } else {
            LocalFileManager.deleteImage(imageName: urlString)
        }
    }
}
