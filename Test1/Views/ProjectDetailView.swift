//
//  ProjectDetailView.swift
//  Test1
//
//  Created by Hai Nam on 14/5/26.
//

import SwiftUI

struct ProjectDetailView: View {
    let projectID: Int

    @State private var canvasModel = CanvasModel()

    var body: some View {
        VStack(spacing: 0) {

            // 1. top
            ProjectDetailHeader()
                .zIndex(1)
                .padding(.bottom, 10)

            // 2. canvas (UIScrollView)
            ProjectDetailMiddle()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            // 3. opacity slider
            Slider()
                .padding(15)

            // 4. bottom – photo picker
            ProjectDetailBottom { imageData in
                // unwrap
                guard let img = UIImage(data: imageData) else { return }

                let randomURL = UUID().uuidString
                LocalFileManager.saveImage(image: img, imageName: randomURL)
                canvasModel.localImages[randomURL] = img

                let screenW = UIScreen.main.bounds.width
                let screenH = UIScreen.main.bounds.height
                let aspectRatio = img.size.width / img.size.height

                var displayW = screenW * 0.4
                var displayH = displayW / aspectRatio
                if displayH > screenH * 0.4 {
                    displayH = screenH * 0.4
                    displayW = displayH * aspectRatio
                }

                canvasModel.addPhoto(
                    url: randomURL,
                    baseSize: CGSize(width: displayW, height: displayH)
                )
            }
        }
        .environment(canvasModel)
        .task {
            do {
                try await canvasModel.fetchData(projectID)
            } catch {
                print("fetchData error: \(error)")
            }
        }
    }
}

#Preview {
    ProjectDetailView(projectID: 21)
}
