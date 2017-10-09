//
//  RouterTests.swift
//  RouterTests
//
//  Created by 王航 on 2017/9/29.
//  Copyright © 2017年 mike. All rights reserved.
//

import XCTest
@testable import Router

extension NameToken: Equatable {
    public static func ==(lhs: NameToken, rhs: NameToken) -> Bool {
        switch lhs{
        case .Index(let i):
            switch rhs{
            case .Index(let ii):
                return i == ii
            case .Name(_):
                return false
            }
        case .Name(let s):
            switch rhs{
            case .Index(_):
                return false
            case .Name(let ss):
                return s == ss
            }
        }
    }
}
extension TokenInfo: Equatable {
    static func from(dict:[String:AnyObject]) -> TokenInfo {
        var name = NameToken.Name("")
        if let strName = dict["name"] as? String {
            name = .Name(strName)
        }else if let intName = dict["name"] as? Int {
            name = .Index(intName)
        }
        let prefix = (dict["prefix"] as? String) ?? ""
        let delimiter = (dict["delimiter"] as? String) ?? ""
        let optional = (dict["optional"] as? Bool) ?? false
        let i_repeat = (dict["repeat"] as? Bool) ?? false
        let partial = (dict["partial"] as? Bool) ?? false
        let pattern = (dict["pattern"] as? String) ?? ""
        return TokenInfo(name:name,
                         prefix:prefix,
                         delimiter:delimiter,
                         optional:optional,
                         i_repeat:i_repeat,
                         partial:partial,
                         pattern:pattern)
    }
    public static func ==(lhs: TokenInfo, rhs: TokenInfo) -> Bool {
        return lhs.name == rhs.name &&
            lhs.prefix == rhs.prefix &&
            lhs.delimiter == rhs.delimiter &&
            lhs.optional == rhs.optional &&
            lhs.i_repeat == rhs.i_repeat &&
            lhs.partial == rhs.partial &&
            lhs.pattern == rhs.pattern
    }
}
extension ParseToken: Equatable {
    static func from(dict:AnyObject) -> ParseToken {
        if let path = dict as? String {
            return .Path(path)
        }
        let token = TokenInfo.from(dict:dict as! [String:AnyObject])
        return .Token(token)
    }
    public static func ==(lhs: ParseToken, rhs: ParseToken) -> Bool {
        switch lhs {
        case .Path(let p):
            switch rhs {
            case .Path(let pp):
                return p == pp
            case .Token(_):
                return false
            }
        case .Token(let t):
            switch rhs {
            case .Path(_):
                return false
            case .Token(let tt):
                return t == tt
            }
        }
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
    
    func testPath() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let TEST_PATH = "/user/:id"
        
        let TEST_PARAM:[String:AnyObject] = [
            "name": "id" as AnyObject,
            "prefix": "/" as AnyObject,
            "delimiter": "/" as AnyObject,
            "optional": false as AnyObject,
            "repeat": false as AnyObject,
            "partial": false as AnyObject,
            "pattern": "[^\\/]+?" as AnyObject
        ]
        let TEST_TOKEN = TokenInfo.from(dict: TEST_PARAM)
        
        let (re,keys) = stringToRegexp(path: TEST_PATH, options: ["end": false as AnyObject])
        XCTAssertEqual(keys, [TEST_TOKEN],"keys not equal")
        let ret = re.match("/user/123/show")!.values
        XCTAssertEqual(ret, ["/user/123", "123"],"regexp result not equal")
    }
    
    func testCase(){
        let testCase:[AnyObject?] = [
            ":test?" as AnyObject,
            nil,
            [
                [
                    "name": "test",
                    "prefix": "",
                    "delimiter": "/",
                    "optional": true,
                    "repeat": false,
                    "partial": false,
                    "pattern": "[^\\/]+?"
                ]
                ] as AnyObject,
            [
                ["route", ["route", "route"]],
                ["/route", nil],
//                ["", ["", nil]],
                ["route/foobar", nil]
                ] as AnyObject,
            [
                [EmptyDict, ""],
                [[ "test": "" ], nil],
                [[ "test": "route" ], "route"]
                ] as AnyObject
        ]
        let path = testCase[0] as! String
        let options = (testCase[1] as? [String:AnyObject]) ?? [:]
        let parseTokens = (testCase[2] as? [AnyObject]) ?? []
        let targetTokens = parseTokens.map({ParseToken.from(dict:$0)})
        
        let tokens = parse(str: path, options: options)
        XCTAssertEqual(tokens,targetTokens,"fail with case: \(testCase) tokens")
        let (re,_) = tokensToRegExp(tokens: tokens, options: options)
        let re_case = (testCase[3] as? [[AnyObject]]) ?? []
        for _case in re_case {
            let re_test = (_case[0] as? String) ?? ""
            let re_res = re.match(re_test)
            if let re_ret = (_case[1] as? [String?]) {
                let target = re_ret.map({ $0==nil ? "" : $0! })
                XCTAssertEqual(re_res!.values,target,"fail with case: \(testCase) re: \(_case)")
            }else {
                XCTAssertNil(re_res,"fail with case: \(testCase) re: \(_case)")
            }
        }
    }
    
