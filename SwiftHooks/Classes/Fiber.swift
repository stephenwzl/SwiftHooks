//
//  Fiber.swift
//  SwiftHooks
//
//  Created by stephenwzl on 2023/11/14.
//

import Foundation
/// Fiber 是可以挂载 State 和 Context的协议，如果想要使用 Hooks，那么当前的 Scope必须要遵循 Fiber协议
///
/// Fiber 在 NSObject上有默认的实现，所以 UIKit中一般都能够使用
public protocol Fiber {
    
    /// 创建受到 Fiber 管理的 state
    ///
    /// - Parameter initialValue: state 的默认值
    /// - Returns: 受到 Fiber 管理的 state 对象
    func useState<T>(_ initialValue: T) -> State<T>
    
    /// 创建受 Fiber 管理的 side effect
    ///
    /// - Parameters:
    ///   - effect: side effect 执行的闭包
    ///   - deps: 依赖的 state，当这些 state 中的任意一个变化时，执行 side effect
    func useEffect(_ effect: @escaping () -> Void, _ deps: [any StateProtocol&AnyObject])
    
    /// 从 Fiber 中获得指定类型的 Context
    ///
    /// 注意：不要强引用 context 对象，否则会造成内存泄漏，context 对象有其自身的管理者
    /// - Parameter context: context 类型
    /// - Returns: context 实例
    func useContext<T:Context>(_ context: T.Type) -> T?
    
    /// 创建受 Fiber 管理的 context
    ///
    /// - Parameters:
    ///   - initialValue: context 实例
    /// - Returns: 可丢弃的返回值
    @discardableResult
    func createContext(_ initialValue: Context) -> Context
}

public extension Fiber where Self: NSObject {
    func useState<T>(_ initialValue: T) -> State<T> {
        let hook = State(state: initialValue, effect: { [weak self] in
            guard let self = self else {
                return
            }
            FiberRoot.shared.execSideEffect(mountPoint: self)
        })
        FiberRoot.shared.pushState(hook, mountPoint: self)
        return hook
    }
    
    func useEffect(_ effect: @escaping () -> Void, _ deps: [any StateProtocol&AnyObject]) {
        FiberRoot.shared.pushSideEffect(effectBlock: effect, deps: deps, mountPoint: self)
    }
    
    func useContext<T:Context>(_ context: T.Type) -> T? {
        let context = FiberRoot.shared.context(for: context)
        context?.addDeps(self)
        return context
    }
    @discardableResult
    func createContext(_ initialValue: Context) -> Context {
        assert(initialValue != self, "context can not attach to itself")
        let dynamicType = type(of: initialValue)
        let key = String(describing: dynamicType)
        FiberRoot.shared.createContext(type: key, value: initialValue, owner: self)
        return initialValue
    }
    
}



