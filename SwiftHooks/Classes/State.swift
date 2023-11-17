//
//  State.swift
//  SwiftHooks
//
//  Created by stephenwzl on 2023/11/16.
//

import Foundation


public protocol StateProtocol {
    var sig: String { get }
}

public final class State<T>: StateProtocol {
    public var sig: String {
        signature
    }
    
    var signature: String = UUID().uuidString
    public var state: T {
        didSet {
            self.effect()
        }
    }
    public func setState(_ newValue: T) -> Void {
        signature = UUID().uuidString // update signature
        state = newValue
    }
    let effect: () -> Void
    
    init(state: T, effect: @escaping () -> Void) {
        self.state = state
        self.effect = effect
    }
}
