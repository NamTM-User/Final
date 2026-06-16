//
//  LocalFileManager.swift
//  Test1Final
//
//  Created by Hai Nam on 12/6/26.
//

import Foundation
import SwiftUI

struct LocalFileManager {
    // MARK: - Tạo paths
    
    static func getFilePath(projectId: Int) -> URL {
        // lấy path từ document tại sandbox
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("project_\(projectId).json")
    }
    
    // MARK: - Save data
    
    static func saveProject(project: ProjectDetail) {
        let url = getFilePath(projectId: project.id)
        
        do {
            // convert data project -> JSON
            let data = try JSONEncoder().encode(project)
            try data.write(to: url)
        } catch {
            print(error)
        }
    }
    
    // MARK: - Load project
    
    static func loadProject(projectId: Int) -> ProjectDetail? {
        let url = getFilePath(projectId: projectId)
        
        do {
            let data = try Data(contentsOf: url)
            let project = try JSONDecoder().decode(ProjectDetail.self, from: data)
            
            return project
        } catch {
            return nil
        }
    }
    
    // MARK: - Save IMAGE
    
    static func saveImage(image: UIImage, imageName: String) {
        // convert UIImage -> JPEG
        
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let url = paths[0].appendingPathComponent(imageName)
        
        do {
            try data.write(to: url)
        } catch {
            print(error)
        }
    }
    
    // MARK: - Delete IMAGE
    
    static func deleteImage(imageName: String) {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let url = paths[0].appendingPathComponent(imageName)
        try? FileManager.default.removeItem(at: url)
    }
    
    // MARK: - Safe Image Name
    
    static func getSafeImageName(from url: String) -> String {
        if url.hasPrefix("http") {
            return url.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? UUID().uuidString
        } else {
            return url
        }
    }
    
    // MARK: - Load IMAGE IN DOCUMENT
    
    static func loadImage(imageName: String) -> UIImage? {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let url = paths[0].appendingPathComponent(imageName) // -> output type URL , url.path convert type URL -> String
        return UIImage(contentsOfFile: url.path)
    }
    
    // MARK: - Save Project
    
    static func saveProjectList(_ projects: [Project]) {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let url = paths[0].appendingPathComponent("project_list.json")
        
        do {
            let data = try JSONEncoder().encode(projects)
            try data.write(to: url)

        } catch {
            print(error)
        }
    }
    
    // MARK: - LOAD Project
    
    static func loadProjectList() -> [Project]? {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let url = paths[0].appendingPathComponent("project_list.json")
        
        do {
            let data = try Data(contentsOf: url)
            let projects = try JSONDecoder().decode([Project].self, from: data)
            return projects
        } catch {
            return nil
        }
    }
    
    // MARK: - Delete Project
    
    static func deleteProject(projectId: Int) {
        // Đọc project ra để biết danh sách ảnh cần xoá
        if let project = loadProject(projectId: projectId) {
            // Xoá từng file ảnh vật lý
            _ = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            
            for photo in project.photos {
                let safeName = getSafeImageName(from: photo.url)
                deleteImage(imageName: safeName)
            }
        }
        
        // Xoá file JSON của project
        let url = getFilePath(projectId: projectId)
        try? FileManager.default.removeItem(at: url)
    }
    
}
