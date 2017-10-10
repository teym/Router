//
//  RouterTests.swift
//  RouterTests
//
//  Created by 王航 on 2017/9/29.
//  Copyright © 2017年 mike. All rights reserved.
//

import XCTest
import Module
@testable import Router

//class Inject:ModuleInject {
//    struct ModuleError:Error {}
//    public func instance<T>() throws -> T {
//        throw ModuleError()
//    }
//}
class MockRouter:NSObject, Router {
    var controllers:[UIViewController] = []
    var router:PathRouter!
    
    func create()->PathRouter{
        self.router = PathRouter(parent: self)
        return self.router
    }
    func push(path:String){
        if let controller = self.router.comptent(url: path){
            controllers.append(controller)
        }
    }
    func replace(path:String){
        if let controller = self.router.comptent(url: path){
            _ = controllers.popLast()
            controllers.append(controller)
        }
    }
    func pop(){
        _ = controllers.popLast()
    }
    func addRouter(path:String,comptent:@escaping (String,[String:String])->UIViewController?){
        self.router.addRouter(path: path, comptent: comptent)
    }
    func addDefaultRouter(comptent:@escaping (String,[String:String])->UIViewController?){
        self.router.addDefaultRouter(comptent: comptent)
    }
    func addSubRouter(path:String, comptent:@escaping (String,[String:String])->Void) -> Router {
        return self.router.addSubRouter(path: path, comptent: comptent)
    }
}
func viewController(title:String) -> UIViewController {
    let ctrl = UIViewController()
    ctrl.title = title
    return ctrl
}

class RouterTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let mock = MockRouter()
        let router = mock.create()

        router.addRouter(path: "/first") { (path, paramers) -> UIViewController? in
            return viewController(title: "first")
        }
        router.push(path: "/first")
        XCTAssert(mock.controllers.last!.title == "first")
        XCTAssert(mock.controllers.count == 1)
        
        router.addRouter(path: "/second") { (path, paramers) -> UIViewController? in
            return viewController(title: "second")
        }
        router.push(path: "/second/")
        XCTAssert(mock.controllers.last!.title == "second")
        XCTAssert(mock.controllers.count == 2)
        
        router.pop()
        XCTAssert(mock.controllers.last!.title == "first")
        XCTAssert(mock.controllers.count == 1)
        
        router.replace(path: "https://www.baidu.com/second?q=1")
        XCTAssert(mock.controllers.last!.title == "second")
        XCTAssert(mock.controllers.count == 1)
        
        router.addDefaultRouter { (path, paramers) -> UIViewController? in
            return viewController(title: "default")
        }
        router.push(path: "/nothing")
        XCTAssert(mock.controllers.last!.title == "default")
        XCTAssert(mock.controllers.count == 2)
        
        router.addRouter(path: "/thrad/:name") { (path, paramers) -> UIViewController? in
            return viewController(title: paramers["name"] ?? "")
        }
        router.push(path: "/thrad/mike")
        XCTAssert(mock.controllers.last!.title == "mike")
        XCTAssert(mock.controllers.count == 3)
    }
    func testSubRouter() {
        let mock = MockRouter()
        let router = mock.create()
        let subRouter = router.addSubRouter(path: "/sub", comptent: { (_, _) in })
        
        router.addRouter(path: "/index") { (path, paramers) -> UIViewController? in
            return viewController(title: "parent")
        }
        subRouter.addRouter(path: "/index") { (path, paramers) -> UIViewController? in
            return viewController(title: "sub")
        }
        
        router.push(path: "/index")
        XCTAssert(mock.controllers.last!.title == "parent")
        XCTAssert(mock.controllers.count == 1)
        
        router.push(path: "/sub/index")
        XCTAssert(mock.controllers.last!.title == "sub")
        XCTAssert(mock.controllers.count == 2)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
