//
//  ProjectDetailHeader.swift
//  Test1
//
//  Created by Hai Nam on 15/5/26.
//

import SwiftUI
import UniformTypeIdentifiers

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

    var shareItem: CanvasShareItem {
        CanvasShareItem {
            canvasModel.renderCanvasImage()
        }
    }

    var body: some View {
        HStack {
            // 1. back
            Button {
                canvasModel.saveChanges()
                dismiss()
            } label: {
                Text("Back")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.black)
            }
            // 2. spacer
            Spacer()
            
            // 3. export
            ShareLink(
                item: shareItem,
                preview: SharePreview(canvasModel.projectDetail?.name ?? "Canvas"),
                label: {
                    Text("Export")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.blue)
                }
            )
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}
