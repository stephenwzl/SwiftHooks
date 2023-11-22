//
//  Context.swift
//  SwiftHooks
//
//  Created by stephenwzl on 2023/11/16.
//

import Foundation

protocol ContextProtocol {}

open class Context: NSObject, ContextProtocol {
    public override init() {}
    
    var deps: [ObjectIdentifier] = []
    internal func addDeps(_ mount: any Fiber&AnyObject) {
        let id = ObjectIdentifier(mount)
        if deps.contains(id) {
            return
        }
        deps.append(id)
    }
    
    internal func execSideEffects() {
        for (index, id) in deps.enumerated() {
            if let node = FiberRoot.shared.fiber(for: id) {
                node.execSideEffect()
            } else {
                deps.remove(at: index)
                DebugLog("context dep \(String(describing: id)) removed")
            }
        }
    }
    
    deinit {
        DebugLog("context \(String(describing: self)) released")
    }
    
}

@propertyWrapper
public struct ContextState<T> {
    public init(wrappedValue: State<T>) {
        value = WeakRef(ref: wrappedValue)
    }
    private var value: WeakRef<State<T>>
    public var wrappedValue: State<T> {
        get { value.ref! }
        set { value = WeakRef(ref: newValue) }
    }
}
