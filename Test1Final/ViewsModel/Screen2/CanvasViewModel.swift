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
    // references Project Model
    var project: Project?
    
    // State selected
    var selectedPhoto: Photo?
    // Canvas State Scroll
    var isCanvasScrollEnabled: Bool = true
    
    // MARK: - loadProject: Khởi tạo và yêu cầu Project tự tải data
    func loadProject(_ item: ProjectItem) async {
        do {
            let p = Project(projectId: item.id)
            self.project = p  
            
            try await p.load() // Sau đó mới ngầm đi tải ảnh chậm
        } catch {
            print("Lỗi tải project Screen2:" , error)
        }
    }
    
    // MARK: - SAVE UI
    func saveChanges() {
        project?.save()
    }
    
    // MARK: - Add
    func addPhoto(url: String, baseSize: CGSize, center: CGPoint) {
        let newPhoto = Photo(
            url: url,
            transform: PhotoTransform(center: center, scale: 1.0, rotation: 0.0, baseSize: baseSize)
        )
        project?.photos.append(newPhoto)
        saveChanges()
    }
    
    // MARK: Delete
    func deletePhoto() {
        guard let photo = selectedPhoto, let index = project?.photos.firstIndex(where: { $0.id == photo.id }) else { return }
        
        // A. Delete file in ssd
        let safeName = LocalFileManager.getSafeImageName(from: photo.url)
        LocalFileManager.deleteImage(imageName: safeName)
        
        // B. Delete in local
        project?.photos.remove(at: index)
        project?.localImages.removeValue(forKey: photo.url)
        
        // C. Reset UI
        self.selectedPhoto = nil
        
        saveChanges()
    }
    
    // MARK: - Draw
    func renderCanvasImage() -> UIImage? {
        return project?.render(canvasSize: CanvasSize)
    }
}
