import UIKit
import SwiftUI

// MARK: Gán UIView cho Gesture

struct PhotoGesture: UIViewRepresentable {
    let photo: Photo
    let isSelected: Bool
    weak var canvasModel: CanvasModel?
    
    func makeCoordinator() -> PhotoGestureCoordinator {
        let view = PhotoGestureCoordinator()
        view.set(photo: photo, canvasModel: canvasModel!)
        return view
    }
    
    func makeUIView(context: Context) -> UIView {
        
        //isUserInteractionEnabled là thuộc tính bật/tắt khả năng nhận tương tác của user trên UIView
        context.coordinator.isUserInteractionEnabled = isSelected
        
        return context.coordinator
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        uiView.isUserInteractionEnabled = isSelected
    }

    
}
