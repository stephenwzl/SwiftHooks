# useEffect

Observe state changes and perform side effects.

## Overview

After creating states, you can observe for their changes and perform side effects.

### Observe State Changes

```swift
class YourNSObjectClass: Fiber {
    // non-optional
    lazy var count = useState(0)
    // optional
    lazy var times: State<Int?> = useState(nil)

    func someFuncCalledOnce() {
        useEffect({ [unowned self] in
            self.label.text = "\(self.count.state)"
        }, [count]);
    }
}
```

The ``Fiber/useEffect(_:_:)`` function takes two parameters:  
- `effect`: A closure that will be called when state changes.
- `dependencies`: An array of states that the effect depends on.

SwiftHooks do not retain any external variables, so you need to use `[unowned self]` to avoid retain cycles.

### Effect Dependencies
Side effects are executed when dependencies changes. This means any state changes in dependency array will cause side effects.
For example:
```swift
class YourNSObjectClass: Fiber {
    // non-optional
    lazy var count = useState(0)
    // optional
    lazy var times: State<Int?> = useState(nil)

    func someFuncCalledOnce() {
        useEffect({ [unowned self] in
            self.label.text = "\(self.count.state) \(self.times.state ?? 0)"
        }, [count, times]);
    }
}
```
In this example, the effect will be called when `count` or `times` changes.

### Avoid cycling effects
By depend states eachother, you can combine multiple states into one. But you need to be careful to avoid cycling effects.
What you should:
```swift
class YourNSObjectClass: Fiber {
    // non-optional
    lazy var count = useState(0)
    // optional
    lazy var times: State<Int?> = useState(nil)

    lazy var text = useState("")

    func someFuncCalledOnce() {
        useEffect({ [unowned self] in
            self.text.setState("\(self.count.state) \(self.times.state ?? 0)")
        }, [count, times]);
        useEffect({ [unowned self] in
            self.label.text = self.text.state
        }, [text])
    }
}
```
In this case, we combine state `count` and `times` into `text`, no cycling effects will happen.

What you should not:
```swift
class YourNSObjectClass: Fiber {
    // non-optional
    lazy var count = useState(0)
    // optional
    lazy var times: State<Int?> = useState(nil)

    lazy var text = useState("")

    func someFuncCalledOnce() {
        useEffect({ [unowned self] in
            self.text.setState("\(self.count.state) \(self.times.state ?? 0)")
        }, [count, times]);
        useEffect({ [unowned self] in
            self.label.text = self.text.state
            self.count.setState(0)
        }, [text])
    }
}
```
In this bad case, we combine two state into one, but we also change one of them in the effect. This will cause cycling effects.
