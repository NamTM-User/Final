//
//  ProjectDetailMiddle.swift
//
//  Created by Hai Nam on 15/5/26.
//

import SwiftUI
import UIKit

// MARK: - Container

struct ProjectDetailMiddle: View {
    @Environment(CanvasViewModel.self) private var canvasModel
    @Environment(CanvasUIState.self) private var uiState
    @State private var canvasCoordinateView: UIView? = nil

    var body: some View {
        GeometryReader { geo in
            CanvasScrollView(
                size: geo.size,
                isScrollEnabled: canvasModel.isCanvasScrollEnabled,
                onSetup: { sv, cv in
                    // 1. binding data -> uiState 
                    DispatchQueue.main.async {
                        uiState.scrollView = sv
                    }
                    
                    // 2. binding update size canvasCoordinateView
                    DispatchQueue.main.async {
                        self.canvasCoordinateView = cv
                    }
                    
                    // 3. (Đã xoá closure setScrollEnabled)
                    
                    // 4. focus camera
                    Task { @MainActor in
                        if let photos = canvasModel.project?.photos, !photos.isEmpty {
                            var minX: Double = Double.greatestFiniteMagnitude
                            var minY: Double = Double.greatestFiniteMagnitude
                            var maxX: Double = -Double.greatestFiniteMagnitude
                            var maxY: Double = -Double.greatestFiniteMagnitude
                            
                            for photo in photos {
                                let frame = photo.frame
                                if frame.x < minX             { minX = frame.x }
                                if frame.x + frame.width > maxX  { maxX = frame.x + frame.width }
                                if frame.y < minY             { minY = frame.y }
                                if frame.y + frame.height > maxY { maxY = frame.y + frame.height }
                            }
                            
                            let boundingCenterX = minX + (maxX - minX) / 2
                            let boundingCenterY = minY + (maxY - minY) / 2
                            
                            let offsetX = boundingCenterX - sv.bounds.width  / 2
                            let offsetY = boundingCenterY - sv.bounds.height / 2
                            
                            let maxOffsetX = max(0, min(offsetX, cv.frame.width  - sv.bounds.width))
                            let maxOffsetY = max(0, min(offsetY, cv.frame.height - sv.bounds.height))
                            
                            sv.setContentOffset(CGPoint(x: maxOffsetX, y: maxOffsetY), animated: true)
                        } else {
                            let offsetX = (cv.frame.width  - sv.bounds.width)  / 2
                            let offsetY = (cv.frame.height - sv.bounds.height) / 2
                            sv.setContentOffset(CGPoint(x: offsetX, y: offsetY), animated: true)
                        }
                    }
                },
                onZoom: { zoomScale in
                    uiState.cameraZoom = zoomScale
                },
                viewSwiftUI: AnyView(
                    CanvasLayerView(canvasCoordinateView: self.canvasCoordinateView)
                        .environment(canvasModel)
                )
            )
        }
    }
}

// MARK: - Canvas Layer View

struct CanvasLayerView: View {
    var canvasCoordinateView: UIView?
    
    var body: some View {
        ZStack {
            // Layer 1: Photos + canvas background
            PhotoContentLayer(canvasCoordinateView: canvasCoordinateView)
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
    @Environment(CanvasViewModel.self) private var canvasModel
    var canvasCoordinateView: UIView?

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    canvasModel.selectedPhoto = nil
                }

            // Render từng ảnh
            if let detail = canvasModel.project {
                ForEach(detail.photos) { photo in
                    let isSelected = canvasModel.selectedPhoto?.id == photo.id
                    PhotoItemView(
                        photo: photo,
                        isSelect: isSelected,
                        canvasCoordinateView: self.canvasCoordinateView,
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
    @Environment(CanvasViewModel.self) private var canvasModel
    @Environment(CanvasUIState.self) private var uiState

    var body: some View {
        Group {
            if let photo = canvasModel.selectedPhoto {
                PhotoSelectionOverlay(
                    photo: photo,
                    zoomScale: uiState.cameraZoom,
                    onDelete: { canvasModel.deletePhoto() }
                )
                .zIndex(2)
            }
        }
    }
}
