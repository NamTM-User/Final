//
//  CanvasRenderer.swift
//  Test1Final
//
//  Created by Hai Nam on 16/6/26.
//

import UIKit

public struct CanvasRenderer {
    static func renderImage(photos: [Photo]?, localImages: [String: UIImage], canvasSize: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        guard let photos = photos else { return nil }

        return renderer.image { ctx in
            let cgCtx = ctx.cgContext
            
            UIColor.white.setFill()
            cgCtx.fill(CGRect(origin: .zero, size: canvasSize))

            for photo in photos {
                guard let img = localImages[photo.url] else { continue }
                let t = photo.transform
                let rw = t.baseSize.width * t.scale
                let rh = t.baseSize.height * t.scale

                cgCtx.saveGState()
                
                // Di chuyển gốc toạ độ đến vị trí tâm của bức ảnh trên Canvas
                cgCtx.translateBy(x: t.center.x, y: t.center.y)
                // Xoay
                cgCtx.rotate(by: CGFloat(t.rotation))
                
                // Render ảnh
                img.draw(
                    in: CGRect(x: -rw / 2, y: -rh / 2, width: rw, height: rh),
                    blendMode: .normal,
                    alpha: CGFloat(photo.opacity)
                )
                // Reset
                cgCtx.restoreGState()
            }
        }
    }
}
