//
//  CanvasScrollView.swift
//  Test1
//

import SwiftUI

/*
 =========================== UIViewRepresentable========================
 
 - UIViewRepresentable: là 1 protocol giúp wrap 1 View của UIKit thành 1 View của SwiftUI để dùng chung với code SwiftUI

 =======================================================================
 Trong quá trình app chạy, hàm updateUIView của bạn bị gọi đi gọi lại hàng chục lần.
 Nếu có những biến tạm thời không muốn bị mất đi sau mỗi lần SwiftUI re-render -> để vào Coordinator để lưu trữ
 (nó không bị huỷ đi mỗi lần SwiftUI re-render).
 
 */

public struct CanvasScrollView: UIViewRepresentable {
    public var size: CGSize
    public var backgroundColor: UIColor
    public var canvasColor: UIColor
    public var isScrollEnabled: Bool
    public var onSetup: ((UIScrollView, UIView) -> Void)?
    public var onZoom: ((CGFloat) -> Void)?
    public let viewSwiftUI: AnyView

    public init(
        size: CGSize,
        backgroundColor: UIColor = .black,
        canvasColor: UIColor = .yellow,
        isScrollEnabled: Bool = true,
        onSetup: ((UIScrollView, UIView) -> Void)? = nil,
        onZoom: ((CGFloat) -> Void)? = nil,
        viewSwiftUI: AnyView
    ) {
        self.size = size
        self.backgroundColor = backgroundColor
        self.canvasColor = canvasColor
        self.isScrollEnabled = isScrollEnabled
        self.onSetup = onSetup
        self.onZoom = onZoom
        self.viewSwiftUI = viewSwiftUI
    }

    // MARK: - Coordinator

    public class Coordinator: NSObject, UIScrollViewDelegate {
        public var contentView: UIView?
        public var hostingController: UIHostingController<AnyView>?
        public var didLoad = false
        public var onZoom: ((CGFloat) -> Void)?
        
        public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return contentView
        }

        public func scrollViewDidZoom(_ scrollView: UIScrollView) {
            centerContent(scrollView)
            onZoom?(scrollView.zoomScale)
        }

        public func centerContent(_ scrollView: UIScrollView) {
            guard let cv = contentView else { return }
            let boundsSize = scrollView.bounds.size
            let frame = cv.frame
            let offsetX = max((boundsSize.width  - frame.width)  * 0.5, 0)
            let offsetY = max((boundsSize.height - frame.height) * 0.5, 0)
            cv.center = CGPoint(
                x: frame.width  * 0.5 + offsetX,
                y: frame.height * 0.5 + offsetY
            )
        }

        // Chạy 1 lần sau khi layout hoàn tất
        public func initOnce(_ scrollView: UIScrollView) {
            guard !didLoad else { return }
            didLoad = true
            centerContent(scrollView)
        }
    }

    public func makeCoordinator() -> Coordinator { Coordinator() }

    // A. Khởi tạo UIScrollView
    public func makeUIView(context: Context) -> CanvasCustomScrollView {
        let scrollView = CanvasCustomScrollView()
        context.coordinator.onZoom = onZoom
        scrollView.delegate = context.coordinator

        scrollView.showsVerticalScrollIndicator   = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom                    = true
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.backgroundColor = backgroundColor
        scrollView.clipsToBounds   = true
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 5.0

        let hosting = UIHostingController(rootView: viewSwiftUI)
        hosting.view.backgroundColor = canvasColor
        hosting.view.frame.size      = CanvasSize
        hosting.view.clipsToBounds   = false // cho phép tràn viền

        scrollView.addSubview(hosting.view)
        scrollView.hostingView = hosting.view
        scrollView.contentSize = CanvasSize
        context.coordinator.contentView = hosting.view
        context.coordinator.hostingController = hosting

        onSetup?(scrollView, hosting.view)
        return scrollView
    }

    // B. Update khi SwiftUI state đổi
    public func updateUIView(_ scrollView: CanvasCustomScrollView, context: Context) {
        context.coordinator.onZoom = onZoom
        context.coordinator.hostingController?.rootView = viewSwiftUI
        
        // update scroll view state
        scrollView.isScrollEnabled = self.isScrollEnabled
        scrollView.pinchGestureRecognizer?.isEnabled = self.isScrollEnabled
        
        DispatchQueue.main.async {
            context.coordinator.initOnce(scrollView)
        }
    }
}

// MARK: - Tự viết lại cơ chế xác định view nào được chạm (hit test) thay vì dùng mặc định của UIKit.

public class CanvasCustomScrollView: UIScrollView {
    public weak var hostingView: UIView?

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard self.point(inside: point, with: event) else { return nil } // check ngón tay có nằm trong scrollview k ? , trả về true false
        
        // image còn trong bound
        let result = super.hitTest(point, with: event)        
        // trả về hostingView để nhường quyền gesture cho SwiftUI ( lúc image đi ra ngoài bound )
        if let hosting = hostingView {
            
            return hosting
        }
        return result
    }
}

