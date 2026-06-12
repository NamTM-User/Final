//
//  ProjectDetailMiddle.swift
//
//  Created by Hai Nam on 15/5/26.
//

import SwiftUI

// MARK: - Container

struct ProjectDetailMiddle: View {
    @Environment(CanvasModel.self) private var canvasModel

    var body: some View {
        GeometryReader { geo in
            CanvasScrollView(
                size: geo.size,
                onSetup: { sv, cv in
                    canvasModel.scrollView        = sv
                    canvasModel.canvasContentView = cv
                    Task { @MainActor in
                        canvasModel.focusCamera()
                    }
                },
                onZoom: { zoomScale in
                    canvasModel.cameraZoom = zoomScale
                },
                viewSwiftUI: AnyView(
                    CanvasLayerView()
                        .environment(canvasModel)
                )
            )
        }
    }
}

// MARK: - Canvas Layer View

struct CanvasLayerView: View {
    var body: some View {
        ZStack {
            // Layer 1: Photos + canvas background
            PhotoContentLayer()
                .frame(width: CanvasSize.width, height: CanvasSize.height)
                .clipped()

            // Layer 2: Selection overlay
            OverlayLayerView()
        }
        .frame(width: CanvasSize.width, height: CanvasSize.height)
    }
}

// MARK: - Photo Content Layer

struct PhotoContentLayer: View {
    @Environment(CanvasModel.self) private var canvasModel

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    canvasModel.selectedPhoto = nil
                }

            // Render từng ảnh
            if let detail = canvasModel.projectDetail {
                ForEach(detail.photos) { photo in
                    let isSelected = canvasModel.selectedPhoto?.id == photo.id
                    PhotoItemView(
                        photo: photo,
                        isSelect: isSelected,
                        onTap: {
                            if canvasModel.selectedPhoto?.id != photo.id {
                                canvasModel.selectedPhoto = photo
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
    @Environment(CanvasModel.self) private var canvasModel

    var body: some View {
        Group {
            if let photo = canvasModel.selectedPhoto {
                PhotoSelectionOverlay(
                    photo: photo,
                    zoomScale: canvasModel.cameraZoom,
                    onDelete: { canvasModel.deletePhoto() }
                )
                .zIndex(2)
            }
        }
    }
}
