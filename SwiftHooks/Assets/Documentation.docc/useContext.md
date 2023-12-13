# useContext
Share states among multiple scopes.

## Overview

In order to share states among different scopes, you need to ``Fiber/createContext(_:)`` first.  
Then you can use ``Fiber/useContext(_:)`` to access the context.

### Create a context
Assuming you have a ``Fiber`` class managing states, you can create a context like this:

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
This context with bridge the state `count` for other scopes. But the memory owner of the state is still `AnyNSObjectClass`.

### Using context and its states
After creating context, you can access it in other scopes.
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
In this example, the effect will be called when `count` changes.

### Context manage states itself.
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
