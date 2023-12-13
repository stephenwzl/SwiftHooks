# useState

Create a data state managed by SwiftHooks, and accessing it's value when it's changed.

## Overview

SwiftHooks can support any type of data state management, but state must be owned by a ``Fiber`` instance. So you should make your class conform to ``Fiber`` protocol. Make sure your class is subclass of `NSObject`.

### Configuring your class

```swift
class YourNSObjectClass: Fiber {
}
```

### Declaring a state
SwiftHooks support both optional and non-optional states. With `lazy var` keywords, you can create states who's memory is maintained by its owner class.  
When you want optional state, you need explict its type with ``State``, because Swift can not infer its type from `nil`.

```swift
class YourNSObjectClass: Fiber {
    // non-optional
    lazy var count = useState(0)
    // optional
    lazy var times: State<Int?> = useState(nil)
}
```

### Change State

```swift
class YourNSObjectClass: Fiber {
    // non-optional
    lazy var count = useState(0)

    func increment() {
        let currentValue = self.count.state
        self.count.setState(currentValue + 1)
    }
}
```

### Observe State Changes
see <doc:useEffect>