    func testList() {
        for testCase in TESTS {
            if let path = testCase[0] as? String{
                let options = (testCase[1] as? [String:AnyObject]) ?? [:]
                let parseTokens = (testCase[2] as? [AnyObject]) ?? []
                let targetTokens = parseTokens.map({ParseToken.from(dict:$0)})
                let tokens = parse(str: path, options: options)
                XCTAssertEqual(tokens,targetTokens,"fail with case: \(testCase) tokens")
                let (re,_) = tokensToRegExp(tokens: tokens, options: options)
                let re_case = (testCase[3] as? [[AnyObject]]) ?? []
                for _case in re_case {
                    let re_test = (_case[0] as? String) ?? ""
                    let re_res = re.match(re_test)
                    if let re_ret = (_case[1] as? [String?]) {
                        let target = re_ret.map({ $0==nil ? "" : $0! })
                        XCTAssertEqual(re_res!.values,target,"fail with case: \(testCase) re: \(_case)")
                    }else {
                        XCTAssertNil(re_res,"fail with case: \(testCase) re: \(_case)")
                    }
                }
            }
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}

/**
 * An array of test cases with expected inputs and outputs.
 *
 * @type {Array}
 */
let EmptyDict = [String:AnyObject]()
let TESTS: [[AnyObject?]] = [
    /**
     * Simple paths.
     */
    [
        "/" as AnyObject,
        nil,
        [
            "/"
            ] as AnyObject,
        [
            ["/", ["/"]],
            ["/route", nil]
            ] as AnyObject,
        [
            [nil, "/"],
            [EmptyDict, "/"],
            [[ "id": 123 ], "/"]
            ] as AnyObject
    ],
    [
        "/test" as AnyObject,
        nil,
        [
            "/test"
            ] as AnyObject,
        [
            ["/test", ["/test"]],
            ["/route", nil],
            ["/test/route", nil],
            ["/test/", ["/test/"]]
            ] as AnyObject,
        [
            [nil, "/test"],
            [EmptyDict, "/test"]
            ] as AnyObject
    ],
    [
        "/test/" as AnyObject,
        nil,
        [
            "/test/"
            ] as AnyObject,
        [
            ["/test", nil],
            ["/test/", ["/test/"]],
            ["/test//", ["/test//"]]
            ] as AnyObject,
        [
            [nil, "/test/"]
            ] as AnyObject
    ],
    
    /**
     * Case-sensitive paths.
     */
    [
        "/test" as AnyObject,
        [
            "sensitive": true
            ] as AnyObject,
        [
            "/test"
            ] as AnyObject,
        [
            ["/test", ["/test"]],
            ["/TEST", nil]
            ] as AnyObject,
        [
            [nil, "/test"]
            ] as AnyObject
    ],
    [
        "/TEST" as AnyObject,
        [
            "sensitive": true
            ] as AnyObject,
        [
            "/TEST"
            ] as AnyObject,
        [
            ["/test", nil],
            ["/TEST", ["/TEST"]]
            ] as AnyObject,
        [
            [nil, "/TEST"]
            ] as AnyObject
    ],
    
    /**
     * Strict mode.
     */
    [
        "/test" as AnyObject,
        [
            "strict": true
            ] as AnyObject,
        [
            "/test"
            ] as AnyObject,
        [
            ["/test", ["/test"]],
            ["/test/", nil],
            ["/TEST", ["/TEST"]]
            ] as AnyObject,
        [
            [nil, "/test"]
            ] as AnyObject
    ],
    [
        "/test/" as AnyObject,
        [
            "strict": true
            ] as AnyObject,
        [
            "/test/"
            ] as AnyObject,
        [
            ["/test", nil],
            ["/test/", ["/test/"]],
            ["/test//", nil]
            ] as AnyObject,
        [
            [nil, "/test/"]
            ] as AnyObject
    ],
    
    /**
     * Non-ending mode.
     */
    [
        "/test" as AnyObject,
        [
            "end": false
            ] as AnyObject,
        [
            "/test"
            ] as AnyObject,
        [
            ["/test", ["/test"]],
            ["/test/", ["/test/"]],
            ["/test/route", ["/test"]],
            ["/route", nil]
            ] as AnyObject,
        [
            [nil, "/test"]
            ] as AnyObject
    ],
    [
        "/test/" as AnyObject,
        [
            "end": false
            ] as AnyObject,
        [
            "/test/"
            ] as AnyObject,
        [
            ["/test/route", nil],
            ["/test//", ["/test//"]],
            ["/test//route", ["/test/"]]
            ] as AnyObject,
        [
            [nil, "/test/"]
            ] as AnyObject
    ],
    [
        "/:test" as AnyObject,
        [
            "end": false
            ] as AnyObject,
        [
            [
                "name": "test",
                "prefix": "/",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "[^\\/]+?"
            ]
            ] as AnyObject,
        [
            ["/route", ["/route", "route"]]
            ] as AnyObject,
        [
            [EmptyDict, nil],
            [[ "test": "abc" ], "/abc"],
            [[ "test": "a+b" ], "/a+b"], //[ "encode": (value) => value ]],
            [[ "test": "a+b" ], "/a%2Bb"]
            ] as AnyObject
    ],
    [
        "/:test/" as AnyObject,
        [
            "end": false
            ] as AnyObject,
        [
            [
                "name": "test",
                "prefix": "/",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "[^\\/]+?"
                ] as AnyObject,
            "/"
            ] as AnyObject,
        [
            ["/route", nil],
            ["/route/", ["/route/", "route"]]
            ] as AnyObject,
        [
            [[ "test": "abc" ], "/abc/"]
            ] as AnyObject
    ],
    
    /**
     * Combine modes.
     */
    [
        "/test" as AnyObject,
        [
            "end": false,
            "strict": true
            ] as AnyObject,
        [
            "/test"
            ] as AnyObject,
        [
            ["/test", ["/test"]],
            ["/test/", ["/test"]],
            ["/test/route", ["/test"]]
            ] as AnyObject,
        [
            [nil, "/test"]
            ] as AnyObject
    ],
    [
        "/test/" as AnyObject,
        [
            "end": false,
            "strict": true
            ] as AnyObject,
        [
            "/test/"
            ] as AnyObject,
        [
            ["/test", nil],
            ["/test/", ["/test/"]],
            ["/test//", ["/test/"]],
            ["/test/route", nil]
            ] as AnyObject,
        [
            [nil, "/test/"]
            ] as AnyObject
    ],
    [
        "/test.json" as AnyObject,
        [
            "end": false,
            "strict": true
            ] as AnyObject,
        [
            "/test.json"
            ] as AnyObject,
        [
            ["/test.json", ["/test.json"]],
            ["/test.json.hbs", nil],
            ["/test.json/route", ["/test.json"]]
            ] as AnyObject,
        [
            [nil, "/test.json"]
            ] as AnyObject
    ],
    [
        "/:test" as AnyObject,
        [
            "end": false,
            "strict": true
            ] as AnyObject,
        [
            [
                "name": "test",
                "prefix": "/",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "[^\\/]+?"
            ]
            ] as AnyObject,
        [
            ["/route", ["/route", "route"]],
            ["/route/", ["/route", "route"]]
            ] as AnyObject,
        [
            [EmptyDict, nil],
            [[ "test": "abc" ], "/abc"]
            ] as AnyObject
    ],
    [
        "/:test/" as AnyObject,
        [
            "end": false,
            "strict": true
            ] as AnyObject,
        [
            [
                "name": "test",
                "prefix": "/",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "[^\\/]+?"
                ] as AnyObject,
            "/"
            ] as AnyObject,
        [
            ["/route", nil],
            ["/route/", ["/route/", "route"]]
            ] as AnyObject,
        [
            [[ "test": "foobar" ], "/foobar/"]
            ] as AnyObject
    ],
    
    /**
     * Arrays of simple paths.
     */
    [
        ["/one", "/two"] as AnyObject,
        nil,
        [] as AnyObject,
        [
            ["/one", ["/one"]],
            ["/two", ["/two"]],
            ["/three", nil],
            ["/one/two", nil]
            ] as AnyObject,
        [] as AnyObject
    ],
    
    /**
     * Non-ending simple path.
     */
    [
        "/test" as AnyObject,
        [
            "end": false
            ] as AnyObject,
        [
            "/test"
            ] as AnyObject,
        [
            ["/test/route", ["/test"]]
            ] as AnyObject,
        [
            [nil, "/test"]
            ] as AnyObject
    ],
    
    /**
     * Single named parameter.
     */
    [
        "/:test" as AnyObject,
        nil,
        [
            [
                "name": "test",
                "prefix": "/",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "[^\\/]+?"
            ]
            ] as AnyObject,
        [
            ["/route", ["/route", "route"]],
            ["/another", ["/another", "another"]],
            ["/something/else", nil],
            ["/route.json", ["/route.json", "route.json"]],
            ["/something%2Felse", ["/something%2Felse", "something%2Felse"]],
            ["/something%2Felse%2Fmore", ["/something%2Felse%2Fmore", "something%2Felse%2Fmore"]],
            ["/;,:@&=+$-_.!~*()", ["/;,:@&=+$-_.!~*()", ";,:@&=+$-_.!~*()"]]
            ] as AnyObject,
        [
            [[ "test": "route" ], "/route"],
            [[ "test": "something/else" ], "/something%2Felse"],
            [[ "test": "something/else/more" ], "/something%2Felse%2Fmore"]
            ] as AnyObject
    ],
    [
        "/:test" as AnyObject,
        [
            "strict": true
            ] as AnyObject,
        [
            [
                "name": "test",
                "prefix": "/",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "[^\\/]+?"
            ]
            ] as AnyObject,
        [
            ["/route", ["/route", "route"]],
            ["/route/", nil]
            ] as AnyObject,
        [
            [[ "test": "route" ], "/route"]
            ] as AnyObject
    ],
    [
        "/:test/" as AnyObject,
        [
            "strict": true
            ] as AnyObject,
        [
            [
                "name": "test",
                "prefix": "/",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "[^\\/]+?"
                ] as AnyObject,
            "/"
            ] as AnyObject,
        [
            ["/route/", ["/route/", "route"]],
            ["/route//", nil]
            ] as AnyObject,
        [
            [[ "test": "route" ], "/route/"]
            ] as AnyObject
    ],
    [
        "/:test" as AnyObject,
        [
            "end": false
            ] as AnyObject,
        [
            [
                "name": "test",
                "prefix": "/",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "[^\\/]+?"
            ]
            ] as AnyObject,
        [
            ["/route.json", ["/route.json", "route.json"]],
            ["/route//", ["/route", "route"]]
            ] as AnyObject,
        [
            [[ "test": "route" ], "/route"]
            ] as AnyObject
    ],
    
    /**
     * Optional named parameter.
     */
    [
        "/:test?" as AnyObject,
        nil,
        [
            [
                "name": "test",
                "prefix": "/",
                "delimiter": "/",
                "optional": true,
                "repeat": false,
                "partial": false,
                "pattern": "[^\\/]+?"
            ]
            ] as AnyObject,
        [
            ["/route", ["/route", "route"]],
            ["/route/nested", nil],
            ["/", ["/", nil]],
            ["//", nil]
            ] as AnyObject,
        [
            [nil, ""],
            [[ "test": "foobar" ], "/foobar"]
            ] as AnyObject
    ],
    [
        "/:test?" as AnyObject,
        [
            "strict": true
            ] as AnyObject,
        [
            [
                "name": "test",
                "prefix": "/",
                "delimiter": "/",
                "optional": true,
                "repeat": false,
                "partial": false,
                "pattern": "[^\\/]+?"
            ]
            ] as AnyObject,
        [
            ["/route", ["/route", "route"]],
            ["/", nil], // Questionable behaviour.
            ["//", nil]
            ] as AnyObject,
        [
            [nil, ""],
            [[ "test": "foobar" ], "/foobar"]
            ] as AnyObject
    ],
    [
        "/:test?/" as AnyObject,
        [
            "strict": true
            ] as AnyObject,
        [
            [
                "name": "test",
                "prefix": "/",
                "delimiter": "/",
                "optional": true,
                "repeat": false,
                "partial": false,
                "pattern": "[^\\/]+?"
                ] as AnyObject,
            "/"
            ] as AnyObject,
        [
            ["/route", nil],
            ["/route/", ["/route/", "route"]],
            ["/", ["/", nil]],
            ["//", nil]
            ] as AnyObject,
        [
            [nil, "/"],
            [[ "test": "foobar" ], "/foobar/"]
            ] as AnyObject
    ],
    [
        "/:test?/bar" as AnyObject,
        nil,
        [
            [
                "name": "test",
                "prefix": "/",
                "delimiter": "/",
                "optional": true,
                "repeat": false,
                "partial": false,
                "pattern": "[^\\/]+?"
                ] as AnyObject,
            "/bar"
            ] as AnyObject,
        [
            ["/foo/bar", ["/foo/bar", "foo"]]
            ] as AnyObject,
        [
            [[ "test": "foo" ], "/foo/bar"]
            ] as AnyObject
    ],
    [
        "/:test?-bar" as AnyObject,
        nil,
        [
            [
                "name": "test",
                "prefix": "/",
                "delimiter": "/",
                "optional": true,
                "repeat": false,
                "partial": true,
                "pattern": "[^\\/]+?"
                ] as AnyObject,
            "-bar"
            ] as AnyObject,
        [
            ["/-bar", ["/-bar", nil]],
            ["/foo-bar", ["/foo-bar", "foo"]]
            ] as AnyObject,
        [
            [nil, "/-bar"],
            [[ "test": "foo" ], "/foo-bar"]
            ] as AnyObject
    ],
    [
        "/:test*-bar" as AnyObject,
        nil,
        [
            [
                "name": "test",
                "prefix": "/",
                "delimiter": "/",
                "optional": true,
                "repeat": true,
                "partial": true,
                "pattern": "[^\\/]+?"
                ] as AnyObject,
            "-bar"
            ] as AnyObject,
        [
            ["/-bar", ["/-bar", nil]],
            ["/foo-bar", ["/foo-bar", "foo"]],
            ["/foo/baz-bar", ["/foo/baz-bar", "foo/baz"]],
            ] as AnyObject,
        [
            [[ "test": "foo" ], "/foo-bar"]
            ] as AnyObject
    ],
    
    /**
     * Repeated one or more times parameters.
     */
    [
        "/:test+" as AnyObject,
        nil,
        [
            [
                "name": "test",
                "prefix": "/",
                "delimiter": "/",
                "optional": false,
                "repeat": true,
                "partial": false,
                "pattern": "[^\\/]+?"
            ]
            ] as AnyObject,
        [
            ["/", nil],
            ["/route", ["/route", "route"]],
            ["/some/basic/route", ["/some/basic/route", "some/basic/route"]],
            ["//", nil]
            ] as AnyObject,
        [
            [EmptyDict, nil],
            [[ "test": "foobar" ], "/foobar"],
            [[ "test": ["a", "b", "c"] ], "/a/b/c"]
            ] as AnyObject
    ],
    [
        "/:test(\\d+)+" as AnyObject,
        nil,
        [
            [
                "name": "test",
                "prefix": "/",
                "delimiter": "/",
                "optional": false,
                "repeat": true,
                "partial": false,
                "pattern": "\\d+"
            ]
            ] as AnyObject,
        [
            ["/abc/456/789", nil],
            ["/123/456/789", ["/123/456/789", "123/456/789"]]
            ] as AnyObject,
        [
            [[ "test": "abc" ], nil],
            [[ "test": 123 ], "/123"],
            [[ "test": [1, 2, 3] ], "/1/2/3"]
            ] as AnyObject
    ],
    [
        "/route.:ext(json|xml)+" as AnyObject,
        nil,
        [
            "/route",
            [
                "name": "ext",
                "prefix": ".",
                "delimiter": ".",
                "optional": false,
                "repeat": true,
                "partial": false,
                "pattern": "json|xml"
            ]
            ] as AnyObject,
        [
            ["/route", nil],
            ["/route.json", ["/route.json", "json"]],
            ["/route.xml.json", ["/route.xml.json", "xml.json"]],
            ["/route.html", nil]
            ] as AnyObject,
        [
            [[ "ext": "foobar" ], nil],
            [[ "ext": "xml" ], "/route.xml"],
            [[ "ext": ["xml", "json"] ], "/route.xml.json"]
            ] as AnyObject
    ],
    
    /**
     * Repeated zero or more times parameters.
     */
    [
        "/:test*" as AnyObject,
        nil,
        [
            [
                "name": "test",
                "prefix": "/",
                "delimiter": "/",
                "optional": true,
                "repeat": true,
                "partial": false,
                "pattern": "[^\\/]+?"
            ]
            ] as AnyObject,
        [
            ["/", ["/", nil]],
            ["//", nil],
            ["/route", ["/route", "route"]],
            ["/some/basic/route", ["/some/basic/route", "some/basic/route"]]
            ] as AnyObject,
        [
            [EmptyDict, ""],
            [[ "test": "foobar" ], "/foobar"],
            [[ "test": ["foo", "bar"] ], "/foo/bar"]
            ] as AnyObject
    ],
    [
        "/route.:ext([a-z]+)*" as AnyObject,
        nil,
        [
            "/route",
            [
                "name": "ext",
                "prefix": ".",
                "delimiter": ".",
                "optional": true,
                "repeat": true,
                "partial": false,
                "pattern": "[a-z]+"
            ]
            ] as AnyObject,
        [
            ["/route", ["/route", nil]],
            ["/route.json", ["/route.json", "json"]],
            ["/route.json.xml", ["/route.json.xml", "json.xml"]],
            ["/route.123", nil]
            ] as AnyObject,
        [
            [EmptyDict, "/route"],
            [[ "ext": [] ], "/route"],
            [[ "ext": "123" ], nil],
            [[ "ext": "foobar" ], "/route.foobar"],
            [[ "ext": ["foo", "bar"] ], "/route.foo.bar"]
            ] as AnyObject
    ],
    
    /**
     * Custom named parameters.
     */
    [
        "/:test(\\d+)" as AnyObject,
        nil,
        [
            [
                "name": "test",
                "prefix": "/",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "\\d+"
            ]
            ] as AnyObject,
        [
            ["/123", ["/123", "123"]],
            ["/abc", nil],
            ["/123/abc", nil]
            ] as AnyObject,
        [
            [[ "test": "abc" ], nil],
            [[ "test": "123" ], "/123"]
            ] as AnyObject
    ],
    [
        "/:test(\\d+)" as AnyObject,
        [
            "end": false
            ] as AnyObject,
        [
            [
                "name": "test",
                "prefix": "/",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "\\d+"
            ]
            ] as AnyObject,
        [
            ["/123", ["/123", "123"]],
            ["/abc", nil],
            ["/123/abc", ["/123", "123"]]
            ] as AnyObject,
        [
            [[ "test": "123" ], "/123"]
            ] as AnyObject
    ],
    [
        "/:test(.*)" as AnyObject,
        nil,
        [
            [
                "name": "test",
                "prefix": "/",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": ".*"
            ]
            ] as AnyObject,
        [
            ["/anything/goes/here", ["/anything/goes/here", "anything/goes/here"]],
            ["/;,:@&=/+$-_.!/~*()", ["/;,:@&=/+$-_.!/~*()", ";,:@&=/+$-_.!/~*()"]]
            ] as AnyObject,
        [
            [[ "test": "" ], "/"],
            [[ "test": "abc" ], "/abc"],
            [[ "test": "abc/123" ], "/abc%2F123"],
            [[ "test": "abc/123/456" ], "/abc%2F123%2F456"]
            ] as AnyObject
    ],
    [
        "/:route([a-z]+)" as AnyObject,
        nil,
        [
            [
                "name": "route",
                "prefix": "/",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "[a-z]+"
            ]
            ] as AnyObject,
        [
            ["/abcde", ["/abcde", "abcde"]],
            ["/12345", nil]
            ] as AnyObject,
        [
            [[ "route": "" ], nil],
            [[ "route": "123" ], nil],
            [[ "route": "abc" ], "/abc"]
            ] as AnyObject
    ],
    [
        "/:route(this|that)" as AnyObject,
        nil,
        [
            [
                "name": "route",
                "prefix": "/",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "this|that"
            ]
            ] as AnyObject,
        [
            ["/this", ["/this", "this"]],
            ["/that", ["/that", "that"]],
            ["/foo", nil]
            ] as AnyObject,
        [
            [[ "route": "this" ], "/this"],
            [[ "route": "foo" ], nil],
            [[ "route": "that" ], "/that"]
            ] as AnyObject
    ],
    [
        "/:path(abc|xyz)*" as AnyObject,
        nil,
        [
            [
                "name": "path",
                "prefix": "/",
                "delimiter": "/",
                "optional": true,
                "repeat": true,
                "partial": false,
                "pattern": "abc|xyz"
            ]
            ] as AnyObject,
        [
            ["/abc", ["/abc", "abc"]],
            ["/abc/abc", ["/abc/abc", "abc/abc"]],
            ["/xyz/xyz", ["/xyz/xyz", "xyz/xyz"]],
            ["/abc/xyz", ["/abc/xyz", "abc/xyz"]],
            ["/abc/xyz/abc/xyz", ["/abc/xyz/abc/xyz", "abc/xyz/abc/xyz"]],
            ["/xyzxyz", nil]
            ] as AnyObject,
        [
            [[ "path": "abc" ], "/abc"],
            [[ "path": ["abc", "xyz"] ], "/abc/xyz"],
            [[ "path": ["xyz", "abc", "xyz"] ], "/xyz/abc/xyz"],
            [[ "path": "abc123" ], nil],
            [[ "path": "abcxyz" ], nil]
            ] as AnyObject
    ],
    
    /**
     * Prefixed slashes could be omitted.
     */
    [
        "test" as AnyObject,
        nil,
        [
            "test"
            ] as AnyObject,
        [
            ["test", ["test"]],
            ["/test", nil]
            ] as AnyObject,
        [
            [nil, "test"]
            ] as AnyObject
    ],
    [
        ":test" as AnyObject,
        nil,
        [
            [
                "name": "test",
                "prefix": "",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "[^\\/]+?"
            ]
            ] as AnyObject,
        [
            ["route", ["route", "route"]],
            ["/route", nil],
            ["route/", ["route/", "route"]]
            ] as AnyObject,
        [
            [[ "test": "" ], nil],
            [EmptyDict, nil],
            [[ "test": nil ], nil],
            [[ "test": "route" ], "route"]
            ] as AnyObject
    ],
    [
        ":test" as AnyObject,
        [
            "strict": true
            ] as AnyObject,
        [
            [
                "name": "test",
                "prefix": "",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "[^\\/]+?"
            ]
            ] as AnyObject,
        [
            ["route", ["route", "route"]],
            ["/route", nil],
            ["route/", nil]
            ] as AnyObject,
        [
            [[ "test": "route" ], "route"]
            ] as AnyObject
    ],
    [
        ":test" as AnyObject,
        [
            "end": false
            ] as AnyObject,
        [
            [
                "name": "test",
                "prefix": "",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "[^\\/]+?"
            ]
            ] as AnyObject,
        [
            ["route", ["route", "route"]],
            ["/route", nil],
            ["route/", ["route/", "route"]],
            ["route/foobar", ["route", "route"]]
            ] as AnyObject,
        [
            [[ "test": "route" ], "route"]
            ] as AnyObject
    ],
    [
        ":test?" as AnyObject,
        nil,
        [
            [
                "name": "test",
                "prefix": "",
                "delimiter": "/",
                "optional": true,
                "repeat": false,
                "partial": false,
                "pattern": "[^\\/]+?"
            ]
            ] as AnyObject,
        [
            ["route", ["route", "route"]],
            ["/route", nil],
//            ["", ["", nil]],
            ["route/foobar", nil]
            ] as AnyObject,
        [
            [EmptyDict, ""],
            [[ "test": "" ], nil],
            [[ "test": "route" ], "route"]
            ] as AnyObject
    ],
    
    /**
     * Formats.
     */
    [
        "/test.json" as AnyObject,
        nil,
        [
            "/test.json"
            ] as AnyObject,
        [
            ["/test.json", ["/test.json"]],
            ["/route.json", nil]
            ] as AnyObject,
        [
            [EmptyDict, "/test.json"]
            ] as AnyObject
    ],
    [
        "/:test.json" as AnyObject,
        nil,
        [
            [
                "name": "test",
                "prefix": "/",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": true,
                "pattern": "[^\\/]+?"
                ] as AnyObject,
            ".json"
            ] as AnyObject,
        [
            ["/.json", nil],
            ["/test.json", ["/test.json", "test"]],
            ["/route.json", ["/route.json", "route"]],
            ["/route.json.json", ["/route.json.json", "route.json"]]
            ] as AnyObject,
        [
            [[ "test": "" ], nil],
            [[ "test": "foo" ], "/foo.json"]
            ] as AnyObject
    ],
    
    /**
     * Format params.
     */
    [
        "/test.:format" as AnyObject,
        nil,
        [
            "/test",
            [
                "name": "format",
                "prefix": ".",
                "delimiter": ".",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "[^\\.]+?"
            ]
            ] as AnyObject,
        [
            ["/test.html", ["/test.html", "html"]],
            ["/test.hbs.html", nil]
            ] as AnyObject,
        [
            [EmptyDict, nil],
            [[ "format": "" ], nil],
            [[ "format": "foo" ], "/test.foo"]
            ] as AnyObject
    ],
    [
        "/test.:format.:format" as AnyObject,
        nil,
        [
            "/test",
            [
                "name": "format",
                "prefix": ".",
                "delimiter": ".",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "[^\\.]+?"
                ] as AnyObject,
            [
                "name": "format",
                "prefix": ".",
                "delimiter": ".",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "[^\\.]+?"
            ]
            ] as AnyObject,
        [
            ["/test.html", nil],
            ["/test.hbs.html", ["/test.hbs.html", "hbs", "html"]]
            ] as AnyObject,
        [
            [[ "format": "foo.bar" ], nil],
            [[ "format": "foo" ], "/test.foo.foo"]
            ] as AnyObject
    ],
    [
        "/test.:format+" as AnyObject,
        nil,
        [
            "/test",
            [
                "name": "format",
                "prefix": ".",
                "delimiter": ".",
                "optional": false,
                "repeat": true,
                "partial": false,
                "pattern": "[^\\.]+?"
            ]
            ] as AnyObject,
        [
            ["/test.html", ["/test.html", "html"]],
            ["/test.hbs.html", ["/test.hbs.html", "hbs.html"]]
            ] as AnyObject,
        [
            [[ "format": [] ], nil],
            [[ "format": "foo" ], "/test.foo"],
            [[ "format": ["foo", "bar"] ], "/test.foo.bar"]
            ] as AnyObject
    ],
    [
        "/test.:format" as AnyObject,
        [
            "end": false
            ] as AnyObject,
        [
            "/test",
            [
                "name": "format",
                "prefix": ".",
                "delimiter": ".",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "[^\\.]+?"
            ]
            ] as AnyObject,
        [
            ["/test.html", ["/test.html", "html"]],
            ["/test.hbs.html", nil]
            ] as AnyObject,
        [
            [[ "format": "foo" ], "/test.foo"]
            ] as AnyObject
    ],
    [
        "/test.:format." as AnyObject,
        nil,
        [
            "/test",
            [
                "name": "format",
                "prefix": ".",
                "delimiter": ".",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "[^\\.]+?"
                ] as AnyObject,
            "."
            ] as AnyObject,
        [
            ["/test.html.", ["/test.html.", "html"]],
            ["/test.hbs.html", nil]
            ] as AnyObject,
        [
            [[ "format": "" ], nil],
            [[ "format": "foo" ], "/test.foo."]
            ] as AnyObject
    ],
    
    /**
     * Format and path params.
     */
    [
        "/:test.:format" as AnyObject,
        nil,
        [
            [
                "name": "test",
                "prefix": "/",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": true,
                "pattern": "[^\\/]+?"
                ] as AnyObject,
            [
                "name": "format",
                "prefix": ".",
                "delimiter": ".",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "[^\\.]+?"
            ]
            ] as AnyObject,
        [
            ["/route.html", ["/route.html", "route", "html"]],
            ["/route", nil],
            ["/route.html.json", ["/route.html.json", "route.html", "json"]]
            ] as AnyObject,
        [
            [EmptyDict, nil],
            [[ "test": "route", "format": "foo" ], "/route.foo"]
            ] as AnyObject
    ],
    [
        "/:test.:format?" as AnyObject,
        nil,
        [
            [
                "name": "test",
                "prefix": "/",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": true,
                "pattern": "[^\\/]+?"
                ] as AnyObject,
            [
                "name": "format",
                "prefix": ".",
                "delimiter": ".",
                "optional": true,
                "repeat": false,
                "partial": false,
                "pattern": "[^\\.]+?"
            ]
            ] as AnyObject,
        [
            ["/route", ["/route", "route", nil]],
            ["/route.json", ["/route.json", "route", "json"]],
            ["/route.json.html", ["/route.json.html", "route.json", "html"]]
            ] as AnyObject,
        [
            [[ "test": "route" ], "/route"],
            [[ "test": "route", "format": "" ], nil],
            [[ "test": "route", "format": "foo" ], "/route.foo"]
            ] as AnyObject
    ],
    [
        "/:test.:format?" as AnyObject,
        [
            "end": false
            ] as AnyObject,
        [
            [
                "name": "test",
                "prefix": "/",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": true,
                "pattern": "[^\\/]+?"
                ] as AnyObject,
            [
                "name": "format",
                "prefix": ".",
                "delimiter": ".",
                "optional": true,
                "repeat": false,
                "partial": false,
                "pattern": "[^\\.]+?"
            ]
            ] as AnyObject,
        [
            ["/route", ["/route", "route", nil]],
            ["/route.json", ["/route.json", "route", "json"]],
            ["/route.json.html", ["/route.json.html", "route.json", "html"]]
            ] as AnyObject,
        [
            [[ "test": "route" ], "/route"],
            [[ "test": "route", "format": nil ], "/route"],
            [[ "test": "route", "format": "" ], nil],
            [[ "test": "route", "format": "foo" ], "/route.foo"]
            ] as AnyObject
    ],
    [
        "/test.:format(.*)z" as AnyObject,
        [
            "end": false
            ] as AnyObject,
        [
            "/test",
            [
                "name": "format",
                "prefix": ".",
                "delimiter": ".",
                "optional": false,
                "repeat": false,
                "partial": true,
                "pattern": ".*"
                ] as AnyObject,
            "z"
            ] as AnyObject,
        [
            ["/test.abc", nil],
            ["/test.z", ["/test.z", ""]],
            ["/test.abcz", ["/test.abcz", "abc"]]
            ] as AnyObject,
        [
            [EmptyDict, nil],
            [[ "format": "" ], "/test.z"],
            [[ "format": "foo" ], "/test.fooz"]
            ] as AnyObject
    ],
    
    /**
     * Unnamed params.
     */
    [
        "/(\\d+)" as AnyObject,
        nil,
        [
            [
                "name": 0,
                "prefix": "/",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "\\d+"
            ]
            ] as AnyObject,
        [
            ["/123", ["/123", "123"]],
            ["/abc", nil],
            ["/123/abc", nil]
            ] as AnyObject,
        [
            [EmptyDict, nil],
            [[ "0": "123" ], "/123"]
            ] as AnyObject
    ],
    [
        "/(\\d+)" as AnyObject,
        [
            "end": false
            ] as AnyObject,
        [
            [
                "name": 0,
                "prefix": "/",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "\\d+"
            ]
            ] as AnyObject,
        [
            ["/123", ["/123", "123"]],
            ["/abc", nil],
            ["/123/abc", ["/123", "123"]],
            ["/123/", ["/123/", "123"]]
            ] as AnyObject,
        [
            [[ "0": "123" ], "/123"]
            ] as AnyObject
    ],
    [
        "/(\\d+)?" as AnyObject,
        nil,
        [
            [
                "name": 0,
                "prefix": "/",
                "delimiter": "/",
                "optional": true,
                "repeat": false,
                "partial": false,
                "pattern": "\\d+"
            ]
            ] as AnyObject,
        [
            ["/", ["/", nil]],
            ["/123", ["/123", "123"]]
            ] as AnyObject,
        [
            [EmptyDict, ""],
            [[ "0": "123" ], "/123"]
            ] as AnyObject
    ],
    [
        "/(.*)" as AnyObject,
        nil,
        [
            [
                "name": 0,
                "prefix": "/",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": ".*"
            ]
            ] as AnyObject,
        [
            ["/", ["/", ""]],
            ["/route", ["/route", "route"]],
            ["/route/nested", ["/route/nested", "route/nested"]]
            ] as AnyObject,
        [
            [[ "0": "" ], "/"],
            [[ "0": "123" ], "/123"]
            ] as AnyObject
    ],
    [
        "/route\\(\\\\(\\d+\\\\)\\)" as AnyObject,
        nil,
        [
            "/route(\\",
            [
                "name": 0,
                "prefix": "",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "\\d+\\\\"
                ] as AnyObject,
            ")"
            ] as AnyObject,
        [
            ["/route(\\123\\)", ["/route(\\123\\)", "123\\"]]
            ] as AnyObject,
        [] as AnyObject
    ],
    
    /**
     * Regexps.
     */
    /*
    [
        ".*" as AnyObject,
        nil,
        [] as AnyObject,
        [
            ["/match/anything", ["/match/anything"]]
            ] as AnyObject,
        [] as AnyObject
    ],
    [
        "(.*)" as AnyObject,
        nil,
        [
            [
                "name": 0,
                "prefix": nil,
                "delimiter": nil,
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": nil
            ]
            ] as AnyObject,
        [
            ["/match/anything", ["/match/anything", "/match/anything"]]
            ] as AnyObject,
        [] as AnyObject
    ],
    [
        "/(\\d+)" as AnyObject,
        nil,
        [
            [
                "name": 0,
                "prefix": nil,
                "delimiter": nil,
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": nil
            ]
            ] as AnyObject,
        [
            ["/abc", nil],
            ["/123", ["/123", "123"]]
            ] as AnyObject,
        [] as AnyObject
    ],
    */
    
    /**
     * Mixed arrays.
     */
    [
        ["/test", "/(\\d+)"] as AnyObject,
        nil,
        [
            [
                "name": 0,
                "prefix": nil,
                "delimiter": nil,
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": nil
            ]
            ] as AnyObject,
        [
            ["/test", ["/test", nil]]
            ] as AnyObject,
        [] as AnyObject
    ],
    [
        ["/:test(\\d+)", "(.*)"] as AnyObject,
        nil,
        [
            [
                "name": "test",
                "prefix": "/",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "\\d+"
                ] as AnyObject,
            [
                "name": 0,
                "prefix": nil,
                "delimiter": nil,
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": nil
            ]
            ] as AnyObject,
        [
            ["/123", ["/123", "123", nil]],
            ["/abc", ["/abc", nil, "/abc"]]
            ] as AnyObject,
        [] as AnyObject
    ],
    
    /**
     * Correct names and indexes.
     */
    [
        ["/:test", "/route/:test"] as AnyObject,
        nil,
        [
            [
                "name": "test",
                "prefix": "/",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "[^\\/]+?"
                ] as AnyObject,
            [
                "name": "test",
                "prefix": "/",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "[^\\/]+?"
            ]
            ] as AnyObject,
        [
            ["/test", ["/test", "test", nil]],
            ["/route/test", ["/route/test", nil, "test"]]
            ] as AnyObject,
        [] as AnyObject
    ],
    [
        ["^/([^/]+)$", "^/route/([^/]+)$"] as AnyObject,
        nil,
        [
            [
                "name": 0,
                "prefix": nil,
                "delimiter": nil,
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": nil
                ] as AnyObject,
            [
                "name": 0,
                "prefix": nil,
                "delimiter": nil,
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": nil
            ]
            ] as AnyObject,
        [
            ["/test", ["/test", "test", nil]],
            ["/route/test", ["/route/test", nil, "test"]]
            ] as AnyObject,
        [] as AnyObject
    ],
    
    /**
     * Ignore non-matching groups in regexps.
     */
    /*
    [
        "(?:.*)" as AnyObject,
        nil,
        [] as AnyObject,
        [
            ["/anything/you/want", ["/anything/you/want"]]
            ] as AnyObject,
        [] as AnyObject
    ],
    */
    
    /**
     * Respect escaped characters.
     */
    [
        "/\\(testing\\)" as AnyObject,
        nil,
        [
            "/(testing)"
            ] as AnyObject,
        [
            ["/testing", nil],
            ["/(testing)", ["/(testing)"]]
            ] as AnyObject,
        [
            [nil, "/(testing)"]
            ] as AnyObject
    ],
    [
        "/.+*?=^!:${}[]|" as AnyObject,
        nil,
        [
            "/.+*?=^!:${}[]|"
            ] as AnyObject,
        [
            ["/.+*?=^!:${}[]|", ["/.+*?=^!:${}[]|"]]
            ] as AnyObject,
        [
            [nil, "/.+*?=^!:${}[]|"]
            ] as AnyObject
    ],
    [
        "/test\\/:uid(u\\d+)?:cid(c\\d+)?" as AnyObject,
        nil,
        [
            "/test/",
            [
                "name": "uid",
                "prefix": "",
                "delimiter": "/",
                "optional": true,
                "repeat": false,
                "partial": false,
                "pattern": "u\\d+"
                ] as AnyObject,
            [
                "name": "cid",
                "prefix": "",
                "delimiter": "/",
                "optional": true,
                "repeat": false,
                "partial": false,
                "pattern": "c\\d+"
            ]
            ] as AnyObject,
        [
            ["/test", nil],
            ["/test/", ["/test/", nil, nil]],
            ["/test/u123", ["/test/u123", "u123", nil]],
            ["/test/c123", ["/test/c123", nil, "c123"]],
            ] as AnyObject,
        [
            [[ "uid": "u123" ], "/test/u123"],
            [[ "cid": "c123" ], "/test/c123"],
            [[ "cid": "u123" ], nil]
            ] as AnyObject
    ],
    
    /**
     * Unnamed group prefix.
     */
    [
        "/(apple-)?icon-:res(\\d+).png" as AnyObject,
        nil,
        [
            [
                "name": 0,
                "prefix": "/",
                "delimiter": "/",
                "optional": true,
                "repeat": false,
                "partial": true,
                "pattern": "apple-"
                ] as AnyObject,
            "icon-",
            [
                "name": "res",
                "prefix": "",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "\\d+"
                ] as AnyObject,
            ".png"
            ] as AnyObject,
        [
            ["/icon-240.png", ["/icon-240.png", nil, "240"]],
            ["/apple-icon-240.png", ["/apple-icon-240.png", "apple-", "240"]]
            ] as AnyObject,
        [] as AnyObject
    ],
    
    /**
     * Random examples.
     */
    [
        "/:foo/:bar" as AnyObject,
        nil,
        [
            [
                "name": "foo",
                "prefix": "/",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "[^\\/]+?"
                ] as AnyObject,
            [
                "name": "bar",
                "prefix": "/",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "[^\\/]+?"
            ]
            ] as AnyObject,
        [
            ["/match/route", ["/match/route", "match", "route"]]
            ] as AnyObject,
        [
            [[ "foo": "a", "bar": "b" ], "/a/b"]
            ] as AnyObject
    ],
    [
        "/:foo(test\\)/bar" as AnyObject,
        nil,
        [
            [
                "name": "foo",
                "prefix": "/",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": true,
                "pattern": "[^\\/]+?"
                ] as AnyObject,
            "(test)/bar"
            ] as AnyObject,
        [] as AnyObject,
        [] as AnyObject
    ],
    [
        "/:remote([\\w-.]+)/:user([\\w-]+)" as AnyObject,
        nil,
        [
            [
                "name": "remote",
                "prefix": "/",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "[\\w-.]+"
                ] as AnyObject,
            [
                "name": "user",
                "prefix": "/",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "[\\w-]+"
            ]
            ] as AnyObject,
        [
            ["/endpoint/user", ["/endpoint/user", "endpoint", "user"]],
            ["/endpoint/user-name", ["/endpoint/user-name", "endpoint", "user-name"]],
            ["/foo.bar/user-name", ["/foo.bar/user-name", "foo.bar", "user-name"]]
            ] as AnyObject,
        [
            [[ "remote": "foo", "user": "bar" ], "/foo/bar"],
            [[ "remote": "foo.bar", "user": "uno" ], "/foo.bar/uno"]
            ] as AnyObject
    ],
    [
        "/:foo\\?" as AnyObject,
        nil,
        [
            [
                "name": "foo",
                "prefix": "/",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": true,
                "pattern": "[^\\/]+?"
                ] as AnyObject,
            "?"
            ] as AnyObject,
        [
            ["/route?", ["/route?", "route"]]
            ] as AnyObject,
        [
            [[ "foo": "bar" ], "/bar?"]
            ] as AnyObject
    ],
    [
        "/:foo+baz" as AnyObject,
        nil,
        [
            [
                "name": "foo",
                "prefix": "/",
                "delimiter": "/",
                "optional": false,
                "repeat": true,
                "partial": true,
                "pattern": "[^\\/]+?"
                ] as AnyObject,
            "baz"
            ] as AnyObject,
        [
            ["/foobaz", ["/foobaz", "foo"]],
            ["/foo/barbaz", ["/foo/barbaz", "foo/bar"]],
            ["/baz", nil]
            ] as AnyObject,
        [
            [[ "foo": "foo" ], "/foobaz"],
            [[ "foo": "foo/bar" ], "/foo%2Fbarbaz"],
            [[ "foo": ["foo", "bar"] ], "/foo/barbaz"]
            ] as AnyObject
    ],
    [
        "/:pre?baz" as AnyObject,
        nil,
        [
            [
                "name": "pre",
                "prefix": "/",
                "delimiter": "/",
                "optional": true,
                "repeat": false,
                "partial": true,
                "pattern": "[^\\/]+?"
                ] as AnyObject,
            "baz"
            ] as AnyObject,
        [
            ["/foobaz", ["/foobaz", "foo"]],
            ["/baz", ["/baz", nil]]
            ] as AnyObject,
        [
            [EmptyDict, "/baz"],
            [[ "pre": "foo" ], "/foobaz"]
            ] as AnyObject
    ],
    [
        "/:foo\\(:bar?\\)" as AnyObject,
        nil,
        [
            [
                "name": "foo",
                "prefix": "/",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": true,
                "pattern": "[^\\/]+?"
                ] as AnyObject,
            "(",
            [
                "name": "bar",
                "prefix": "",
                "delimiter": "/",
                "optional": true,
                "repeat": false,
                "partial": false,
                "pattern": "[^\\/]+?"
                ] as AnyObject,
            ")"
            ] as AnyObject,
        [
            ["/hello(world)", ["/hello(world)", "hello", "world"]],
            ["/hello()", ["/hello()", "hello", nil]]
            ] as AnyObject,
        [
            [[ "foo": "hello", "bar": "world" ], "/hello(world)"],
            [[ "foo": "hello" ], "/hello()"]
            ] as AnyObject
    ],
    [
        "/:postType(video|audio|text)(\\+.+)?" as AnyObject,
        nil,
        [
            [
                "name": "postType",
                "prefix": "/",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": true,
                "pattern": "video|audio|text"
                ] as AnyObject,
            [
                "name": 0,
                "prefix": "",
                "delimiter": "/",
                "optional": true,
                "repeat": false,
                "partial": false,
                "pattern": "\\+.+"
            ]
            ] as AnyObject,
        [
            ["/video", ["/video", "video", nil]],
            ["/video+test", ["/video+test", "video", "+test"]],
            ["/video+", nil]
            ] as AnyObject,
        [
            [[ "postType": "video" ], "/video"],
            [[ "postType": "random" ], nil]
            ] as AnyObject
    ],
    
    /**
     * Unicode characters.
     */
    [
        "/:foo" as AnyObject,
        nil,
        [
            [
                "name": "foo",
                "prefix": "/",
                "delimiter": "/",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "[^\\/]+?"
            ]
            ] as AnyObject,
        [
            ["/café", ["/café", "café"]]
            ] as AnyObject,
        [
            [[ "foo": "café" ], "/caf%C3%A9"]
            ] as AnyObject
    ],
    [
        "/café" as AnyObject,
        nil,
        [
            "/café"
            ] as AnyObject,
        [
            ["/café", ["/café"]]
            ] as AnyObject,
        [
            [nil, "/café"]
            ] as AnyObject
    ],
    
    /**
     * Hostnames.
     */
    [
        ":domain.com" as AnyObject,
        [
            "delimiter": "."
            ] as AnyObject,
        [
            [
                "name": "domain",
                "prefix": "",
                "delimiter": ".",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "[^\\.]+?"
                ] as AnyObject,
            ".com"
            ] as AnyObject,
        [
            ["example.com", ["example.com", "example"]],
            ["github.com", ["github.com", "github"]],
            ] as AnyObject,
        [
            [[ "domain": "example" ], "example.com"],
            [[ "domain": "github" ], "github.com"]
            ] as AnyObject
    ],
    [
        "mail.:domain.com" as AnyObject,
        [
            "delimiter": "."
            ] as AnyObject,
        [
            "mail",
            [
                "name": "domain",
                "prefix": ".",
                "delimiter": ".",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "[^\\.]+?"
                ] as AnyObject,
            ".com"
            ] as AnyObject,
        [
            ["mail.example.com", ["mail.example.com", "example"]],
            ["mail.github.com", ["mail.github.com", "github"]]
            ] as AnyObject,
        [
            [[ "domain": "example" ], "mail.example.com"],
            [[ "domain": "github" ], "mail.github.com"]
            ] as AnyObject
    ],
    [
        "example.:ext" as AnyObject,
        [
            "delimiter": "."
            ] as AnyObject,
        [
            "example",
            [
                "name": "ext",
                "prefix": ".",
                "delimiter": ".",
                "optional": false,
                "repeat": false,
                "partial": false,
                "pattern": "[^\\.]+?"
            ]
            ] as AnyObject,
        [
            ["example.com", ["example.com", "com"]],
            ["example.org", ["example.org", "org"]],
            ] as AnyObject,
        [
            [[ "ext": "com" ], "example.com"],
            [[ "ext": "org" ], "example.org"]
            ] as AnyObject
    ],
    [
        "this is" as AnyObject,
        [
            "delimiter": " ",
            "end": false
            ] as AnyObject,
        [
            "this is"
            ] as AnyObject,
        [
            ["this is a test", ["this is"]],
            ["this isn\"t", nil]
            ] as AnyObject,
        [
            [nil, "this is"]
            ] as AnyObject
    ],
    
    /**
     * Ends with.
     */
    [
        "/test" as AnyObject,
        [
            "endsWith": "?"
            ] as AnyObject,
        [
            "/test"
            ] as AnyObject,
        [
            ["/test", ["/test"]],
            ["/test?query=string", ["/test"]],
            ["/test/?query=string", ["/test/"]],
            ["/testx", nil]
            ] as AnyObject,
        [
            [nil, "/test"]
            ] as AnyObject
    ],
    [
        "/test" as AnyObject,
        [
            "endsWith": "?",
            "strict": true
            ] as AnyObject,
        [
            "/test"
            ] as AnyObject,
        [
            ["/test?query=string", ["/test"]],
            ["/test/?query=string", nil]
            ] as AnyObject,
        [
            [nil, "/test"]
            ] as AnyObject
    ],
    
    /**
     * Custom delimiters.
     */
    [
        "$:foo$:bar?" as AnyObject,
        [
            "delimiters": "$"
            ] as AnyObject,
        [
            [
                "delimiter": "$",
                "name": "foo",
                "optional": false,
                "partial": false,
                "pattern": "[^\\$]+?",
                "prefix": "$",
                "repeat": false
                ] as AnyObject,
            [
                "delimiter": "$",
                "name": "bar",
                "optional": true,
                "partial": false,
                "pattern": "[^\\$]+?",
                "prefix": "$",
                "repeat": false
            ]
            ] as AnyObject,
        [
            ["$x", ["$x", "x", nil]],
            ["$x$y", ["$x$y", "x", "y"]]
            ] as AnyObject,
        [
            [[ "foo": "foo" ], "$foo"],
            [[ "foo": "foo", "bar": "bar" ], "$foo$bar"],
            ] as AnyObject
    ],
]
