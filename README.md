# SwiftHooks

## Example

### using state

> create a data state managed by SwiftHooks, and accessing it's value when it's changed

```swift
class AnyNSObjectClass: Fiber {
    lazy var count = useState(0)
    
    func someFuncCalledOnce() {
        // use side effect to observe for count changes
        useEffect({ [unowned self] in
            self.label.text = "\(self.count.state)"
        }, [count]);
    }
    
    // change state value
    func increment() {
        self.count.setState(self.count.state + 1)
    }
}
```

### using context

> context is a way for you to share states between different scopes

First of al, you need to declare a context type, context can managing states by other providers

```swift
class MyContext: Context {
    @ContextState var count: State<Int>
    init(count: State<Int>) {
        self.count = count
    }
}

class AnyNSObjectClass: Fiber {
    lazy var count = useState(0)
    lazy var context = MyContext(count: self.count)
    
    func someFuncCalledOnce() {
        createContext(self.context)
    }
}
```
Then you can access and observe state managed by this context in other scope.
```swift
class AnotherNSObjectClass: Fiber {
    func doSomething() {
        guard let context = useContext(MyContext.self) else {
            return
        }
        useEffect({ [unowned context] in
            print(context.count.state)
        }, [context.count])
    }

}
```

Also, you can use context as a ViewModel, and manage states by it self.
```swift
class MyContext: Context, Fiber {
    lazy var count = useState(0)
}
// do not forget to attach context, it need other objects to maintain its memory lifecycle
class AnyNSObjectClass: Fiber {
    lazy var context = MyContext()
    
    func someFuncCalledOnce() {
        createContext(self.context)
    }
    
    func accessingSample() {
        self.context.count.setState(1)
    }
}
```

## Requirements

## Installation

SwiftHooks is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'SwiftHooks'
```

## Author

stephenwzl, stephenwzlwork@gmail.com 

## License

SwiftHooks is available under the MIT license. See the LICENSE file for more info.
