//
//  ProjectDetailMiddle.swift
//
//  Created by Hai Nam on 15/5/26.
//

import SwiftUI

// MARK: - Container

struct ProjectDetailMiddle: View {
    @Environment(CanvasViewModel.self) private var canvasViewModel
    @State private var cameraZoom: CGFloat = 1.0

    var body: some View {
        GeometryReader { geo in
            CanvasScrollView(
                size: CanvasSize,
                isScrollEnabled: canvasViewModel.isCanvasScrollEnabled,
                backgroundColor: .green,
                canvasColor: .yellow,
                onSetup: { sv, cv in
                    Task { @MainActor in
                        let offset = canvasViewModel.focusCamera(scrollViewSize: sv.bounds.size, canvasSize: cv.frame.size)
                        sv.setContentOffset(offset, animated: true)
                    }
                },
                onZoom: { zoomScale in
                    cameraZoom = zoomScale
                }
            )
            {
                CanvasLayerView(cameraZoom: cameraZoom)
                    .environment(canvasViewModel)
            }
        }
    }
}

// MARK: - Canvas Layer View

struct CanvasLayerView: View {
    let cameraZoom: CGFloat

    var body: some View {
        ZStack {
            // Layer 1: Photos + canvas background
            PhotoContentLayer()
                .frame(width: CanvasSize.width, height: CanvasSize.height)
                .clipped()

            // Layer 2: Selection overlay
            OverlayLayerView(cameraZoom: cameraZoom)
        }
        .frame(width: CanvasSize.width, height: CanvasSize.height)
    }
}

// MARK: - Photo Content Layer

struct PhotoContentLayer: View {
    @Environment(CanvasViewModel.self) private var canvasViewModel

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    canvasViewModel.selectedPhotoIndex = nil
                }

            // Render từng ảnh
            if let detail = canvasViewModel.projectDetail {
                ForEach(detail.photos.indices, id: \.self) { index in
                    let photo = detail.photos[index]
                    let isSelected = canvasViewModel.selectedPhotoIndex == index
                    PhotoItemView(
                        photo: photo,
                        isSelect: isSelected,
                        onTap: {
                            if canvasViewModel.selectedPhotoIndex != index {
                                canvasViewModel.selectedPhotoIndex = index
                            }
                        }
                    )
                    .zIndex(isSelected ? 1 : 0)
                }
            }
        }
    }
}

// MARK: - Overlay Layer 

struct OverlayLayerView: View {
    @Environment(CanvasViewModel.self) private var canvasViewModel
    let cameraZoom: CGFloat

    var body: some View {
        Group {
            if let index = canvasViewModel.selectedPhotoIndex,
               let detail = canvasViewModel.projectDetail,
               index >= 0, index < detail.photos.count {
                
                let photo = detail.photos[index]
                PhotoSelectionOverlay(
                    photo: photo,
                    zoomScale: cameraZoom,
                    onDelete: { canvasViewModel.deletePhoto() }
                )
                .zIndex(2)
            }
        }
    }
}
