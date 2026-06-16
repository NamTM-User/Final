//
//  CanvasUIState.swift
//  Test1Final
//

import SwiftUI
import UIKit
import Observation

@Observable
public class CanvasUIState {
    public weak var scrollView: UIScrollView?
    public var cameraZoom: CGFloat = 1.0
    
    public var currentCenter: CGPoint {
        guard let sv = scrollView else { return CGPoint(x: 123, y: 456) } // Default fallback
        return CGPoint(
            x: (sv.contentOffset.x + sv.bounds.width / 2) / sv.zoomScale,
            y: (sv.contentOffset.y + sv.bounds.height / 2) / sv.zoomScale
        )
    }
}
