//
//  PhotoItemView.swift
//  Test1
//
//  Created by Hai Nam on 21/5/26.
//

import SwiftUI

struct PhotoItemView: View {
    @Environment(CanvasViewModel.self) private var canvasViewModel
    @State private var loadedImage: Image?

    let photo: Photo
    let isSelect: Bool
    let onTap: () -> Void

    var body: some View {
        let transform = photo.transform

        Group {
            if let img = canvasViewModel.localImages[photo.url] {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else if let img = loadedImage {
                img
                    .resizable()
                    .scaledToFill()
            } else {
                Color.gray.opacity(0.15)
                    .overlay(ProgressView())
                    .task {
                        if let img = try? await canvasViewModel.loadImage(urlString: photo.url) {
                            loadedImage = img
                        }
                    }
            }
        }
        // ── Render chain BẮT BUỘC theo thứ tự này ──
        // 1. frame = baseSize
        // 2. clip
        // 3. opacity
        // 4. overlay gesture (TRƯỚC scale/rotate/position để hưởng chung transform)
        // 5. scaleEffect 
        // 6. rotationEffect
        // 7. position = tâm trong canvas coordinate space
        .frame(width: transform.baseSize.width, height: transform.baseSize.height)
        .clipped()
        .opacity(photo.opacity)
        .customGesture(
            CustomGesture(
                transform: TranformState(
                    center: transform.center,
                    scale: transform.scale,
                    rotation: transform.rotation
                ),
                isEnabled: isSelect
            )
            .onChanged { newState in
                photo.transform = PhotoTransform(
                    center: newState.center,
                    scale: newState.scale,
                    rotation: newState.rotation,
                    baseSize: transform.baseSize
                )
            }
            .onTouchStateChanged { isTouching in
                canvasViewModel.isCanvasScrollEnabled = !isTouching
            }
        )
        // scale đã được bake vào frame.width/height qua Photo.transform setter
        // nên transform.scale getter luôn = 1.0 → không cần scaleEffect
        .rotationEffect(.radians(transform.rotation))
        .onTapGesture { onTap() }
        .position(transform.center)
    }
}
