//
//  PhotoGestureCoordinator.swift
//  Test1


import Foundation
import UIKit
import SwiftUI

// MARK: -  Gesture Coordinator ( Xử lý logic gesture )

class PhotoGestureCoordinator: UIView, UIGestureRecognizerDelegate {
    var photo: Photo?
    weak var canvasModel: CanvasModel?
    
    // state gesture
    let panGesture = UIPanGestureRecognizer()
    let pinchGesture = UIPinchGestureRecognizer()
    let rotateGesture = UIRotationGestureRecognizer()
    
    // quản lý các gesture đang active , sẽ chứa các gesture đang ở trạng thái .began hoặc .changed
    private var activeGestures: Set<UIGestureRecognizer> = []
    
    // state update gesture
    private var isUpdate = false
    
    // init
    func set(photo: Photo, canvasModel: CanvasModel) {
        self.photo = photo
        self.canvasModel = canvasModel
        

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
            // kiểm tra xem trước đó Set có đang rỗng không (tức là chưa có ngón nào chạm)
            // thêm gesture vừa bắt đầu vào Set các gesture đang hoạt động
            activeGestures.insert(gesture)
            
            // 1. nếu Set trước đó rỗng, nghĩa là đây là ngón tay đầu tiên chạm vào màn hình
            if activeGestures.isEmpty {
                startTouch()
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
                endTouch()
            } else {
                // nếu vẫn còn ngón tay khác đang chạm, chỉ cập nhật image bình thường
                scheduleUpdate()
            }
            
        default:
            break
        }
    }
    
    // ========================================== HANDLE TOUCH ===========================================
    
    // A. func gọi 1 lần khi bắt đầu chạm ngón đầu tiên
    private func startTouch() {
        
        // block gesture canvas
        canvasModel?.scrollView?.isScrollEnabled = false
        canvasModel?.scrollView?.pinchGestureRecognizer?.isEnabled = false
    }
    
    // B. func gọi 1 lần khi ngón tay cuối cùng nhấc lên
    private func endTouch() {
        // unblock canvas
        canvasModel?.scrollView?.isScrollEnabled = true
        canvasModel?.scrollView?.pinchGestureRecognizer?.isEnabled = true
    }
    
    // C. update image
    private func updateImagePosition() {
        guard let cv = canvasModel?.canvasContentView else { return }
        guard let photo = self.photo else { return }
        
        // lấy transform hiện tại của ảnh trước khi thực hiện gesture
        var currentTransform = photo.transform
        // state change
        var hasChanges = false
        
        // 1. Drag
        let isPanActive = panGesture.isActive == true || panGesture.state == .ended
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
        let isPinchActive = pinchGesture.isActive == true || pinchGesture.state == .ended
        let isRotateActive = rotateGesture.isActive == true || rotateGesture.state == .ended
        
        let scale = isPinchActive ? pinchGesture.scale : 1.0
        let rotation = isRotateActive ? rotateGesture.rotation : 0.0
        
        if scale != 1.0 || rotation != 0.0 {
            // xác định tâm để zoom và xoay , mặc định tâm xoay là tâm của bức ảnh
            var focalPoint = currentTransform.center
            
            // nhưng dùng đang dùng 2 ngón tay, xoay/zoom quanh center 2 ngón tay
            if isPinchActive, pinchGesture.numberOfTouches >= 2 {
                focalPoint = pinchGesture.location(in: cv)
            } else if isRotateActive, rotateGesture.numberOfTouches >= 2 {
                focalPoint = rotateGesture.location(in: cv)
            } else if isPanActive, panGesture.numberOfTouches >= 2 {
                focalPoint = panGesture.location(in: cv)
            }
            
            // dùng api CGAffineTransform để thực hiện tranform image
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
            
            hasChanges = true // checkk changes = true
        }
        
        // update models
        if hasChanges {
            photo.transform = currentTransform
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
        _ gesture : UIGestureRecognizer,
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
