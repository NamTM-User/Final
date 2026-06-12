//
//  PhotoGesture.swift
//  Test1Final
//
//  Created by Hai Nam on 12/6/26.
//

import UIKit
import SwiftUI

// =====================================================================
// PHẦN 1: BỀ NỔI (Dành cho bạn gõ code UI) - CHUẨN APPLE BUILDER PATTERN
// =====================================================================

// MARK: - 1. Struct Data dùng chung cho Module (Độc lập 100%)
// Đây là "chuẩn giao tiếp" riêng của Module này, tuyệt đối không dính dáng tới chữ Photo của App
public struct GestureTransform {
    public var center: CGPoint
    public var scale: CGFloat
    public var rotation: Double
    public var baseSize: CGSize
    
    public init(center: CGPoint, scale: CGFloat, rotation: Double, baseSize: CGSize) {
        self.center = center
        self.scale = scale
        self.rotation = rotation
        self.baseSize = baseSize
    }
}

// MARK: - 2. Struct PhotoGesture (Bắt chước DragGesture của Apple)
// Đóng vai trò là nơi chứa cấu hình và các hàm nối đuôi, giúp bạn gọi .onChanged, .onEnded tuỳ thích
public struct PhotoGesture {
    
    // Lưu toạ độ gốc (đã được quy đổi sang chuẩn GestureTransform)
    var transform: GestureTransform
    
    // Biến quyết định có cho phép vuốt hay không
    var isSelected: Bool
    
    // --- KHAI BÁO CÁC "ỐNG XẢ" (CALLBACKS) ĐỂ HỨNG SỰ KIỆN ---
    // Để = nil tức là những ống xả này là TUỲ CHỌN. Khi code ở UI, bạn không gọi nó cũng không báo lỗi.
    
    // Ống xả 1: Bắn toạ độ ra liên tục khi ngón tay đang di chuyển trên màn hình
    var changedAction: ((GestureTransform) -> Void)? = nil
    
    // Ống xả 2: Bắn toạ độ ra đúng 1 lần duy nhất khi tất cả ngón tay đã nhấc lên (kết thúc vuốt)
    var endedAction: ((GestureTransform) -> Void)? = nil
    
    // Ống xả 3: Bắn ra `true` khi vừa chạm ngón đầu tiên, bắn ra `false` khi nhấc ngón cuối cùng lên
    // Mục đích chính: Ra lệnh cho ViewModel khoá/mở thanh cuộn Camera
    var touchStateAction: ((Bool) -> Void)? = nil
    
    // Hàm khởi tạo bắt buộc phải có Toạ độ gốc và trạng thái Select
    public init(transform: GestureTransform, isSelected: Bool = true) {
        self.transform = transform
        self.isSelected = isSelected
    }
    
    // --- CÁC HÀM NỐI ĐUÔI (CHAINING) ---
    // Kỹ thuật Builder Pattern: Trả về chính nó (Self) sau khi gán biến để viết được kiểu .onChanged{}.onEnded{}
    
    // Hàm hứng sự kiện ĐANG VUỐT
    public func onChanged(_ action: @escaping (GestureTransform) -> Void) -> Self {
        var copy = self              // Tạo bản sao của chính cấu hình này
        copy.changedAction = action  // Gán closure bạn viết bên ngoài vào ống xả
        return copy                  // Trả về bản sao để nối tiếp hàm khác
    }
    
    // Hàm hứng sự kiện KẾT THÚC VUỐT (Nhấc tay)
    public func onEnded(_ action: @escaping (GestureTransform) -> Void) -> Self {
        var copy = self
        copy.endedAction = action
        return copy
    }
    
    // Hàm hứng sự kiện CHẠM/NHẤC ngón tay
    public func onTouchStateChanged(_ action: @escaping (Bool) -> Void) -> Self {
        var copy = self
        copy.touchStateAction = action
        return copy
    }
}

// MARK: - 3. Extension View (Để SwiftUI hiểu được PhotoGesture)
extension View {
    // Hàm này giúp bạn gọi .photoGesture(...) y hệt như các hàm native của Apple (.gesture(), .sheet()...)
    func photoGesture(_ gesture: PhotoGesture) -> some View {
        
        // Chèn lớp UIViewRepresentable chìm ở dưới nền (background) để bắt chạm ngón tay
        // Trích xuất toàn bộ cấu hình từ biến `gesture` (PhotoGesture) truyền vào nó
        self.background(
            PhotoGestureRepresentable(
                initialTransform: gesture.transform,
                isSelected: gesture.isSelected,
                onChanged: gesture.changedAction,
                onEnded: gesture.endedAction,
                onTouchStateChanged: gesture.touchStateAction
            )
        )
    }
}


// =====================================================================
// PHẦN 2: BỀ CHÌM (Chạy ngầm bên dưới) - NỐI SWIFTUI VỚI UIKIT
// =====================================================================

// MARK: - 4. Cầu nối UIViewRepresentable
// Struct này hoàn toàn chạy ngầm để cầu nối UIKit, bạn không bao giờ phải gõ tên nó ở ngoài UI
struct PhotoGestureRepresentable: UIViewRepresentable {
    
