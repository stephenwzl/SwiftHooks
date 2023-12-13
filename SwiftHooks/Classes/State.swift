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
/// State is a immutable data wrapper
public final class State<T>: StateProtocol {
    /// internal use only
    public var sig: String {
        signature
    }
    
    var signature: String = UUID().uuidString
    /// Readonly, indicates current value of state
    public var state: T {
        get {
            _state
        }
    }
    
    var _state: T {
        didSet {
            self.effect()
        }
    }
    /// State modifier, value only can be set by this method
    public func setState(_ newValue: T) -> Void {
        signature = UUID().uuidString // update signature
        _state = newValue
    }
    let effect: () -> Void
    
    init(state: T, effect: @escaping () -> Void) {
        self._state = state
        self.effect = effect
    }
}
