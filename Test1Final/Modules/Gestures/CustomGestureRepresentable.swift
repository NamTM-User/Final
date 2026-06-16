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
    let getState: () -> TranformState
    let isEnabled: Bool // state edit
    
    // single gesture
    let canPan: Bool
    let canZoom: Bool
    let canRotate: Bool
    
    let canvasCoordinateView: UIView?
    
    // callback ( optional )
    var onChanged: ((TranformState) -> Void)?
    var onEnded: ((TranformState) -> Void)?
    // CHỈ ÁP DỤNG TRONG NHỮNG PROJECT CÓ SCROLLVIEW. NẾU KHÔNG CÓ THÌ BỎ QUA KO CẦN GỌI.
    var onTouchStateChanged: ((Bool) -> Void)? // Dùng để khoá tính năng cuộn (scroll) của ScrollView lại khi đang thao tác gesture ảnh.
    
    func makeCoordinator() -> GestureCustomCoordinator {
        let view = GestureCustomCoordinator()
        view.getState = getState
        view.setupGesture()
        
        return view
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = context.coordinator
        
        view.isUserInteractionEnabled = isEnabled
        view.canvasCoordinateView = canvasCoordinateView
        view.canPan = canPan
        view.canZoom = canZoom
        view.canRotate = canRotate
        
        // binding
        view.onChanged = onChanged
        view.onEnded = onEnded
        view.onTouchStateChanged = onTouchStateChanged

        
        return context.coordinator
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        let coordinator = uiView as! GestureCustomCoordinator
        coordinator.isUserInteractionEnabled = isEnabled
        
        coordinator.getState = getState
        coordinator.canvasCoordinateView = canvasCoordinateView
        
        coordinator.canPan = canPan
        coordinator.canZoom = canZoom
        coordinator.canRotate = canRotate
        
        // Cập nhật closure mới nhất mỗi khi SwiftUI thay đổi state
        coordinator.onChanged = onChanged
        coordinator.onEnded = onEnded
        coordinator.onTouchStateChanged = onTouchStateChanged
    }
}

// MARK: Coordinator
class GestureCustomCoordinator: UIView, UIGestureRecognizerDelegate {
    var getState: (() -> TranformState)?
    
    var canPan: Bool = true
    var canZoom: Bool = true
    var canRotate: Bool = true
    
    // callback
    var onChanged: ((TranformState) -> Void)?
    var onEnded: ((TranformState) -> Void)?
    var onTouchStateChanged: ((Bool) -> Void)?
    
    // Coordinate space reference
    weak var canvasCoordinateView: UIView?
    
    // state gesture
    let panGesture = UIPanGestureRecognizer()
    let pinchGesture = UIPinchGestureRecognizer()
    let rotateGesture = UIRotationGestureRecognizer()
    
    // quản lý các gesture đang active , sẽ chứa các gesture đang ở trạng thái .began hoặc .changed
    private var activeGestures: Set<UIGestureRecognizer> = []
    
    var isGestureActive: Bool {
        return !activeGestures.isEmpty
    }
    
    // state update gesture
    private var isUpdate = false

