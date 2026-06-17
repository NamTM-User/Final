//
//  LocalFileManager.swift
//  Test1Final
//
//  Created by Hai Nam on 12/6/26.
//

import Foundation
import SwiftUI 

struct LocalFileManager {
    
    // MARK: - getFilePath: Tạo đường dẫn tuyệt đối tới file JSON của project trong Document
    static func getFilePath(projectId: Int) -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("project_\(projectId).json")
    }
    
    // =====================================
    // MARK: - FILE PROJECT Screen2
    // =====================================
    
    // MARK: - saveProject: Lưu đối tượng Project Màn 2 xuống máy dưới dạng JSON
    static func saveProject(project: Project) {
        let url = getFilePath(projectId: project.id)
        do {
            let data = try JSONEncoder().encode(project)
            try data.write(to: url)
        } catch { 
            print("Lỗi khi lưu Project \(project.id): \(error)") 
        }
    }
    
    // MARK: - loadProject: Đọc file JSON từ máy và dịch ngược thành đối tượng Project Màn 2
    static func loadProject(projectId: Int) -> Project? {
        let url = getFilePath(projectId: projectId)
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(Project.self, from: data)
        } catch { 
            return nil 
        }
    }
    
    // =====================================
    // MARK: - FILE PROJECT MÀN 1 (DANH SÁCH)
    // =====================================
    
    // MARK: - saveProjectList: Lưu toàn bộ mảng ProjectItem xuống 1 file project_list.json duy nhất
    static func saveProjectList(_ projects: [ProjectItem]) {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let url = paths[0].appendingPathComponent("project_list.json")
        do {
            let data = try JSONEncoder().encode(projects)
            try data.write(to: url)
        } catch { 
            print("Lỗi lưu ProjectList: \(error)") 
        }
    }
    
    // MARK: - loadProjectList: Đọc file project_list.json lên và trả về mảng ProjectItem cho Screen1
    static func loadProjectList() -> [ProjectItem]? {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let url = paths[0].appendingPathComponent("project_list.json")
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([ProjectItem].self, from: data)
        } catch { 
            return nil 
        }
    }
    
    // =====================================
    // MARK: - QUẢN LÝ HÌNH ẢNH (JPEG)
    // =====================================
    
    // MARK: - getSafeImageName: Mã hoá đường link mạng thành chuỗi an toàn để làm tên file ảnh
    static func getSafeImageName(from url: String) -> String {
        if url.hasPrefix("http") {
            return url.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? UUID().uuidString
        }
        return url
    }
    
    // MARK: - saveImage: Nén ảnh UIImage thành file .jpeg và lưu vào ổ cứng để làm Cache
    static func saveImage(image: UIImage, imageName: String) {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let url = paths[0].appendingPathComponent(imageName)
        do { 
            try data.write(to: url) 
        } catch { 
            print("Lỗi lưu ảnh: \(error)") 
        }
    }
    
    // MARK: - loadImage: Tìm ảnh vật lý trong máy bằng tên, trả về UIImage để vẽ ra View
    static func loadImage(imageName: String) -> UIImage? {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let url = paths[0].appendingPathComponent(imageName)
        return UIImage(contentsOfFile: url.path)
    }
    
    // MARK: - deleteImage: Xoá 1 file ảnh vật lý ra khỏi ổ cứng
    static func deleteImage(imageName: String) {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let url = paths[0].appendingPathComponent(imageName)
        try? FileManager.default.removeItem(at: url)
    }
    
    // =====================================
    // MARK: - DELETE SCREEN1
    // =====================================
    
    // MARK: - deleteProject: Xoá TẬN GỐC project
    static func deleteProject(projectId: Int) {
        if let project = loadProject(projectId: projectId) {
            for photo in project.photos {
                let safeName = getSafeImageName(from: photo.url)
                deleteImage(imageName: safeName)
            }
        }
        
        let url = getFilePath(projectId: projectId)
        try? FileManager.default.removeItem(at: url)
    }
}
