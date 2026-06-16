//
//  CanvasViewModel.swift
//  Test1Final
//
//  Created by Hai Nam on 12/6/26.
//

import Foundation
import SwiftUI

// MARK: - Canvas Size
let CanvasSize = CGSize(width: 500, height: 500)

@Observable
@MainActor
class CanvasViewModel {
    var projectDetail: ProjectDetail?
    
    // MARK: - State selected
    var selectedPhoto: Photo?
    var localImages: [String: UIImage] = [:]
    
    // MARK: - Canvas State
    var isCanvasScrollEnabled: Bool = true
    
    // MARK: - Load Image
    func loadImage(urlString: String) async throws -> Image {
        // 1. check image in local
        if let img = self.localImages[urlString] {
            return Image(uiImage: img)
        }
        
        // 2. load image
        let uiImage = try await ProjectDataManager.shared.downloadImage(urlString: urlString)
        
        // 3. Lưu vào RAM
        self.localImages[urlString] = uiImage
        return Image(uiImage: uiImage)
    }
    
    // MARK: - Fetch
    
    func fetchData(_ id: Int) async throws {
        // 1. lấy data
        let project = try await ProjectDataManager.shared.fetchProject(id: id)
        self.projectDetail = project
        
        // 2. load image in ssd
        for photo in project.photos {
            let safe = photo.url.hasPrefix("http") ? (photo.url.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "") : photo.url
            if let img = LocalFileManager.loadImage(imageName: safe) {
                self.localImages[photo.url] = img
            }
        }
    }
    
    // MARK: - Add Photo
    func addPhoto(url: String, baseSize: CGSize, center: CGPoint) {
        
        let newPhoto = Photo(
            url: url,
            transform: PhotoTransform(
                center: center,
                scale: 1.0,
                rotation: 0.0,
                baseSize: baseSize
            )
        )
        projectDetail?.photos.append(newPhoto)
    }
    
    // MARK: - Delete Photo
    
    func deletePhoto() {
        guard let photo = selectedPhoto,
              let project = projectDetail,
              let index = project.photos.firstIndex(where: { $0.id == photo.id }) else {
            return
        }
        
        // 1. delete
        ProjectDataManager.shared.deleteImageFile(urlString: photo.url)
        
        // 2. delete in model
        var updatedProject = project
        updatedProject.photos.remove(at: index)
        self.projectDetail = updatedProject
        
        // 3. delete in local
        self.localImages.removeValue(forKey: photo.url)
        self.selectedPhoto = nil
    }
    
    // MARK: - Save
    
    func saveChanges() {
        if let project = projectDetail {
            LocalFileManager.saveProject(project: project)
        }
    }
    
    // MARK: - Draw
    
    func renderCanvasImage() -> UIImage? {
        return CanvasRenderer.renderImage(
            photos: projectDetail?.photos,
            localImages: localImages,
            canvasSize: CanvasSize
        )
    }
}
