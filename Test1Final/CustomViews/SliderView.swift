//
//  SliderView.swift
//  Test1Final
//
//  Created by Hai Nam on 12/6/26.
//

import SwiftUI

struct SliderView: View {
    @Environment(CanvasViewModel.self) private var canvasViewModel
    
    let thumbSize: CGFloat = 20
    
    var body: some View {
        if let index = canvasViewModel.selectedPhotoIndex,
           let project = canvasViewModel.projectDetail,
           index >= 0, index < project.photos.count {
               
            let selectedPhoto = project.photos[index]
            let curOpacity = selectedPhoto.opacity
            
            GeometryReader { geo in
                // calculate
                let dragX = geo.size.width - thumbSize
                let a = dragX * curOpacity
                
                LinearGradient(
                    colors: [.blue , .purple , .pink],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .mask {
                    ZStack(alignment: .leading) {
                        // 1 . line
                        Capsule()
                            .frame(height: 4)
                            .padding(.vertical, (thumbSize - 4) / 2)
                        // 2. circle drag
                        Circle()
                            .frame(width: thumbSize , height: thumbSize)
                            .offset(x: a)
                    }
                }
                .overlay(
                    Circle()
                        .stroke(Color.white , lineWidth: 4)
                        .shadow(radius: 1)  
                        .frame(width: thumbSize, height: thumbSize)
                        .offset(x: a),
                    alignment: .leading
                )
                .contentShape(Rectangle())
                // gesture
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let newX = value.location.x - thumbSize / 2
                            // max drag
                            let maxDrag = max(0 , min(dragX, newX))
                            // Tính ngược lại ra % opacity mới 
                            let newValue = maxDrag / dragX
                            
                            selectedPhoto.opacity = newValue
                    }
                )
            }
            .frame(height: thumbSize)
            
        }
    }
}
