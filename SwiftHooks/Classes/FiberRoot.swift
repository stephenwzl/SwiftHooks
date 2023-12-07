//
//  FiberRoot.swift
//  SwiftHooks
//
//  Created by stephenwzl on 2023/11/16.
//

import Foundation

private typealias ContextPair = (context: WeakRef<Context>, ownerId: ObjectIdentifier)

class FiberRoot {
    static let shared = FiberRoot()
    
    private init() {
        setupAutoRelease()
    }
    
    private var contexts = [String: ContextPair]()
    
    private var fibers = [ObjectIdentifier: WeakRef<FiberNode>]()
    
    private func fiber(_ for: NSObject) -> FiberNode? {
        let id = ObjectIdentifier(`for`)
        return fiber(for: id, owner: `for`)
    }
    
    internal func fiber(for id: ObjectIdentifier, owner: NSObject? = nil) -> FiberNode? {
        if let node = fibers[id]?.ref {
            if node.canbeReleased() {
                fibers.removeValue(forKey: id)
                DebugLog("fiber node \(String(describing: id)) released")
                return nil
            }
            return node
        } else {
            fibers.removeValue(forKey: id)
        }
        if let owner {
            let node = FiberNode(owner: WeakRef(ref: owner))
            owner.fiberNode = node
            fibers[id] = WeakRef(ref: node)
        }
        return fibers[id]?.ref
    }
    
    func context<T:Context>(for type: T.Type) -> T? {
        let key = String(describing: type)
        guard let pair = self.contexts[key] else {
            return nil
        }
        
        if pair.context.isEmpty {
            contexts.removeValue(forKey: key)
            DebugLog("context \(key) released")
            return nil
        }
        return pair.context.ref as? T
    }
    
    private func context(for owner: ObjectIdentifier) -> [Context] {
        var contexts = [Context]()
        for (_, pair) in self.contexts {
            if pair.ownerId == owner, let context = pair.context.ref {
                contexts.append(context)
            } else {
                // 如果这个 owner 已经释放了，那么说明所有关联的 context 都已经释放了
                return []
            }
        }
        return contexts
    }
    
    func pushState(_ hook: AnyObject, mountPoint: NSObject) {
        fiber(mountPoint)?.pushState(hook)
    }
    
    func pushSideEffect(effectBlock: @escaping () -> Void, deps: [AnyObject], mountPoint: NSObject) {
        fiber(mountPoint)?.pushSideEffect(effectBlock: effectBlock, deps: deps)
    }
    
    func execSideEffect(mountPoint: NSObject) {
        fiber(mountPoint)?.execSideEffect()
        // fiber 关联的 context 也需要执行
        // 如果这个 fiber 已经释放了，那么对应的 deps 也要移除
        for context in context(for: ObjectIdentifier(mountPoint)) {
            context.execSideEffects()
        }
        // FIXED: 如果 mount point 本身就是一个 context，那么它的 side effect 也需要执行
        // 上面的方法无法执行得到
        if let mountPointContext = mountPoint as? Context {
            mountPointContext.execSideEffects()
        }
    }
    
    private func setupAutoRelease() {
        // 定义一个回调函数
        let runLoopObserverCallback: CFRunLoopObserverCallBack = { observer, activity, context in
            // 在这里执行你想在 RunLoop 空闲时进行的操作
            FiberRoot.shared.scheduleCompactFiberNode()
            FiberRoot.shared.scheduleCompactContext()
        }

        // 创建 RunLoop 观察者
        if let observer = CFRunLoopObserverCreate(nil, CFRunLoopActivity.beforeWaiting.rawValue, true, 0, runLoopObserverCallback, nil) {
            // 将观察者添加到主 RunLoop
            CFRunLoopAddObserver(CFRunLoopGetMain(), observer, .defaultMode)
        }
    }
    
    
    /// 自动释放不再使用的 fiber Node
    /// TODO：这个方法可能在某些循环中会被多次调用，后期优化可以合并
    private func scheduleCompactFiberNode() {
        for (id, node) in self.fibers {
            if node.isEmpty {
                self.fibers.removeValue(forKey: id)
                DebugLog("fiber node \(String(describing: id)) released")
            }
        }
    }
    
    /// 自动释放不再使用的 context
    /// TODO：这个方法可能在某些循环中会被多次调用，后期优化可以合并
    private func scheduleCompactContext() {
        var toRemove: [String] = []
        for (id, pair) in self.contexts {
            if pair.context.isEmpty {
                toRemove.append(id)
            }
        }
        if toRemove.count > 0 {
            toRemove.forEach({ self.contexts.removeValue(forKey: $0) })
            DebugLog("context \(toRemove) released")
        }
    }
    
    func createContext(type: String, value: Context, owner: NSObject) {
        owner.fiberContext = value
        contexts[type] = (WeakRef(ref: value), ObjectIdentifier(owner))
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
                memoDeps[index] = deps
                sideEffects[index].effect()
            }
        }
        
    }
    
    /// 当一个 fiber node 中的所有 state 都已经被释放的时候，这个 fiber node 可以被释放
    /// - Returns: 是否可以释放
    func canbeReleased() -> Bool {
        self.owner.isEmpty
    }
}