    // MARK: - SETUP Gesture
    func setupGesture() {
        for g in [panGesture, pinchGesture, rotateGesture] {
            addGestureRecognizer(g)
            g.delegate = self
        }
        panGesture.addTarget(self, action: #selector(handlePan(_:)))
        pinchGesture.addTarget(self, action: #selector(handlePinch(_:)))
        rotateGesture.addTarget(self, action: #selector(handleRotate(_:)))
    }
    
    // MARK: - Logic gesture
    
    // func state change gesture
    private func handleGestureStateChange(_ gesture: UIGestureRecognizer) {
        switch gesture.state {
        case .began:
            // khi ngón tay bắt đầu chạm
            // thêm gesture vừa bắt đầu vào Set các gesture đang hoạt động
            activeGestures.insert(gesture)
            
            // nếu đây là ngón tay đầu tiên chạm vào màn hình
            if activeGestures.count == 1 {
                onTouchStateChanged?(true) 
            }
            
            // update scale image
            scheduleUpdate()
            
        case .changed:
            scheduleUpdate()
            
        case .ended, .cancelled, .failed:
            // delete gesture này khỏi Set các gesture đang hoạt động
            activeGestures.remove(gesture)
            
            // Kiểm tra xem Set đã rỗng chưa (tất cả ngón tay đã nhấc lên chưa)
            if activeGestures.isEmpty {
                scheduleUpdate()
                onTouchStateChanged?(false)
                
                if let finalTransform = getState?() {
                    onEnded?(finalTransform)
                }
            } else {
                // nếu vẫn còn ngón tay khác đang chạm, chỉ cập nhật image bình thường
                scheduleUpdate()
            }
            
        default:
            break
        }
    }
    
    // ========================================== HANDLE TOUCH ===========================================
    
    // C. update image
    private func updateImagePosition() {
        // Lấy View chuẩn để đo . Ưu tiên canvasCoordinateView (truyền từ ngoài vào).
        // Nếu bên ngoài không truyền = nil, thì lấy View cha .
        guard var currentTransform = self.getState?() else { return } // lấy state transform
        let cv = self.canvasCoordinateView ?? superview?.superview
        
        // state change
        var hasChanges = false
        
        // 1. Drag
        let isPanActive = canPan && (panGesture.isActive == true || panGesture.state == .ended)
        if isPanActive {
            // value translation của ngón tay
            let translation = panGesture.translation(in: cv)
            if translation != .zero {
                // Cộng dồn độ dịch chuyển vào tâm của ảnh
                currentTransform.center.x += translation.x
                currentTransform.center.y += translation.y
                // reset tránh + dồn liên tục
                panGesture.setTranslation(.zero, in: cv)
                hasChanges = true // đánh dấu là có thay đổi
            }
        }
        
        // 2. Zoom + Rotate
        let isPinchActive = canZoom && (pinchGesture.isActive == true || pinchGesture.state == .ended)
        let isRotateActive = canRotate && (rotateGesture.isActive == true || rotateGesture.state == .ended)
        
        let scale    = isPinchActive  ? pinchGesture.scale    : 1.0
        let rotation = isRotateActive ? rotateGesture.rotation : 0.0
        
        if scale != 1.0 || rotation != 0.0 {
            // xác định tâm để zoom và xoay , mặc định tâm xoay là tâm của bức ảnh
            var focalPoint = currentTransform.center
            
            // nhưng đang dùng 2 ngón tay, xoay/zoom quanh center 2 ngón tay
            if isPinchActive, pinchGesture.numberOfTouches >= 2 {
                focalPoint = pinchGesture.location(in: cv)
            } else if isRotateActive, rotateGesture.numberOfTouches >= 2 {
                focalPoint = rotateGesture.location(in: cv)
            } else if isPanActive, panGesture.numberOfTouches >= 2 {
                focalPoint = panGesture.location(in: cv)
            }
            
            // dùng api CGAffineTransform để thực hiện transform image
            var transform = CGAffineTransform(translationX: focalPoint.x, y: focalPoint.y)
            transform = transform.scaledBy(x: scale, y: scale)
            transform = transform.rotated(by: rotation)
            // reset về gốc toạ độ
            transform = transform.translatedBy(x: -focalPoint.x, y: -focalPoint.y)
            
            // apply ma trận trên vào tâm hiện tại của bức ảnh để tìm ra tâm mới
            currentTransform.center = currentTransform.center.applying(transform)
            currentTransform.scale *= scale
            currentTransform.rotation += Double(rotation)
            
            // reset
            pinchGesture.scale = 1.0
            rotateGesture.rotation = 0.0
            
            hasChanges = true // check changes = true
        }
        
        // update models
        if hasChanges {
            self.onChanged?(currentTransform)
        }
    }
    
    // ===================================================================================================
    
    // 2. Gom luồng tính toán Transform
    private func scheduleUpdate() {
        if !isUpdate {
            isUpdate = true
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isUpdate = false
                self.updateImagePosition()
            }
        }
    }
    
    // E. cho phép nhiều thao tác gesture diễn ra 1 lúc
    func gestureRecognizer(
        _ gesture: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        // Chỉ cho phép đồng thời nếu delegate của gesture kia cũng là class coordinator này
        return otherGestureRecognizer.delegate === self
    }
    
    // MARK: - GESTURE Actions
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        handleGestureStateChange(gesture)
    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        handleGestureStateChange(gesture)
    }
    
    @objc func handleRotate(_ gesture: UIRotationGestureRecognizer) {
        handleGestureStateChange(gesture)
    }
}

// MARK: - EXTENSION

private extension UIGestureRecognizer {
    var isActive: Bool {
        return state == .began || state == .changed
    }
}
