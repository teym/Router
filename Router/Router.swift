//
//  Router.swift
//  Router
//
//  Created by 王航 on 2017/9/29.
//  Copyright © 2017年 mike. All rights reserved.
//

import UIKit
import Interfaces

class MRouter:NSObject, Router, Module {
    static func interfaces() -> [AnyObject] {
        return [Router.self as AnyObject]
    }
    static func loadOnStart() -> Bool {
        return false
    }
    private var router:PathRouter! = nil
    private var root: UINavigationController? = nil
    private var middlewares:[Middleware] = []
    required init(inject: ModuleInject) {
        super.init()
        self.router = PathRouter(parent: self)
        self.addMiddleware { [weak self] (a,b,c,d) in self?.rootMiddleware(type: a, parameters: b, controller: c, next: d)}
    }
    private func rootMiddleware(type:RouteType, parameters:[String : Any], controller:UIViewController?, next:() -> Void){
        guard let controller = controller else { return }
        guard let nav = self.rootNav() else { return }
        var list = type == .push ? nav.viewControllers : Array(nav.viewControllers.dropLast())
        if let index = list.index(of: controller) {
            list.remove(at: index)
            nav.setViewControllers(list.appendWith(contentsOf: [controller]), animated: true)
        }else{
            if type == .push {
                nav.pushViewController(controller, animated: true)
            }else {
                nav.setViewControllers(list.appendWith(contentsOf: [controller]), animated: true)
            }
        }
    }
    private func rootNav() -> UINavigationController? {
        guard self.root == nil else {
            return self.root
        }
        self.root = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController
        return self.root
    }
    private func callMiddleware(type:RouteType,parameters:[String:Any],controller:UIViewController?,middlewares:[Middleware],index:Int = -1){
        let index = index < 0 ? (middlewares.count - 1) : index
        let middleware = middlewares[index]
        middleware(type, parameters, controller) {
            if index != 0{
                self.callMiddleware(type: type, parameters: parameters, controller: controller, middlewares: middlewares,index: index - 1)
            }
        }
    }
    private func urlParse(url:String,parameters:[String:Any],pass:[String:Any])->(String,[String:Any]){
        let kv = parameters.mapValues { (val) -> String in
            if let dicStr = (val as? [String:Any]).flatMap({
                try? JSONSerialization.data(withJSONObject: $0, options: .init(rawValue: 0))
            }).flatMap({String(data: $0, encoding: .utf8)}) {
                return dicStr
            }
            if let arrStr = (val as? [Any]).flatMap({
                try? JSONSerialization.data(withJSONObject: $0, options: .init(rawValue: 0))
            }).flatMap({String(data: $0, encoding: .utf8)}) {
                return arrStr
            }
            if let str = val as? String {
                return str
            }
            return String(describing: val)
        }
        let queryItems = kv.map{ URLQueryItem(name: $0.0, value: $0.1)}
        var param = pass
        var path = url
        if var comp = URLComponents(string: url){
            comp.queryItems = queryItems.appendWith(contentsOf: (comp.queryItems ?? []))
            comp.queryItems = (comp.queryItems?.count ?? 0) == 0 ? nil : comp.queryItems
            param["URL"] = comp.string ?? url
            path = comp.path
            let kvs = (comp.queryItems ?? []).map({ (item) -> (String,Any) in
                return (item.name,item.value ?? "")
            })
            param.merge(kvs, uniquingKeysWith: { (first, _) -> Any in first })
        }
        return (path, param)
    }
    func push(path:String){
        self.push(path: path, parameters: [:], pass: [:])
    }
    func push(path: String, parameters: [String : Any], pass:[String:Any]) {
        print("[router] push:",path)
        let (path,params) = urlParse(url: path,parameters: parameters,pass: pass)
        self.router.route(url: path, parameters: params) {
            self.callMiddleware(type:.push,parameters: $0,controller: $1,middlewares: self.middlewares)
        }
    }
    func replace(path:String){
        self.replace(path: path, parameters: [:], pass: [:])
    }
    func replace(path: String, parameters: [String : Any], pass: [String : Any]) {
        print("[router] replace:",path)
        let (path,params) = urlParse(url: path, parameters: parameters,pass: pass)
        self.router.route(url: path, parameters: params) {
            self.callMiddleware(type:.replase,parameters: $0,controller: $1,middlewares: self.middlewares)
        }
    }
    func pop(){
        print("[router] pop")
        self.rootNav()?.popViewController(animated: true)
    }
    func addRouter(path:String,comptent:@escaping (String,[String:Any])->UIViewController?){
        self.router.addRouter(path: path, comptent: comptent)
    }
    func addDefaultRouter(comptent:@escaping (String,[String:Any])->UIViewController?){
        self.router.addDefaultRouter(comptent: comptent)
    }
    func addSubRouter(path:String, comptent:@escaping (String,[String:Any])->Void) -> Router {
        return self.router.addSubRouter(path: path, comptent: comptent)
    }
    func addMiddleware(middleware: @escaping Middleware) {
        middlewares.append(middleware)
    }
}

