//
//  RouterTests.swift
//  RouterTests
//
//  Created by 王航 on 2017/9/29.
//  Copyright © 2017年 mike. All rights reserved.
//

import XCTest
import Interfaces
@testable import Router

class MockRouter:NSObject, Router {
    
    var controllers:[UIViewController] = []
    var router:PathRouter!
    
    func create()->PathRouter{
        self.router = PathRouter(parent: self)
        return self.router
    }
    func urlParse(url:String)->(String,[String:String]){
        let uri = URLComponents(string: url)
        let path = uri?.path ?? url
        var param = ["URL":url]
        if let comp = uri{
            let kvs = (comp.queryItems ?? []).map({ (item) -> (String,String) in
                return (item.name,item.value ?? "")
            })
            param.merge(kvs, uniquingKeysWith: { (first, _) -> String in first })
        }
        return (path, param)
    }
    func push(path:String){
        let (path, param) = urlParse(url: path)
        self.router.route(url: path, parameters: param) { (a, b) in
            if let c = b {
                controllers.append(c)
            }
        }
    }
    func replace(path:String){
        let (path, param) = urlParse(url: path)
        self.router.route(url: path, parameters: param) { (a, b) in
            if let c = b {
                _ = controllers.popLast()
                controllers.append(c)
            }
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
    func addMiddleware(middleware: @escaping Router.Middleware) {
        
    }
}
var ViewControllerParamersKey = "ViewControllerParamersKey"
extension UIViewController{
    var paramers:[String:String] {
        get {
            return (objc_getAssociatedObject(self, &ViewControllerParamersKey) as? [String:String]) ?? [:]
        }
        set {
            return objc_setAssociatedObject(self, &ViewControllerParamersKey, newValue, .OBJC_ASSOCIATION_COPY)
        }
    }
}
func viewController(title:String,paramers:[String:String]) -> UIViewController {
    let ctrl = UIViewController()
    ctrl.title = title
    ctrl.paramers = paramers
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
            return viewController(title: "first", paramers: paramers)
        }
        router.push(path: "/first")
        var controller = mock.controllers.last!
        XCTAssert(controller.title == "first")
        XCTAssert(controller.paramers["matched"] == "/first")
        XCTAssert(controller.paramers["fullMatched"] == "/first")
        XCTAssert(mock.controllers.count == 1)
        
        router.addRouter(path: "/second") { (path, paramers) -> UIViewController? in
            return viewController(title: "second", paramers: paramers)
        }
        router.push(path: "/second/")
        controller = mock.controllers.last!
        XCTAssert(controller.title == "second")
        XCTAssert(controller.paramers["matched"] == "/second/")
        XCTAssert(controller.paramers["fullMatched"] == "/second/")
        XCTAssert(mock.controllers.count == 2)
        
        router.pop()
        controller = mock.controllers.last!
        XCTAssert(controller.title == "first")
        XCTAssert(mock.controllers.count == 1)
        
        router.replace(path: "https://www.baidu.com/second?q=1")
        controller = mock.controllers.last!
        XCTAssert(controller.title == "second")
        XCTAssert(controller.paramers["matched"] == "/second")
        XCTAssert(controller.paramers["fullMatched"] == "/second")
        XCTAssert(controller.paramers["q"] == "1")
        XCTAssert(mock.controllers.count == 1)
        
        router.addDefaultRouter { (path, paramers) -> UIViewController? in
            return viewController(title: "default", paramers: paramers)
        }
        router.push(path: "/nothing")
        controller = mock.controllers.last!
        XCTAssert(controller.title == "default")
        XCTAssert(controller.paramers["matched"] == "/nothing")
        XCTAssert(controller.paramers["fullMatched"] == "/nothing")
        XCTAssert(mock.controllers.count == 2)
        
        router.replace(path: "/nothing/more")
        controller = mock.controllers.last!
        XCTAssert(controller.title == "default")
        XCTAssert(controller.paramers["matched"] == "/nothing/more")
        XCTAssert(controller.paramers["fullMatched"] == "/nothing/more")
        XCTAssert(mock.controllers.count == 2)
        
        router.addRouter(path: "/thrad/:name") { (path, paramers) -> UIViewController? in
            return viewController(title: paramers["name"] ?? "", paramers: paramers)
        }
        router.push(path: "/thrad/mike")
        controller = mock.controllers.last!
        XCTAssert(controller.title == "mike")
        XCTAssert(controller.paramers["matched"] == "/thrad/mike")
        XCTAssert(controller.paramers["fullMatched"] == "/thrad/mike")
        XCTAssert(controller.paramers["name"] == "mike")
        XCTAssert(mock.controllers.count == 3)
    }
    func testSubRouter() {
        let mock = MockRouter()
        let router = mock.create()
        let subRouter = router.addSubRouter(path: "/sub", comptent: { (_, _) in })
        
        router.addRouter(path: "/index") { (path, paramers) -> UIViewController? in
            return viewController(title: "parent", paramers: paramers)
        }
        subRouter.addRouter(path: "/index") { (path, paramers) -> UIViewController? in
            return viewController(title: "sub", paramers: paramers)
        }
        
        router.push(path: "/index")
        var controller = mock.controllers.last!
        XCTAssert(controller.title == "parent")
        XCTAssert(controller.paramers["matched"] == "/index")
        XCTAssert(controller.paramers["fullMatched"] == "/index")
        XCTAssert(mock.controllers.count == 1)
        
        router.push(path: "/sub/index")
        controller = mock.controllers.last!
        XCTAssert(controller.title == "sub")
        XCTAssert(controller.paramers["matched"] == "/index")
        XCTAssert(controller.paramers["fullMatched"] == "/sub/index")
        XCTAssert(mock.controllers.count == 2)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
