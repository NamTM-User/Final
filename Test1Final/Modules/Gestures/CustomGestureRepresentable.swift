//
//  CustomGestureRepresentable.swift
//  Test1Final
//
//  Created by Hai Nam on 15/6/26.
//

import SwiftUI
import UIKit

struct CustomGestureRepresentable: UIViewRepresentable {
    // data init
    let stateTransform: TranformState
    let isEnabled: Bool // state edit
    
    // single gesture
    let canPan: Bool
    let canZoom: Bool
    let canRotate: Bool
    
    // callback ( optional )
    var onChanged: ((TranformState) -> Void)?
    var onEnded: ((TranformState) -> Void)?
    // CHỈ ÁP DỤNG TRONG NHỮNG PROJECT CÓ SCROLLVIEW. NẾU KHÔNG CÓ THÌ BỎ QUA KHÔNG CẦN GỌI.
    var onTouchStateChanged: ((Bool) -> Void)? // Dùng để khoá tính năng cuộn (scroll) của ScrollView lại khi đang thao tác gesture ảnh.
    
    func makeCoordinator() -> GestureCustomCoordinator {
        let view = GestureCustomCoordinator()
        view.currentTransform = stateTransform
        view.setupGesture()
        
        return view
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = context.coordinator
        
        view.isUserInteractionEnabled = isEnabled
        view.canPan = canPan
        view.canZoom = canZoom
        view.canRotate = canRotate
        
        // binding
        view.onChanged = onChanged
        view.onEnded = onEnded
        view.onTouchStateChanged = onTouchStateChanged

        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        let coordinator = uiView as! GestureCustomCoordinator
        coordinator.isUserInteractionEnabled = isEnabled
        
        coordinator.currentTransform = stateTransform
        
        coordinator.canPan = canPan
        coordinator.canZoom = canZoom
        coordinator.canRotate = canRotate
    }
}

// MARK: Coordinator
class GestureCustomCoordinator: UIView, UIGestureRecognizerDelegate {
    var currentTransform: TranformState?
    
    var canPan: Bool = true
    var canZoom: Bool = true
    var canRotate: Bool = true
    
    // callback
    var onChanged: ((TranformState) -> Void)?
    var onEnded: ((TranformState) -> Void)?
    var onTouchStateChanged: ((Bool) -> Void)?
    
    // init getures recognizers
    private let panGesture = UIPanGestureRecognizer()
    private let pinchGesture = UIPinchGestureRecognizer()
    private let rotateGesture = UIRotationGestureRecognizer()
    
    // quản lý các gesture đang active , sẽ chứa các gesture đang ở trạng thái .began hoặc .changed
    private var activeGestures: Set<UIGestureRecognizer> = []
    

    // MARK: - SETUP Gesture
    func setupGesture() {
        for g in [panGesture, pinchGesture, rotateGesture] {
            addGestureRecognizer(g)
            g.delegate = self
        }
        
        // gắn action cho từng gesture
        panGesture.addTarget(self, action: #selector(handlePan(_:)))
        pinchGesture.addTarget(self, action: #selector(handlePinch(_:)))
        rotateGesture.addTarget(self, action: #selector(handleRotate(_:)))
    }
    
    // MARK: Manager State Gesture
    private func handleGestureStateChange(_ gesture: UIGestureRecognizer) {
        switch gesture.state {
        case .began:
            activeGestures.insert(gesture)
            if activeGestures.count == 1 {
                onTouchStateChanged?(true)
            }
            updateTransform()
           
        case .changed:
            updateTransform()
           
        case .ended, .cancelled, .failed:
            activeGestures.remove(gesture)
            if activeGestures.isEmpty {
                updateTransform()
                onTouchStateChanged?(false)
                
                if let finalTransform = currentTransform {
                    onEnded?(finalTransform)
                }
            } else {
                updateTransform()
            }
           
        default:
            break
        }
    }
    
    // MARK: - Core LOGIC GESTURE
    
    private func updateTransform() {
        guard var currentTransform = self.currentTransform else { return }
        var hasChanges = false
        
        // MARK: - MOVE
        if canPan, panGesture.isActive {
            let translation = panGesture.translation(in: self)
            if translation != .zero {
                currentTransform.center.x += translation.x
                currentTransform.center.y += translation.y
               
                panGesture.setTranslation(.zero, in: self)
                hasChanges = true
            }
        }
        
        // MARK: - ZOOM/ROTATE
        let isPinchActive = canZoom && pinchGesture.isActive
        let isRotateActive = canRotate && rotateGesture.isActive
       
        let scale = isPinchActive ? pinchGesture.scale : 1.0
        let rotation = isRotateActive ? rotateGesture.rotation : 0.0
       
        if scale != 1.0 || rotation != 0.0 {
            var focalPoint = currentTransform.center
           
            if isPinchActive, pinchGesture.numberOfTouches >= 2 {
                focalPoint = pinchGesture.location(in: self)
            } else if isRotateActive, rotateGesture.numberOfTouches >= 2 {
                focalPoint = rotateGesture.location(in: self)
            } else if canPan, panGesture.isActive, panGesture.numberOfTouches >= 2 {
                focalPoint = panGesture.location(in: self)
            }
           
            var affineTransform = CGAffineTransform(translationX: focalPoint.x, y: focalPoint.y)
            affineTransform = affineTransform.scaledBy(x: scale, y: scale)
            affineTransform = affineTransform.rotated(by: rotation)
            affineTransform = affineTransform.translatedBy(x: -focalPoint.x, y: -focalPoint.y)
           
            currentTransform.center = currentTransform.center.applying(affineTransform)
            currentTransform.scale *= scale
            currentTransform.rotation += Double(rotation)
           
            pinchGesture.scale = 1.0
            rotateGesture.rotation = 0.0
            hasChanges = true
        }
        
        if hasChanges {
            self.currentTransform = currentTransform
            self.onChanged?(currentTransform)
        }
    }

    
    // MARK: - Multi Gesture
    func gestureRecognizer(_ gesture: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return otherGestureRecognizer.delegate === self
    }
    
    // MARK: - gesture handlers
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) { handleGestureStateChange(gesture) }
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) { handleGestureStateChange(gesture) }
    @objc func handleRotate(_ gesture: UIRotationGestureRecognizer) { handleGestureStateChange(gesture) }
}



// MARK: - Extension
// FIX: bỏ .ended khỏi isActive — khi gesture kết thúc (.ended), isActive phải trả về false
// để updateTransform() không đọc thêm translation/scale sau khi ngón tay nhấc lên (tránh drift/giật)
private extension UIGestureRecognizer {
    var isActive: Bool {
        return state == .began || state == .changed
    }
}
