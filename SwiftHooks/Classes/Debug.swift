//
//  Debug.swift
//  SwiftHooks
//
//  Created by stephenwzl on 2023/11/17.
//

import Foundation
import ObjectiveC

func DebugLog(_ str: String) {
    debugPrint("[SwiftHooks]:" + str)
}

private var FiberNodeKey: UInt8 = 0
private var FiberContextKey: UInt8 = 0
extension NSObject {
    var fiberNode: FiberNode? {
        get {
            return objc_getAssociatedObject(self, &FiberNodeKey) as? FiberNode
        }
        set {
            objc_setAssociatedObject(self, &FiberNodeKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    var fiberContext: Context? {
        get {
            return objc_getAssociatedObject(self, &FiberContextKey) as? Context
        }
        set {
            objc_setAssociatedObject(self, &FiberContextKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
