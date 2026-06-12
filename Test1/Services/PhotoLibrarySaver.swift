//
//  PhotoLibrarySaver.swift
//  Test1
//
//  Created by Hai Nam on 25/5/26.
//
//import UIKit
//import Photos
//
//struct PhotoLibrarySaver {
//    static func save(image: UIImage) async throws {
//        
//        // Gọi thẳng vào kho lưu trữ ảnh dùng chung (shared) của thiết bị.
//        // Hàm performChanges yêu cầu hệ thống mở cửa để đưa dữ liệu và
//        try await PHPhotoLibrary.shared().performChanges {
//            // lưu ảnh vào photos
//            PHAssetChangeRequest.creationRequestForAsset(from: image)
//        }
//    }
//}
//
//