    // Dữ liệu tĩnh mồi vào lúc khởi tạo
    let initialTransform: GestureTransform
    let isSelected: Bool
    
    // Hứng các closure từ bề nổi ném vào đây để chờ ngày "phát nổ"
    var onChanged: ((GestureTransform) -> Void)?
    var onEnded: ((GestureTransform) -> Void)?
    var onTouchStateChanged: ((Bool) -> Void)?
    
    // Khởi tạo bộ não tính toán (Coordinator)
    func makeCoordinator() -> PhotoGestureCoordinator {
        let coordinator = PhotoGestureCoordinator()
        
        // Cấp toạ độ xuất phát ban đầu cho Coordinator tính toán
        coordinator.currentTransform = initialTransform
        coordinator.setupGestures()
        return coordinator
    }
    
    // Hàm này chạy 1 lần khi View vừa được tạo ra
    func makeUIView(context: Context) -> UIView {
        // Bật/tắt tương tác dựa vào isSelected
        context.coordinator.isUserInteractionEnabled = isSelected
        
        // Cắm các "ống xả" của SwiftUI vào Coordinator để khi Coordinator tính xong, nó biết đường bắn data ra ngoài
        context.coordinator.onChanged = onChanged
        context.coordinator.onEnded = onEnded
        context.coordinator.onTouchStateChanged = onTouchStateChanged
        return context.coordinator
    }
    
    // Hàm này chạy lại liên tục mỗi khi State bên ngoài SwiftUI thay đổi
    func updateUIView(_ uiView: UIView, context: Context) {
        // Cập nhật lại isSelected lỡ như user bấm nút bỏ chọn ảnh
        uiView.isUserInteractionEnabled = isSelected
        
        // Cập nhật lại toạ độ gốc lỡ như có biến động từ bên ngoài (ví dụ user bấm nút Undo toạ độ)
        let coordinator = uiView as! PhotoGestureCoordinator
        coordinator.currentTransform = initialTransform
    }
}

// MARK: - 5. Bộ não tính toán (PhotoGestureCoordinator CỦA BẠN)
// Xử lý 100% logic ma trận kéo, phóng to, xoay. KHÔNG BIẾT CanvasModel LÀ AI!
class PhotoGestureCoordinator: UIView, UIGestureRecognizerDelegate {
    
    // Biến lưu trữ toạ độ nội bộ đang tính toán dở dang
    var currentTransform: GestureTransform!
    
    // 3 ống xả chờ sẵn để bắn tín hiệu ra ngoài
    var onChanged: ((GestureTransform) -> Void)?
    var onEnded: ((GestureTransform) -> Void)?
    var onTouchStateChanged: ((Bool) -> Void)?
    
    // Khai báo 3 loại Gesture cơ bản của UIKit
    let panGesture = UIPanGestureRecognizer()
    let pinchGesture = UIPinchGestureRecognizer()
    let rotateGesture = UIRotationGestureRecognizer()
    
    // Set chứa các Gesture đang hoạt động (đang chạm trên màn hình)
    private var activeGestures: Set<UIGestureRecognizer> = []
    
    // Cờ chống giật lag (chỉ tính toán khi cần)
    private var isUpdate = false
    
