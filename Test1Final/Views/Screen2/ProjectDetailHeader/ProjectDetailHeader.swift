//
//  ProjectDetailHeader.swift
//  Test1Final
//
//  Created by Hai Nam on 12/6/26.
//

import SwiftUI
internal import UniformTypeIdentifiers

struct CanvasShareItem: Transferable {
    let renderImage: @MainActor () async -> UIImage?

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .jpeg) { item in
            guard let img = await item.renderImage(),
                  let data = img.jpegData(compressionQuality: 0.9)
            else {
                return Data()
            }
            return data
        }
    }
}

struct ProjectDetailHeader: View {
    @Environment(CanvasModel.self) private var canvasModel
    @Environment(\.dismiss) private var dismiss
    
//    var shareItem: CanvasShareItem {
//        var shareItem: CanvasShareItem {
//            CanvasShareItem {
//                
//            }
//        }
//    }
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

