//
//  LocalFileManager.swift
//  Test1
//
//  Created by Hai Nam on 21/5/26.
//

import Foundation
import SwiftUI


struct LocalFileManager {
    
    // 1. Tạo paths
    static func getFilePath(projectId: Int) -> URL {
        // lấy đường dẫn documents tại sandbox
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        // trả về path chứa thông tin của project ( appendingPathComponent nối thêm file vào paths )
        return paths[0].appendingPathComponent("project_\(projectId).json")
    }
    
    // 2. save data
    static func saveProject(project: ProjectDetail) {
        let url = getFilePath(projectId: project.id)
        
        do {
            // convert data project -> JSON
            let data = try JSONEncoder().encode(project)
            // ghi data ( json ) vào file
            try data.write(to: url)
            
            print(data)
        } catch {
            print(error)
        }
    }
    
    // 3. load project
    static func loadProject(projectId: Int) -> ProjectDetail? {
        let url = getFilePath(projectId: projectId)
        
        do {
            // doc file data
            let data = try Data(contentsOf: url)
            // convert JSON -> data
            let project = try JSONDecoder().decode(ProjectDetail.self, from: data)
            
            return project
        } catch {
            return nil
        }
    }
    
    // 4. save image
    static func saveImage(image: UIImage , imageName: String) {
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
    
    // 5. load image in document
    static func loadImage(imageName: String) -> UIImage? {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let url = paths[0].appendingPathComponent(imageName) // -> output type URL , url.path convert type URL -> String
        return UIImage(contentsOfFile: url.path)
    }
    
    // 6. save list project ở screen1
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
    
    // 7. load project
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
    
    // 8. delete toàn bộ dữ liệu của 1 project
    static func deleteProject(projectId: Int) {
        // Đọc project ra để biết danh sách ảnh cần xoá
        if let project = loadProject(projectId: projectId) {
            // Xoá từng file ảnh vật lý
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            
            for photo in project.photos {
                if !photo.url.hasPrefix("http") {
                    // Xoá ảnh local
                    let imageUrl = paths[0].appendingPathComponent(photo.url)
                    try? FileManager.default.removeItem(at: imageUrl)
                } else {
                    // Xoá ảnh web đã cache
                    let safeImageName = photo.url.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
                    let imageUrl = paths[0].appendingPathComponent(safeImageName)
                    try? FileManager.default.removeItem(at: imageUrl)
                }
            }
        }
        
        // Xoá file JSON của project
        let url = getFilePath(projectId: projectId)
        try? FileManager.default.removeItem(at: url)
    }
}