    // Hàm gắn các ngón tay giả lập vào UIView này
    func setupGestures() {
        for g in [panGesture, pinchGesture, rotateGesture] {
            addGestureRecognizer(g)
            g.delegate = self
        }
        // Liên kết hành động của ngón tay với các hàm xử lý bên dưới
        panGesture.addTarget(self, action: #selector(handlePan(_:)))
        pinchGesture.addTarget(self, action: #selector(handlePinch(_:)))
        rotateGesture.addTarget(self, action: #selector(handleRotate(_:)))
    }
    
    // Quản lý trạng thái: Khi nào ngón tay bắt đầu chạm và khi nào nhấc hẳn lên
    private func handleGestureStateChange(_ gesture: UIGestureRecognizer) {
        switch gesture.state {
        case .began: // Vừa chạm vào
            activeGestures.insert(gesture) // Thêm vào danh sách đang chạm
            if activeGestures.count == 1 {
                // Nếu đây là ngón đầu tiên chạm vào màn hình -> Báo ra ngoài là `true` (Để khoá Camera)
                onTouchStateChanged?(true)
            }
            scheduleUpdate() // Gọi tính toạ độ
            
        case .changed: // Đang di chuyển ngón tay
            scheduleUpdate() // Gọi tính toạ độ liên tục
            
        case .ended, .cancelled, .failed: // Nhấc ngón tay lên hoặc vuốt xịt
            activeGestures.remove(gesture) // Rút ngón tay khỏi danh sách
            if activeGestures.isEmpty {
                scheduleUpdate()
                
                // Nếu danh sách rỗng (ngón tay cuối cùng đã nhấc lên) -> Báo ra ngoài là `false` (Để mở Camera)
                onTouchStateChanged?(false)
                
                // GỌI HÀM ENDED: Bắn toạ độ CUỐI CÙNG ra ngoài để App lưu vào ổ cứng / gửi API
                if let finalTransform = self.currentTransform {
                    onEnded?(finalTransform)
                }
            } else {
                // Nếu vẫn còn ngón khác đang chạm thì chỉ tính toạ độ tiếp thôi
                scheduleUpdate()
            }
        default:
            break
        }
    }
    
    // Xử lý ma trận xoay/kéo/scale (Logic toán học thiên tài của bạn)
    private func updateImagePosition() {
        // LẤY VIEW CHA LÀM HỆ QUY CHIẾU: Thay vì chui vào tận CanvasModel để lấy `canvasContentView`
        // Nhờ vậy file này hoàn toàn mù tịt về CanvasModel, đảm bảo tính độc lập tuyệt đối.
        guard let cv = self.superview else { return }
        
        // Copy toạ độ hiện tại ra một biến tạm để tính toán
        var transformToUpdate = self.currentTransform!
        var hasChanges = false
        
        // 1. Logic Tính Toán Kéo (Drag)
        let isPanActive = panGesture.isActive == true || panGesture.state == .ended
        if isPanActive {
            // Tính khoảng cách ngón tay đã trượt trên màn hình (hệ quy chiếu `cv`)
            let translation = panGesture.translation(in: cv)
            if translation != .zero {
                // Cộng dồn vào toạ độ x, y
                transformToUpdate.center.x += translation.x
                transformToUpdate.center.y += translation.y
                // Reset lại quãng đường của hệ thống để không bị cộng dồn theo cấp số nhân ở frame tiếp theo
                panGesture.setTranslation(.zero, in: cv)
                hasChanges = true
            }
        }
        
        // 2. Logic Tính Toán Phóng To (Zoom) và Xoay (Rotate)
        let isPinchActive = pinchGesture.isActive == true || pinchGesture.state == .ended
        let isRotateActive = rotateGesture.isActive == true || rotateGesture.state == .ended
        
        // Lấy hệ số phóng to và góc xoay từ ngón tay
        let scale = isPinchActive ? pinchGesture.scale : 1.0
        let rotation = isRotateActive ? rotateGesture.rotation : 0.0
        
        if scale != 1.0 || rotation != 0.0 {
            // Xác định tâm xoay (Mặc định là tâm của bức ảnh)
            var focalPoint = transformToUpdate.center
            
            // Nếu người dùng dùng 2 ngón tay, thì tâm xoay phải là điểm chính giữa 2 ngón tay đó
            if isPinchActive, pinchGesture.numberOfTouches >= 2 {
                focalPoint = pinchGesture.location(in: cv)
            } else if isRotateActive, rotateGesture.numberOfTouches >= 2 {
                focalPoint = rotateGesture.location(in: cv)
            } else if isPanActive, panGesture.numberOfTouches >= 2 {
                focalPoint = panGesture.location(in: cv)
            }
            
            // Dùng API CGAffineTransform để dịch chuyển ma trận về tâm ngón tay, sau đó Xoay/Scale, rồi dịch trả về vị trí cũ
            var transform = CGAffineTransform(translationX: focalPoint.x, y: focalPoint.y)
            transform = transform.scaledBy(x: scale, y: scale)
            transform = transform.rotated(by: rotation)
            transform = transform.translatedBy(x: -focalPoint.x, y: -focalPoint.y)
            
            // Áp dụng ma trận vừa tính vào toạ độ trung tâm của cấu trúc GestureTransform
            transformToUpdate.center = transformToUpdate.center.applying(transform)
            transformToUpdate.scale *= scale
            transformToUpdate.rotation += Double(rotation)
            
            // Lại reset các biến của hệ thống về mặc định để tránh cộng dồn
            pinchGesture.scale = 1.0
            rotateGesture.rotation = 0.0
            hasChanges = true
        }
        
        // 3. Xả Dữ Liệu
        // Nếu qua 2 bước trên mà có sự thay đổi toạ độ thật sự
        if hasChanges {
            // Lưu đè lại biến nội bộ để lần vuốt tiếp theo có điểm gốc mới
            self.currentTransform = transformToUpdate
            
            // BẮN DATA RA NGOÀI qua ống xả onChanged!
            self.onChanged?(transformToUpdate)
        }
    }
    
    // Gom luồng tính toán vào Task MainActor để giao diện không bị giật lag khi ngón tay vuốt quá nhanh
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
    
    // Hàm này của UIKit: Cấp phép cho nhận nhiều ngón tay cùng lúc (VD: Vừa kéo vừa xoay đồng thời)
    func gestureRecognizer(_ gesture : UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Chỉ cho phép đồng thời nếu 2 gesture đều thuộc về file Coordinator này
        return otherGestureRecognizer.delegate === self
    }
    
    // Cầu nối từ Objective-C Selector sang hàm xử lý State của Swift
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) { handleGestureStateChange(gesture) }
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) { handleGestureStateChange(gesture) }
    @objc func handleRotate(_ gesture: UIRotationGestureRecognizer) { handleGestureStateChange(gesture) }
}

// Bổ trợ kiểm tra xem ngón tay có đang hoạt động hay không
private extension UIGestureRecognizer {
    var isActive: Bool {
        return state == .began || state == .changed
    }
}
