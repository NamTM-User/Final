//
//  CanvasViewModel.swift
//  Test1Final
//
//  Created by Hai Nam on 12/6/26.
//

import Foundation
import SwiftUI
import UIKit

// MARK: - Canvas Size
let CanvasSize = CGSize(width: 500, height: 500)

@Observable
@MainActor
class CanvasViewModel {
    var projectDetail: ProjectDetail?
    
    // MARK: - State selected
    var selectedPhotoIndex: Int?
    var localImages: [String: UIImage] = [:]
    
    // MARK: - Canvas State
    var isCanvasScrollEnabled: Bool = true
    
    // api
    private let apiService = APIService()
    
    // MARK: - Load Image
    
    func loadImage(urlString: String) async throws -> Image {
        // 1.encode string thành dạng an toàn không có character special
        let safeImageName = LocalFileManager.getSafeImageName(from: urlString)
        
        // 2. kiểm tra bộ nhớ trong cache local
        if let savedImage = LocalFileManager.loadImage(imageName: safeImageName) {
            await MainActor.run { self.localImages[urlString] = savedImage }
            return Image(uiImage: savedImage)
        }
        
        // 3. nếu trong cache local chưa có thì dowload từ url
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        // 4. data
        let (data, _) = try await URLSession.shared.data(from: url) // dowload
        guard let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        // 5. save vào cache local
        LocalFileManager.saveImage(image: image, imageName: safeImageName)
        await MainActor.run { self.localImages[urlString] = image } // update vào
        return Image(uiImage: image)
    }
    
    // MARK: - Fetch
    
    func fetchData(_ id: Int) async throws {
        
        // 1. check data project trong cache local
        if let localProject = LocalFileManager.loadProject(projectId: id) {
            self.projectDetail = localProject
            // loop image
            for photo in localProject.photos {
                let safeName = LocalFileManager.getSafeImageName(from: photo.url)
                if let img = LocalFileManager.loadImage(imageName: safeName) {
                    self.localImages[photo.url] = img
                }
            }
            // check project isEmty image
            if !localProject.photos.isEmpty { return }
        }
        
        // 2. dowload image từ url
        do {
            let data = try await apiService.postAPI(projectId: id)
            self.projectDetail = data
            
            // load data image -> local cache
            LocalFileManager.saveProject(project: data)
            
            // loop image
            for photo in data.photos where photo.url.hasPrefix("http") {
                let safeName = LocalFileManager.getSafeImageName(from: photo.url)
                if let img = LocalFileManager.loadImage(imageName: safeName) {
                    self.localImages[photo.url] = img
                }
            }
        } catch {
            throw error
        }
    }
    
    // MARK: - Add Photo
    
    func addPhoto(url: String, baseSize: CGSize, center: CGPoint? = nil) {
        let photoCenter = center ?? CGPoint(x: CanvasSize.width / 2, y: CanvasSize.height / 2)
        let newPhoto = Photo(
            url: url,
            transform: PhotoTransform(
                center: photoCenter,
                scale: 1.0,
                rotation: 0.0,
                baseSize: baseSize
            )
        )
        projectDetail?.photos.append(newPhoto)
    }
    
    // MARK: - Delete Photo
    
    func deletePhoto() {
        guard let index = selectedPhotoIndex,
              let project = projectDetail,
              index >= 0, index < project.photos.count else {
            return
        }
        
        let photo = project.photos[index]
        let url = photo.url
        
        // xoá khỏi UI và ram
        projectDetail?.photos.remove(at: index)
        localImages.removeValue(forKey: url)
        
        // xoá trong ổ cứng điện thoại
        let safeName = LocalFileManager.getSafeImageName(from: url)
        LocalFileManager.deleteImage(imageName: safeName)
        
        // reset
        selectedPhotoIndex = nil
    }
    
    // MARK: - Save
    
    func saveChanges() {
        if let project = projectDetail {
            LocalFileManager.saveProject(project: project)
        }
    }
    
    // MARK: - Draw
    
    func renderCanvasImage() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: CanvasSize)
        guard let photos = projectDetail?.photos else { return nil }

        return renderer.image { ctx in
            let cgCtx = ctx.cgContext
            
            UIColor.white.setFill()
            cgCtx.fill(CGRect(origin: .zero, size: CanvasSize))

            for photo in photos {
                guard let img = localImages[photo.url] else { continue }
                let t = photo.transform
                let rw = t.baseSize.width * t.scale
                let rh = t.baseSize.height * t.scale

                cgCtx.saveGState()
                
                // Di chuyển gốc toạ độ đến vị trí tâm của bức ảnh trên Canvas
                cgCtx.translateBy(x: t.center.x, y: t.center.y)
                // Xoay
                cgCtx.rotate(by: CGFloat(t.rotation))
                
                // Render ảnh
                img.draw(
                    in: CGRect(x: -rw / 2, y: -rh / 2, width: rw, height: rh),
                    blendMode: .normal,
                    alpha: CGFloat(photo.opacity)
                )
                // Reset
                cgCtx.restoreGState()
            }
        }
    }
    
    // MARK: - Camera Focus
    
    func focusCamera(scrollViewSize: CGSize, canvasSize: CGSize) -> CGPoint {
        guard let photos = projectDetail?.photos, !photos.isEmpty else {
            let offsetX = (canvasSize.width - scrollViewSize.width) / 2
            let offsetY = (canvasSize.height - scrollViewSize.height) / 2
            return CGPoint(x: offsetX, y: offsetY)
        }
        
        var minX: Double = .greatestFiniteMagnitude
        var minY: Double = .greatestFiniteMagnitude
        var maxX: Double = -.greatestFiniteMagnitude
        var maxY: Double = -.greatestFiniteMagnitude
        
        for photo in photos {
            let frame = photo.frame
            minX = min(minX, frame.x)
            maxX = max(maxX, frame.x + frame.width)
            minY = min(minY, frame.y)
            maxY = max(maxY, frame.y + frame.height)
        }
        
        let boundingCenterX = minX + (maxX - minX) / 2
        let boundingCenterY = minY + (maxY - minY) / 2
        
        let offsetX = boundingCenterX - scrollViewSize.width / 2
        let offsetY = boundingCenterY - scrollViewSize.height / 2
        
        let maxOffsetX = max(0, min(offsetX, canvasSize.width - scrollViewSize.width))
        let maxOffsetY = max(0, min(offsetY, canvasSize.height - scrollViewSize.height))
        
        return CGPoint(x: maxOffsetX, y: maxOffsetY)
    }
}
