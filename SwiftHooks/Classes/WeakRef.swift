//
//  WeakRef.swift
//  SwiftHooks
//
//  Created by stephenwzl on 2023/11/16.
//

import Foundation

/// 弱引用包一层对象中使用的任何 var
/// 当对象中挂载的 var 释放后，这里的 ref 会自动置 nil
class WeakRef<T: AnyObject> {
    weak var ref: T?
    init(ref: T) {
        self.ref = ref
    }
    var sig: String? {
        (ref as? any StateProtocol)?.sig
    }
    var isEmpty: Bool {
        ref == nil
    }
}
