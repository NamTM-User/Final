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
class CanvasModel {
    var projectDetail: ProjectDetail?
    
    // MARK: - State selected
    var selectedPhotoIndex: Int?
    
    var localImages: [String: UIImage] = [:]
    
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
    
    
    func addPhoto(url: String , baseSize: CGSize) {
        // edit after
    }
    
    // MARK: - Delete Photo
    func deletePhoto() {
        guard let index = selectedPhotoIndex,
              let project = projectDetail,
              index >= 0 , index < project.photos.count else {
            return
        }
    }
    
    
    
    
}
