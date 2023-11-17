//
//  FiberRoot.swift
//  SwiftHooks
//
//  Created by stephenwzl on 2023/11/16.
//

import Foundation

private typealias ContextPair = (context: Context, ownerId: ObjectIdentifier, ownerRef: WeakRef<AnyObject>)

class FiberRoot {
    static let shared = FiberRoot()
    
    private var contexts = [String: ContextPair]()
    
    private var fibers = [ObjectIdentifier: FiberNode]()
    
    private func fiber(_ for: AnyObject) -> FiberNode? {
        let id = ObjectIdentifier(`for`)
        return fiber(for: id, owner: `for`)
    }
    
    internal func fiber(for id: ObjectIdentifier, owner: AnyObject? = nil) -> FiberNode? {
        defer {
            scheduleCompactFiberNode()
        }
        if let node = fibers[id] {
            if node.canbeReleased() {
                fibers.removeValue(forKey: id)
                DebugLog("fiber node \(String(describing: id)) released")
                return nil
            }
            return node
        }
        if let owner {
            fibers[id] = FiberNode(owner: WeakRef(ref: owner))
        }
        return fibers[id]
    }
    
    func context<T:Context>(for type: T.Type) -> T? {
        defer {
            scheduleCompactContext()
        }
        let key = String(describing: type)
        guard let pair = self.contexts[key] else {
            return nil
        }
        if pair.ownerRef.isEmpty {
            contexts.removeValue(forKey: key)
            DebugLog("context \(key) released")
            return nil
        }
        return pair.context as? T
    }
    
    private func context(for owner: ObjectIdentifier) -> [Context] {
        defer {
            scheduleCompactContext()
        }
        var contexts = [Context]()
        for (_, pair) in self.contexts {
            if pair.ownerId == owner && pair.ownerRef.isEmpty == false {
                contexts.append(pair.context)
            } else {
                // 如果这个 owner 已经释放了，那么说明所有关联的 context 都已经释放了
                return []
            }
        }
        return contexts
    }
    
    func pushState(_ hook: AnyObject, mountPoint: AnyObject) {
        fiber(mountPoint)?.pushState(hook)
    }
    
    func pushSideEffect(effectBlock: @escaping () -> Void, deps: [AnyObject], mountPoint: AnyObject) {
        fiber(mountPoint)?.pushSideEffect(effectBlock: effectBlock, deps: deps)
    }
    
    func execSideEffect(mountPoint: AnyObject) {
        fiber(mountPoint)?.execSideEffect()
        // fiber 关联的 context 也需要执行
        // 如果这个 fiber 已经释放了，那么对应的 deps 也要移除
        for context in context(for: ObjectIdentifier(mountPoint)) {
            context.execSideEffects()
        }
    }
    
    
    
    /// 自动释放不再使用的 fiber Node
    /// TODO：这个方法可能在某些循环中会被多次调用，后期优化可以合并
    private func scheduleCompactFiberNode() {
        Task.detached { @MainActor in
            for (id, node) in self.fibers {
                if node.canbeReleased() {
                    self.fibers.removeValue(forKey: id)
                    DebugLog("fiber node \(String(describing: id)) released")
                }
            }
        }
    }
    
    /// 自动释放不再使用的 context
    /// TODO：这个方法可能在某些循环中会被多次调用，后期优化可以合并
    private func scheduleCompactContext() {
        Task.detached { @MainActor in
            var toRemove: [String] = []
            for (id, pair) in self.contexts {
                if pair.ownerRef.isEmpty {
                    toRemove.append(id)
                }
            }
            if toRemove.count > 0 {
                toRemove.forEach({ self.contexts.removeValue(forKey: $0) })
                DebugLog("context \(toRemove) released")
            }
        }
    }
    
    func createContext(type: String, value: Context, owner: AnyObject) {
        contexts[type] = (value, ObjectIdentifier(owner), WeakRef(ref: owner))
    }
}

class FiberNode {
    var states: [WeakRef<AnyObject>] = []
    var sideEffects: [(effect: () -> Void, deps:[WeakRef<AnyObject>])] = []
    var memoDeps: [[String]] = []
    var owner: WeakRef<AnyObject>
    
    init(owner: WeakRef<AnyObject>) {
        self.owner = owner
    }
    
    func pushState(_ hook: AnyObject) {
        states.append(WeakRef(ref: hook))
    }
    func pushSideEffect(effectBlock: @escaping () -> Void, deps: [AnyObject]) {
        let refs = deps.map({ WeakRef(ref: $0)})
        sideEffects.append((effectBlock, refs))
        memoDeps.append(refs.map({ $0.sig ?? ""}))
        effectBlock() // execute by default
        if memoDeps.count != sideEffects.count {
            assertionFailure("some error occurred on FiberRoot")
        }
    }
    
    func execSideEffect() {
        let currentDeps = sideEffects.map({ $0.1.map({$0.sig ?? ""}) })
        for (index, deps) in currentDeps.enumerated() {
            if deps != memoDeps[index] {
                sideEffects[index].effect()
                memoDeps[index] = deps
            }
        }
        
    }
    
    /// 当一个 fiber node 中的所有 state 都已经被释放的时候，这个 fiber node 可以被释放
    /// - Returns: 是否可以释放
    func canbeReleased() -> Bool {
        self.owner.isEmpty
    }
}
