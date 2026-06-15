//
//  CanvasScrollView.swift
//  Test1Final
//
//  Created by Hai Nam on 15/6/26.
//

import UIKit
import SwiftUI


public struct CanvasScrollView<ViewSwiftUI: View > : UIViewRepresentable {
    
    // MARK: - 1. Init Data State
    public var size: CGSize
    public var isScrollEnabled: Bool // State enable pan ScrollView
    
    public var backgroundColor: UIColor?
    public var canvasColor: UIColor?
    
    // callback
    public var onSetup: ((UIScrollView, UIView) -> Void)?
    public var onZoom: ((CGFloat) -> Void)?
    public var onScroll: ((CGPoint) -> Void)?
    
    public let content: ViewSwiftUI // content in canvas = viewSwiftUI
    
    public init(
            size: CGSize,
            isScrollEnabled: Bool = true,
            backgroundColor: UIColor? = nil,
            canvasColor: UIColor? = nil,
            onSetup: ((UIScrollView, UIView) -> Void)? = nil,
            onZoom: ((CGFloat) -> Void)? = nil,
            onScroll: ((CGPoint) -> Void)? = nil,
            @ViewBuilder content: () -> ViewSwiftUI
    ){
        self.size = size
        self.isScrollEnabled = isScrollEnabled
        self.backgroundColor = backgroundColor
        self.canvasColor = canvasColor
        self.onSetup = onSetup
        self.onZoom = onZoom
        self.onScroll = onScroll
        self.content = content()
    }
    
    // MARK: - Coordinator
    
    public class Coordinator: NSObject, UIScrollViewDelegate {
        var hostingController: UIHostingController<ViewSwiftUI>?
        var didLoad = false
        var onZoom: ((CGFloat) -> Void)? // storage closure zoom
        var onScroll: ((CGPoint) -> Void)? // storage closure scroll
        
        public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return hostingController?.view
        }
        
        public func scrollViewDidZoom(_ scrollView: UIScrollView) {
            centerContent(scrollView)
            onZoom?(scrollView.zoomScale) // Báo cáo tỉ lệ zoom ra ngoài SwiftUI.
        }
        
        public func scrollViewDidScroll(_ scrollView: UIScrollView) {
            onScroll?(scrollView.contentOffset) // Báo cáo toạ độ x, y ra ngoài SwiftUI.
        }
        
        // MARK: - CENTER CANVAS
        func centerContent(_ scrollView: UIScrollView) {
            guard let cv = hostingController?.view else { return }
            let boundsSize = scrollView.bounds.size // Kích thước khung hình của ScrollView
            let frame = cv.frame // Kích thước thực tế của nội dung sau khi bị zoom
                    
            // Tính toán khoảng trống dư thừa, chia đôi để lấy căn lề
            let offsetX = max((boundsSize.width  - frame.width)  * 0.5, 0)
            let offsetY = max((boundsSize.height - frame.height) * 0.5, 0)
                    
            // Cập nhật lại center content
            cv.center = CGPoint(
                x: frame.width  * 0.5 + offsetX,
                y: frame.height * 0.5 + offsetY
            )
        }
        
        // init
        func initOnce(_ scrollView: UIScrollView) {
            guard !didLoad else { return }
            didLoad = true
            centerContent(scrollView) // Căn giữa lần đầu tiên
        }
    }
    
    public func makeCoordinator() -> Coordinator { Coordinator() }
    
    // MARK: - makeUIView (Hàm này chỉ chạy đúng 1 lần khi View lần đầu tiên xuất hiện)
    public func makeUIView(context: Context) -> CanvasCustomScrollView {
        let scrollView = CanvasCustomScrollView()
        scrollView.delegate = context.coordinator // gán coordinator làm delegate để nhận event scroll/zoom
        
        // setup config các thuộc tính cơ bản của UIScrollView
        scrollView.showsVerticalScrollIndicator   = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom                    = true // Cho phép hiệu ứng nảy (bounce) khi zoom quá giới hạn
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.backgroundColor = backgroundColor
        scrollView.clipsToBounds   = true // Cắt bỏ những phần nội dung tràn ra ngoài ScrollView
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 5.0
        
        // Khởi tạo UIHostingController để biến SwiftUI View thành UIKit View
        let hosting = UIHostingController(rootView: content)
        hosting.view.backgroundColor = canvasColor
        hosting.view.frame.size      = size
        hosting.view.clipsToBounds   = false
        
        scrollView.addSubview(hosting.view)
        scrollView.hostingView = hosting.view
        scrollView.contentSize = size
        
        context.coordinator.hostingController = hosting
        
        onSetup?(scrollView, hosting.view)
        
        return scrollView
    }
    
    public func updateUIView(_ scrollView: CanvasCustomScrollView, context: Context) {
        scrollView.isScrollEnabled = isScrollEnabled
        scrollView.pinchGestureRecognizer?.isEnabled = isScrollEnabled
        
        context.coordinator.onZoom = onZoom
        context.coordinator.onScroll = onScroll
        
        // update view swiftui
        context.coordinator.hostingController?.rootView = content
        
        // update size
        if scrollView.contentSize != size {
            scrollView.contentSize = size
            context.coordinator.hostingController?.view.frame.size = size
            context.coordinator.centerContent(scrollView)
        }
        
        // update color background
        scrollView.backgroundColor = backgroundColor
        context.coordinator.hostingController?.view.backgroundColor = canvasColor
        
        DispatchQueue.main.async {
            context.coordinator.initOnce(scrollView)
        }
    }
}

// MARK: - Tự viết lại cơ chế xác định view nào được chạm (hit test) thay vì dùng mặc định của UIKit.

public class CanvasCustomScrollView: UIScrollView {
    weak var hostingView: UIView? // Reference tới view chứa SwiftUI
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {

        guard self.point(inside: point, with: event) else { return nil }
        let result = super.hitTest(point, with: event)

        if result == self || result == nil {
            return result
        }
        
        if let hosting = hostingView {
            return hosting
        }
        
        return result
    }
}
