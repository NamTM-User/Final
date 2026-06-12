//
//  CanvasModels.swift
//  Test1Final
//
//  Created by Hai Nam on 12/6/26.
//

import Foundation
import CoreGraphics

// không cần chuyển thành class vì không thao tác id trực tiếp ở đây ( thao tác ở class Photo rồi ) , để struct sẽ tốt hơn
struct ProjectDetail: Codable {
    var name: String
    var id: Int
    var photos: [Photo]

}

// MARK: - Frame
struct Frame: Codable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
}

// MARK: - Photo
@Observable
class Photo: Codable, Identifiable {
    var id: UUID = UUID()
    var url: String
    var opacity: Double = 1.0
    var frame: Frame
    var rotation: Double = 0.0
    
    // computed property
    var transform: PhotoTransform {
        get {
            // Công thức tính center : Tâm nằm ở giữa width và height => tính tâm thì sẽ đi sang phải nửa widght và đi xuống nửa height
            PhotoTransform(
                center: CGPoint(x: frame.x + frame.width / 2, y: frame.y + frame.height / 2),
                scale: 1.0, // Tỉ lệ default chưa scale
                rotation: rotation,
                baseSize: CGSize(width: frame.width, height: frame.height)
            )
        }
        
        set {
            // khi gesture change -> ghi lại newvalue vào frame & rotation
            let w = newValue.baseSize.width * newValue.scale
            let h = newValue.baseSize.height * newValue.scale
            
            // set new coordinate
            frame.x = newValue.center.x - w/2
            frame.y = newValue.center.y - h/2
            frame.width = w
            frame.height = h
            rotation = newValue.rotation
        }
    }
    
    // handle keys JSON compiler
    enum CodingKeys: String , CodingKey {
        case id , url , opacity , frame , rotation
    }
    
    // init
    init(id: UUID = UUID(), url: String, transform: PhotoTransform, opacity: Double = 1.0) {
        self.id = id
        self.url = url
        self.opacity = opacity
        self.rotation = transform.rotation
        
        // convert transform -> frame
        let w = transform.baseSize.width * transform.scale
        let h = transform.baseSize.height * transform.scale
        
        self.frame = Frame(
            x: transform.center.x - w/2,
            y: transform.center.y - h/2,
            width: w,
            height: h
        )
    }
    
    // decoder JSON from server -> IMAGE
    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // các field thiếu từ server
        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        self.opacity = (try? container.decode(Double.self, forKey: .opacity)) ?? 1.0
        self.rotation = (try? container.decode(Double.self, forKey: .rotation)) ?? 0.0
        
        // các field có trong json gửi từ server
        self.url = try container.decode(String.self, forKey: .url)
        self.frame = try container.decode(Frame.self, forKey: .frame)
    }
    
    // encoder image -> JSON (func encode require protocol Encodable)
    func encode(to e: any Encoder) throws {
        // container key-value JSON
        var container = e.container(keyedBy: CodingKeys.self)
        
        // write key-value -> container
        try container.encode(id, forKey: .id)
        try container.encode(url, forKey: .url)
        try container.encode(opacity, forKey: .opacity)
        try container.encode(frame, forKey: .frame)
        try container.encode(rotation, forKey: .rotation)
        
    }
    
}

// MARK: - PhotoTransform
struct PhotoTransform: Codable {
    var center: CGPoint // center image trong canvas
    var scale: CGFloat
    var rotation: Double
    var baseSize: CGSize  // size ảnh chuẩn(hiện tại) của ảnh trước khi ngón tay bắt đầu kéo scale
}
