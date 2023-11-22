//
//  Fiber.swift
//  SwiftHooks
//
//  Created by stephenwzl on 2023/11/14.
//

import Foundation

public protocol Fiber {
    
    /// 创建受到 Fiber 管理的 state，使用方法：
    /// `lazy var count = useState(10)`
    /// 如果需要可选类型，需要显式声明类型
    /// 例如：`lazy var count: State<Int?> = useState(nil)`
    /// - Parameter initialValue: state 的默认值
    /// - Returns: 受到 Fiber 管理的 state 对象
    func useState<T>(_ initialValue: T) -> State<T>
    
    /// 创建受 Fiber 管理的 side effect，使用方法：
    /// `useEffect({ print(count.state) }, [count])`
    /// - Parameters:
    ///   - effect: side effect 执行的闭包
    ///   - deps: 依赖的 state，当这些 state 中的任意一个变化时，执行 side effect
    func useEffect(_ effect: @escaping () -> Void, _ deps: [any StateProtocol&AnyObject])
    
    /// 从 Fiber 中获得指定类型的 Context，使用方法：
    /// `let context = useContext(FooContext.self)`
    /// 注意：不要强引用 context 对象，否则会造成内存泄漏，context 对象有其自身的管理者
    /// - Parameter context: context 类型
    /// - Returns: context 实例
    func useContext<T:Context>(_ context: T.Type) -> T?
    
    /// 创建受 Fiber 管理的 context，使用方法：
    /// `createContext(FooContext.self, FooContext(count: count))`
    /// - Parameters:
    ///   - initialValue: context 实例
    /// - Returns: 无返回
    @discardableResult
    func createContext(_ initialValue: Context) -> Context
}

public extension Fiber where Self: UIResponder {
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
        let dynamicType = type(of: initialValue)
        let key = String(describing: dynamicType)
        FiberRoot.shared.createContext(type: key, value: initialValue, owner: self)
        return initialValue
    }
    
}



