//
//  ProjectDetailView.swift
//  Test1
//
//  Created by Hai Nam on 14/5/26.
//

import SwiftUI

struct ProjectDetailView: View {
    let projectItem: ProjectItem

    @State private var canvasViewModel = CanvasViewModel()
    @State private var uiState = CanvasUIState()

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
            SliderView()
                .padding(15)

            // 4. bottom – photo picker
            ProjectDetailBottom { imageData in
                // unwrap
                guard let img = UIImage(data: imageData) else { return }

                let randomURL = UUID().uuidString
                LocalFileManager.saveImage(image: img, imageName: randomURL)
                canvasViewModel.project?.localImages[randomURL] = img

                let screen = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen ?? UIScreen.main
                let screenW = screen.bounds.width
                let screenH = screen.bounds.height
                let aspectRatio = img.size.width / img.size.height

                var displayW = screenW * 0.4
                var displayH = displayW / aspectRatio
                if displayH > screenH * 0.4 {
                    displayH = screenH * 0.4
                    displayW = displayH * aspectRatio
                }

                let center = uiState.currentCenter
                canvasViewModel.addPhoto(
                    url: randomURL,
                    baseSize: CGSize(width: displayW, height: displayH),
                    center: center
                )
            }
        }
        .environment(canvasViewModel)
        .environment(uiState)
        .task {
            await canvasViewModel.loadProject(projectItem)
        }
    }
}

#Preview {
    ProjectDetailView(projectItem: ProjectItem(id: 21, name: "Test Project"))
}
