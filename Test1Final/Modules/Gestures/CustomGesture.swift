//
//  CustomGesture.swift
//  Test1Final
//
//  Created by Hai Nam on 15/6/26.
//


import SwiftUI

// MARK: - Struct Data Gesture Template
public struct TranformState {
    public var center: CGPoint
    public var scale: CGFloat
    public var rotation: Double
    
    public init(center: CGPoint, scale: CGFloat, rotation: Double) {
        self.center = center
        self.scale = scale
        self.rotation = rotation
    }
}

// MARK: -  STRUCT Gesture
public struct CustomGesture {
    public var getState: () -> TranformState
    public var isEnabled: Bool // cho phép view nhận tương tác
    public var canvasCoordinateView: UIView? // Truyền View Background vào nếu: Bức ảnh có xoay, hoặc Background có zoom. Còn lại để nil
    
    public var canPan: Bool
    public var canZoom: Bool
    public var canRotate: Bool
    
    // callback
    var changedAction : ((TranformState) -> Void)?
    var endedAction: ((TranformState) -> Void)?
    var touchStateAction: ((Bool) -> Void)?
    
    public init(
        getState: @escaping () -> TranformState,
        isEnabled: Bool = true,
        canvasCoordinateView: UIView? = nil,
        canPan: Bool = true,
        canZoom: Bool = true,
        canRotate: Bool = true
    ) {
        self.getState = getState
        self.isEnabled = isEnabled
        self.canvasCoordinateView = canvasCoordinateView
        self.canPan = canPan
        self.canZoom = canZoom
        self.canRotate = canRotate
    }
    
    // MARK: - method onChanged
    
    public func onChanged(_ action: @escaping (TranformState) -> Void) -> Self {
        var updatedGesture = self
        updatedGesture.changedAction = action
        return updatedGesture
    }
    
    // MARK: - medthod onEnded
    
    public func onEnded(_ action: @escaping (TranformState) -> Void) -> Self {
        var updatedGesture = self
        updatedGesture.endedAction = action
        return updatedGesture
    }
    
    // MARK: - method active ScrollView
    
    public func onTouchStateChanged(_ action: @escaping (Bool) -> Void) -> Self {
        var a = self
        a.touchStateAction = action
        return a
    }
}


public extension View {
    func customGesture(_ gesture: CustomGesture) -> some View {
        self.overlay(
            CustomGestureRepresentable(
                getState: gesture.getState,
                isEnabled: gesture.isEnabled,
                canPan: gesture.canPan,
                canZoom: gesture.canZoom,
                canRotate: gesture.canRotate,
                canvasCoordinateView: gesture.canvasCoordinateView,
                onChanged: gesture.changedAction,
                onEnded: gesture.endedAction,
                onTouchStateChanged: gesture.touchStateAction
            )
        )
    }
}
