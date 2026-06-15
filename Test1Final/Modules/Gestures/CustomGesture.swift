//
//  CustomGesture.swift
//  Test1Final
//
//  Created by Hai Nam on 15/6/26.
//

import SwiftUI

// MARK: - Struct Data Gesutre Template
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
    var transform: TranformState
    var isEnabled: Bool
    var canPan: Bool = true
    var canZoom: Bool = true
    var canRotate: Bool = true
    
    // callback
    var changedAction : ((TranformState) -> Void)?
    var endedAction: ((TranformState) -> Void)?
    var touchStateAction: ((Bool) -> Void)?
    
    public init(transform: TranformState, isEnabled: Bool = true) {
        self.transform = transform
        self.isEnabled = isEnabled
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
                stateTransform: gesture.transform,
                isEnabled: gesture.isEnabled,
                canPan: gesture.canPan,
                canZoom: gesture.canZoom,
                canRotate: gesture.canRotate,
                onChanged: gesture.changedAction,
                onEnded: gesture.endedAction,
                onTouchStateChanged: gesture.touchStateAction
            )
        )
    }
}
