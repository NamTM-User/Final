//
//  PhotoItemView.swift
//  Test1
//
//  Created by Hai Nam on 21/5/26.
//

import SwiftUI
import UIKit

struct PhotoItemView: View {
    @Environment(CanvasViewModel.self) private var canvasViewModel
    @State private var loadedImage: Image?

    let photo: Photo
    let isSelect: Bool
    var canvasCoordinateView: UIView?
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
                        do {
                            let img = try await canvasViewModel.loadImage(urlString: photo.url)
                            loadedImage = img
                        } catch {
                            print(error)
                        }
                    }
            }
        }
        // ── Render chain theo thứ tự này ──
        // 1. frame = baseSize
        // 2. clip
        // 3. opacity
        // 4. overlay gesture (TRƯỚC scale/rotate/position để hưởng chung transform)
        // 5. rotationEffect
        // 6. position = tâm trong canvas coordinate space
        .frame(width: transform.baseSize.width, height: transform.baseSize.height)
        .clipped()
        .opacity(photo.opacity)
        .customGesture(
            CustomGesture(
                getState: {
                    TranformState(
                        center: photo.transform.center,
                        scale: photo.transform.scale,
                        rotation: photo.transform.rotation
                    )
                },
                isEnabled: isSelect,
//                canvasCoordinateView: self.canvasCoordinateView
            )
            .onChanged { newState in
                photo.transform = PhotoTransform(
                    center: newState.center,
                    scale: newState.scale,
                    rotation: newState.rotation,
                    baseSize: photo.transform.baseSize
                )
            }
            .onTouchStateChanged { isTouching in
                canvasViewModel.isCanvasScrollEnabled = !isTouching
            }
        )
        .rotationEffect(.radians(transform.rotation))
        .onTapGesture { onTap() }
        .position(transform.center)
    }
}
