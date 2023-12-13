import XCTest
import SwiftHooks

class Tests: XCTestCase {
    
    var testFoo: TestFiberNodeFoo!
    var testBar: TestFiberNodeBar!
    
    override func setUp() {
        super.setUp()
        testFoo = TestFiberNodeFoo()
        testBar = TestFiberNodeBar()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testEffectWorks() {
        var currentValue = 2
        testFoo.count.setState(currentValue)
        var calledCount = 0
        testFoo.observeEffect {
            XCTAssertEqual(self.testFoo.count.state, currentValue)
            calledCount += 1
        }
        // loop 3times
        for _ in 0..<3 {
            currentValue += 1
            testFoo.count.setState(currentValue)
        }
        XCTAssertEqual(calledCount, 4)
    }
    
    func testContextObserve() {
        testFoo.registerContext()
        var currentValue = 2
        testFoo.count.setState(currentValue)
        var calledCount = 0
        testBar.observeFooState({ value in
            calledCount += 1
            XCTAssertEqual(value, currentValue)
        }) {
            XCTFail("should not failed")
        }
        // loop 3times
        for _ in 0..<3 {
            currentValue += 1
            testFoo.count.setState(currentValue)
        }
        XCTAssertEqual(calledCount, 4)
    }
    
    func testContextStateObserve() {
        testFoo.registerContext()
        var currentValue = 2
        testFoo.context.ownedCount.setState(currentValue)
        var calledCount = 0
        testBar.observeContextState({ value in
            XCTAssertEqual(value, currentValue)
            calledCount += 1
        }) {
            XCTFail("should not failed")
        }
        // loop 3times
        for _ in 0..<3 {
            currentValue += 1
            testFoo.context.ownedCount.setState(currentValue)
        }
        XCTAssertEqual(calledCount, 4)
    }
    
    func testStateDependency() {
        var currentValue = 2
        var calledCount = 0
        testFoo.count.setState(currentValue)
        testFoo.observeCountAdded2 { value in
            XCTAssertEqual(value, currentValue + 2)
            calledCount += 1
        }
//         loop 3times
        for _ in 0..<3 {
            currentValue += 1
            testFoo.count.setState(currentValue)
        }
        // TODO: 这里为什么会调这么多遍？
        XCTAssertEqual(calledCount, 3 + 1)
    }
    
}


class TestFiberNodeFoo: NSObject, Fiber {
    lazy var count = useState(1)
    lazy var countAdd2 = useState(3)
    lazy var context = TestContext(count: self.count)
    
    func registerContext() {
        createContext(context)
    }
    
    func observeEffect(_ action: (() -> Void)?) {
        useEffect({
            action?()
        }, [self.count])
    }
    
    func observeCountAdded2(_ action: ((Int) -> Void)?) {
        useEffect({
            self.countAdd2.setState(self.count.state + 2)
        }, [self.count])
        useEffect({
            action?(self.countAdd2.state)
        }, [self.countAdd2])
    }
}

class TestFiberNodeBar: NSObject, Fiber {
    func observeFooState(_ action: ((Int) -> Void)?, failed: (() -> Void)?) {
        guard let context = useContext(TestContext.self) else {
            failed?()
            return
        }
        useEffect({ [unowned context] in
            action?(context.count.state)
        }, [context.count])
    }
    
    func observeContextState(_ action: ((Int) -> Void)?, failed: (() -> Void)?) {
        guard let context = useContext(TestContext.self) else {
            failed?()
            return
        }
        useEffect({ [unowned context] in
            action?(context.ownedCount.state)
        }, [context.ownedCount])
    }
}

class TestContext: Context, Fiber {
    @ContextState var count: State<Int>
    lazy var ownedCount = useState(1)
    init(count: State<Int>) {
        self.count = count
    }
}
