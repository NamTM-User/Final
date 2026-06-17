//
//  Project.swift
//  Test1Final
//
//  Created by Hai Nam on 17/6/26.
//

import Foundation
import SwiftUI

@Observable
class Project: Codable {
    var id: Int
    var name: String
    var photos: [Photo]
    
    var localImages: [String: UIImage] = [:]
    
    enum CodingKeys: String, CodingKey {
        case id, name, photos
    }
    
    // MARK: - Init
    init(projectId: Int) {
        self.id = projectId;
        self.name = "";
        self.photos = []
    }
    
    // MARK: - Decoder JSON
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.photos = try container.decode([Photo].self, forKey: .photos)
        self.localImages = [:]
        
    }
    
    // MARK: - Encoder JSON
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(photos, forKey: .photos)
    }
    
    
    // MARK: - Loader Data
    func load() async throws {
        
        // A. Check data local
        if let localData = LocalFileManager.loadProject(projectId: self.id) {
            self.name = localData.name
            self.photos = localData.photos
        }
        // B. Dowload
        else {
            let apiData = try await APIService().postAPI(projectId: self.id)
            self.name = apiData.name
            self.photos = apiData.photos
        }
        
        // C. Save
        self.save() // save in ssd
        try await saveImagesLocal() // save in local -> export to view
    }
    
    // MARK: - SAVE
    
    func save() {
        LocalFileManager.saveProject(project: self)
    }
    
    // MARK: - Render
    func render(canvasSize: CGSize) -> UIImage? {
        return CanvasRenderer.renderImage(photos: self.photos, localImages: self.localImages, canvasSize: canvasSize)
    }
    
    // MARK: - DOWLOAD IMAGE
    private func downloadImages(url: String) async throws -> UIImage? {
        let safeName = LocalFileManager.getSafeImageName(from: url)
        
        // A. check image local
        if let savedImage = LocalFileManager.loadImage(imageName: safeName) {
            return savedImage
        }
        
        // B. dowload image
        guard let imageURL = URL(string: url) else { return nil }
        let (data, _) = try await URLSession.shared.data(from: imageURL)
        guard let downloadedImage = UIImage(data: data) else { return nil }
        
        // C. save image in Local
        LocalFileManager.saveImage(image: downloadedImage, imageName: safeName)
        
        return downloadedImage
    }
    
    // MARK: - Save Image
    @MainActor
    private func saveImagesLocal() async throws {
        for photo in photos {
            let data = try await downloadImages(url: photo.url)
            
            if let image = data {
                self.localImages[photo.url] = image
            }
        }
    }
    
    
    
    
    
}
