//
//  test.swift
//  Test1
//
//  Created by Hai Nam on 25/5/26.
//

import UIKit

func drawFiveImages() -> UIImage? {
    let canvasSize = CGSize(width: 600, height: 400)
    let renderer = UIGraphicsImageRenderer(size: canvasSize)

    let images = [
        UIImage(named: "img1") ?? UIImage(),
        UIImage(named: "img2") ?? UIImage(),
        UIImage(named: "img3") ?? UIImage(),
        UIImage(named: "img4") ?? UIImage(),
        UIImage(named: "img5") ?? UIImage(named: "img1") ?? UIImage()
    ]

    let image = renderer.image { context in
        let imageWidth: CGFloat = 110
        let imageHeight: CGFloat = 180
        let padding: CGFloat = 10

        for (index, img) in images.enumerated() {
            let x = CGFloat(index) * (imageWidth + padding) + padding
            let rect = CGRect(x: x, y: 110, width: imageWidth, height: imageHeight)
            img.draw(in: rect)
        }
    }

    return image
}