class PathRouter:NSObject,Router {
    struct Comptent {
        typealias MatchParser = (String)->[String:String]?
        typealias Comptenter = (String,[String:Any],([String:Any],UIViewController?)->Void)->Void
        private let parser: MatchParser
        private let comptenter: Comptenter
        let isDefault:Bool
        init(parser: @escaping MatchParser,comptenter: @escaping Comptenter,isDefault:Bool = false) {
            self.parser = parser
            self.comptenter = comptenter
            self.isDefault = isDefault
        }
        func parse(path:String) -> [String:Any]? {
            return parser(path)
        }
        func invoke(path:String,parameters:[String:Any],handle:([String:Any],UIViewController?)->Void) {
            comptenter(path,parameters,handle)
        }
    }
    
    weak var parent:Router?
    var comptents = [Comptent]()
    
    init(parent:Router) {
        self.parent = parent
        super.init()
    }
    
    func push(path:String){
        self.parent?.push(path: path)
    }
    func push(path: String, parameters: [String : Any], pass: [String : Any]) {
        self.parent?.push(path: path, parameters: parameters, pass: pass)
    }
    func replace(path:String){
        self.parent?.replace(path: path)
    }
    func replace(path: String, parameters: [String : Any], pass: [String : Any]) {
        self.parent?.replace(path: path, parameters: parameters, pass: pass)
    }
    func pop(){
        self.parent?.pop()
    }
    func addComptent(comptent:Comptent){
        guard !comptent.isDefault else {
            return comptents.append(comptent)
        }
        if let index = comptents.index(where: {$0.isDefault}){
            comptents.insert(comptent, at: index)
        }else {
            comptents.append(comptent)
        }
    }
    func addRouter(path:String,comptent:@escaping (String,[String:Any])->UIViewController?){
        print("[router] addRouter:",path)
        let (re, keys) = stringToRegexp(path: path)
        let names = ["matched"].appendWith(contentsOf: keys.map({ (t) -> String in
            switch t.name {
            case .Index(let i):
                return "\(i)"
            case .Name(let s):
                return s
            }
        }))
        let parser = { (url:String) -> [String:String]? in
            if let ret = re.match(url) {
                assert(names.count == ret.values.count)
                return Dictionary<String,String>(zip(names, ret.values),uniquingKeysWith: { (first, _) in first })
            }
            return nil
        }
        let comptenter = { (url:String,parameters:[String:Any],handle:([String:Any],UIViewController?) -> Void) in
             handle(parameters,comptent(url, parameters))
        }
        addComptent(comptent: Comptent(parser: parser,comptenter: comptenter))
    }
    func addDefaultRouter(comptent:@escaping (String,[String:Any])->UIViewController?){
        print("[router] addDefaultRouter")
        let parser = { (url:String) -> [String:String]? in
            return ["matched":url]
        }
        let comptenter = { (url:String,parameters:[String:Any],handle:([String:Any],UIViewController?) -> Void) in
            handle(parameters,comptent(url, parameters))
        }
        addComptent(comptent: Comptent(parser: parser, comptenter: comptenter, isDefault:true))
    }
    func addSubRouter(path:String, comptent:@escaping (String,[String:Any])->Void) -> Router {
        print("[router] addSubRouter:",path)
        let router = PathRouter(parent: self)
        let (re, keys) = stringToRegexp(path: path,options: ["end":false as AnyObject])
        let names = ["matched"].appendWith(contentsOf: keys.map({ (t) -> String in
            switch t.name {
            case .Index(let i):
                return "\(i)"
            case .Name(let s):
                return s
            }
        }))
        let parser = { (url:String) -> [String:String]? in
            if let ret = re.match(url) {
                assert(names.count == ret.values.count)
                return Dictionary<String,String>(zip(names, ret.values),uniquingKeysWith: { (_, last) in last})
            }
            return nil
        }
        let comptenter = { (url:String,parameters:[String:Any],handle:([String:Any],UIViewController?) -> Void) in
            comptent(url,parameters)
            let match = (parameters["matched"] as? String) ?? ""
            router.route(url: String(url.dropFirst(match.characters.count)), parameters: parameters,handle: handle)
        }
        addComptent(comptent: Comptent(parser: parser,comptenter: comptenter))
        return router
    }
    
    func route(url:String,parameters:[String:Any] = [:],handle:([String:Any],UIViewController?) -> Void) {
        for comptent in self.comptents {
            var params = [String:Any]()
            if let param = comptent.parse(path: url) {
                params.merge(param, uniquingKeysWith: { (first, _) -> Any in first})
                params.merge(parameters, uniquingKeysWith: { (first, _) -> Any in first})
                params["fullMatched"] = ((parameters["fullMatched"] as? String) ?? "") + ((param["matched"] as? String) ?? "")
                print("[router] route:",url,"parameters:",params)
                comptent.invoke(path:url,parameters:params,handle:handle)
            }
        }
    }
    
    func addMiddleware(middleware:@escaping Middleware ) {
        self.parent?.addMiddleware(middleware: middleware)
    }
}
