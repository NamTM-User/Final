//
//  CanvasModel.swift
//  Test1
//
//  Created by Hai Nam on 14/5/26.
//

import Foundation
import SwiftUI
import UIKit

// set default size canvas
let CanvasSize = CGSize(width: 500, height: 500)

@Observable
class CanvasModel {
    // state selected
    var projectDetail: ProjectDetail?
    
    // state selected
    var selectedPhoto: Photo?
    
    // Cache lưu trữ ảnh local tải từ máy
    var localImages: [String: UIImage] = [:]

    // @ObservationIgnored để tránh trigger re-render khi set
    @ObservationIgnored weak var scrollView: UIScrollView?
    @ObservationIgnored weak var canvasContentView: UIView?

    // Lưu lại zoom scale hiện tại để bù trừ kích thước cho overlay
    var cameraZoom: CGFloat = 1.0

    // api
    private let apiService = APIService()

    // MARK: - Load Image

    func loadImage(urlString: String) async throws -> Image {
        // 1.encode string thành dạng an toàn không có character special
        let safeImageName = urlString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? UUID().uuidString
        
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
                
                // A. Image từ libary photo
                if !photo.url.hasPrefix("http") {
                    if let img = LocalFileManager.loadImage(imageName: photo.url) {
                        self.localImages[photo.url] = img
                    }
                    
                // B. Image dowload từ url
                } else {
                    // safe encode url
                    let safe = photo.url.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
                    if let img = LocalFileManager.loadImage(imageName: safe) {
                        self.localImages[photo.url] = img // save img cache
                    }
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
                // safe encode url
                let safe = photo.url.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
                //save image
                if let img = LocalFileManager.loadImage(imageName: safe) {
                    self.localImages[photo.url] = img
                }
            }
        } catch {
            throw error
        }
    }

    // MARK: - Add Photo

    func addPhoto(url: String, baseSize: CGSize) {
        let center: CGPoint
        
        // 1. Tìm coordinate để add new image
        
        // check scrollview
        if let sv = scrollView {
            // -------------------------------------------------------------------------------------------------------------------
            // - sv.contentOffset: Vị trí cuộn hiện tại .
            // - sv.bounds.width / 2: Cộng thêm nửa chiều rộng để ra tới điểm chính giữa màn hình.
            // - Chia cho zoomScale : Để loại bỏ sự phóng to/thu nhỏ, đưa toạ độ màn hình về đúng chuẩn toạ độ thực tế của Canvas.
            // -------------------------------------------------------------------------------------------------------------------

            center = CGPoint(
                x: (sv.contentOffset.x + sv.bounds.width  / 2) / sv.zoomScale,
                y: (sv.contentOffset.y + sv.bounds.height / 2) / sv.zoomScale
            )
        }
        else {
            center = CGPoint(x: CanvasSize.width / 2, y: CanvasSize.height / 2)
        }
        //
        let newPhoto = Photo(
            url: url,
            transform: PhotoTransform(
                center:   center,
                scale:    1.0,
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
              let idx = project.photos.firstIndex(where: { $0.id == photo.id }) else { return }
        
        // get url
        let url = photo.url
        
        // xoá khỏi ui và ram
        projectDetail?.photos.remove(at: idx)
        localImages.removeValue(forKey: url)
        
        // xoá trong ổ cứng điện thoại
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        if url.hasPrefix("http") {
            let safe = url.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
            try? FileManager.default.removeItem(at: paths[0].appendingPathComponent(safe))
        } else {
            try? FileManager.default.removeItem(at: paths[0].appendingPathComponent(url))
        }
        
        // reset
        selectedPhoto = nil
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
                let rw = t.baseSize.width  * t.scale
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
    
    // MARK: Camera Focus
    
    func focusCamera() {
        /*
         Tìm trung tâm của của toàn bộ canvas -> đưa camera tới tâm của canvas
         
         1. Tìm bounding của các images
         
         2. Lấy tâm bounding của các imgs
         
         3. Rời camera về tâm bounding các imgs
         
         4. Clamp
         */
        
        guard let sv = scrollView , let cv = canvasContentView else { return }
        
        // 1. tìm bounding của các image
        if let photos = projectDetail?.photos, !photos.isEmpty {
            var minX: Double = Double.greatestFiniteMagnitude
            var minY: Double = Double.greatestFiniteMagnitude
            
            var maxX: Double = -Double.greatestFiniteMagnitude
            var maxY: Double = -Double.greatestFiniteMagnitude
            
            for photo in photos {
                let frame = photo.frame
                // so sánh tìm ra img đứng xa nhất về 4 hướng
                
                // 1. tìm left
                if frame.x < minX { minX = frame.x }
                // 2. tìm right
                if frame.x + frame.width > maxX { maxX = frame.x + frame.width }
                // 3. tìm top
                if frame.y < minY { minY = frame.y }
                // 4. tìm bottom
                if frame.y + frame.height > maxY { maxY = frame.y + frame.height }
                
            }
            
            // 2. tìm center bounding
            let boundingCenterX = minX + (maxX - minX) / 2
            let boundingCenterY = minY + (maxY - minY) / 2
            
            // 3. Rời camera
            
            // lấy center trừ lùi lại 1 nửa chiều rộng/chiều cao của điện thoại.
            let offsetX = boundingCenterX -  sv.bounds.width / 2
            let offsetY = boundingCenterY - sv.bounds.height / 2
            
            // 4. clamp
            let maxOffsetX = max(0 , min(offsetX , cv.frame.width - sv.bounds.width))
            let maxOffsetY = max(0 , min(offsetY , cv.frame.height - sv.bounds.height))
            
            // set camera
            sv.setContentOffset(CGPoint(x:maxOffsetX , y: maxOffsetY), animated: true)
        }
        else {
            let offsetX = (cv.frame.width - sv.bounds.width) / 2
            let offsetY = (cv.frame.height - sv.bounds.height) / 2
            sv.setContentOffset(CGPoint(x: offsetX, y: offsetY), animated: true) // move về center CANVAS
        }
    }
}
