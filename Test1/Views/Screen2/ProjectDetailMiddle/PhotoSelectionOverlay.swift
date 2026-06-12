//
//  PhotoSelectionOverlay.swift
//  Test1
//
//  Created by Hai Nam on 22/5/26.
//

import SwiftUI


struct PhotoSelectionOverlay: View {
    let photo: Photo
    let zoomScale: CGFloat
    var onDelete: () -> Void

    var body: some View {
        let transform = photo.transform
        let halfWidth  = (transform.baseSize.width  * transform.scale) / 2
        let halfHeight = (transform.baseSize.height * transform.scale) / 2

        // Tính 4 góc + vị trí nút delete trong canvas coordinate space
        let topLeft     = canvasPoint(center: transform.center, dx: -halfWidth, dy: -halfHeight, angle: transform.rotation)
        let topRight    = canvasPoint(center: transform.center, dx:  halfWidth, dy: -halfHeight, angle: transform.rotation)
        let bottomLeft  = canvasPoint(center: transform.center, dx: -halfWidth, dy:  halfHeight, angle: transform.rotation)
        let bottomRight = canvasPoint(center: transform.center, dx:  halfWidth, dy:  halfHeight, angle: transform.rotation)
        
        let dynamicGap  = 30.0 / max(zoomScale, 0.001)
        let deletePos   = canvasPoint(center: transform.center, dx: 0,          dy: -halfHeight - dynamicGap, angle: transform.rotation)

        ZStack {
            SelectionBorderView(
                topLeft: topLeft, topRight: topRight,
                bottomLeft: bottomLeft, bottomRight: bottomRight,
                zoomScale: zoomScale
            )

            ControlDot(position: topLeft, zoomScale: zoomScale)
            ControlDot(position: topRight, zoomScale: zoomScale)
            ControlDot(position: bottomLeft, zoomScale: zoomScale)
            ControlDot(position: bottomRight, zoomScale: zoomScale)

            DeleteButtonView(
                position: deletePos,
                angle: Angle(radians: transform.rotation),
                zoomScale: zoomScale,
                action: onDelete
            )
        }
        .frame(width: CanvasSize.width, height: CanvasSize.height)
    }

    private func canvasPoint(center: CGPoint, dx: Double, dy: Double, angle: Double) -> CGPoint {
        let t = CGAffineTransform(translationX: center.x, y: center.y).rotated(by: angle)
        return CGPoint(x: dx, y: dy).applying(t)
    }
}

// MARK: - Sub-components

struct ControlDot: View {
    let position: CGPoint
    let zoomScale: CGFloat
    
    var body: some View {
        Circle()
            .fill(Color.white)
            .shadow(radius: 2)
            .frame(width: 14, height: 14)
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .scaleEffect(1.0 / max(zoomScale, 0.001))
            .position(position)
            .allowsHitTesting(false)
    }
}

struct SelectionBorderView: View {
    let topLeft: CGPoint
    let topRight: CGPoint
    let bottomLeft: CGPoint
    let bottomRight: CGPoint
    let zoomScale: CGFloat

    var body: some View {
        Path { path in
            path.move(to: topLeft)
            path.addLine(to: topRight)
            path.addLine(to: bottomRight)
            path.addLine(to: bottomLeft)
            path.closeSubpath()
        }
        .stroke(Color.blue, style: StrokeStyle(lineWidth: 2.0 / max(zoomScale, 0.001))) 
        .allowsHitTesting(false)
    }
}

struct DeleteButtonView: View {
    let position: CGPoint
    let angle: Angle
    let zoomScale: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(red: 1.0, green: 0.27, blue: 0.27))
                    .frame(width: 32, height: 32)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 14, height: 3)
                    .cornerRadius(1.5)
            }
        }
        .scaleEffect(1.0 / max(zoomScale, 0.001))
        .rotationEffect(angle)
        .position(position)
    }
}
