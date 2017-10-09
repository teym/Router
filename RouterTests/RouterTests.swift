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

class Inject:ModuleInject {
    struct ModuleError:Error {}
    public func instance<T>() throws -> T {
        throw ModuleError()
    }
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
        let router = MRouter(inject: Inject())
        
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
