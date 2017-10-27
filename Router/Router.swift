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
    private func rootMiddleware(type:RouteType, parameters:[String : String], controller:UIViewController?, next:() -> Void){
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
    private func callMiddleware(type:RouteType,parameters:[String:String],controller:UIViewController?,middlewares:[Middleware],index:Int = -1){
        let index = index < 0 ? middlewares.count : index
        let middleware = middlewares[index]
        middleware(type, parameters, controller) {
            if index != 0{
                self.callMiddleware(type: type, parameters: parameters, controller: controller, middlewares: middlewares,index: index - 1)
            }
        }
    }
    private func urlParse(url:String)->(String,[String:String]){
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
        print("[router] push:",path)
        let (path,parameters) = urlParse(url: path)
        self.router.route(url: path, parameters: parameters) { (parameters, controller) in
            self.callMiddleware(type:.push,parameters: parameters,controller: controller,middlewares: self.middlewares)
        }
    }
    func replace(path:String){
        print("[router] replace:",path)
        let (path,parameters) = urlParse(url: path)
        self.router.route(url: path, parameters: parameters) { (parameters, controller) in
            self.callMiddleware(type:.replase,parameters: parameters,controller: controller,middlewares: self.middlewares)
        }
    }
    func pop(){
        print("[router] pop")
        self.rootNav()?.popViewController(animated: true)
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
    func addMiddleware(middleware: @escaping Middleware) {
        middlewares.append(middleware)
    }
}

class PathRouter:NSObject,Router {
    struct Comptent {
        typealias MatchParser = (String)->[String:String]?
        typealias Comptenter = (String,[String:String],([String:String],UIViewController?)->Void)->Void
        private let parser: MatchParser
        private let comptenter: Comptenter
        let isDefault:Bool
        init(parser: @escaping MatchParser,comptenter: @escaping Comptenter,isDefault:Bool = false) {
            self.parser = parser
            self.comptenter = comptenter
            self.isDefault = isDefault
        }
        func parse(path:String) -> [String:String]? {
            return parser(path)
        }
        func invoke(path:String,parameters:[String:String],handle:([String:String],UIViewController?)->Void) {
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
    func replace(path:String){
        self.parent?.replace(path: path)
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
    func addRouter(path:String,comptent:@escaping (String,[String:String])->UIViewController?){
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
        let comptenter = { (url:String,parameters:[String:String],handle:([String:String],UIViewController?) -> Void) in
             handle(parameters,comptent(url, parameters))
        }
        addComptent(comptent: Comptent(parser: parser,comptenter: comptenter))
    }
    func addDefaultRouter(comptent:@escaping (String,[String:String])->UIViewController?){
        print("[router] addDefaultRouter")
        let parser = { (url:String) -> [String:String]? in
            return ["matched":url]
        }
        let comptenter = { (url:String,parameters:[String:String],handle:([String:String],UIViewController?) -> Void) in
            handle(parameters,comptent(url, parameters))
        }
        addComptent(comptent: Comptent(parser: parser, comptenter: comptenter, isDefault:true))
    }
    func addSubRouter(path:String, comptent:@escaping (String,[String:String])->Void) -> Router {
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
        let comptenter = { (url:String,parameters:[String:String],handle:([String:String],UIViewController?) -> Void) in
            comptent(url,parameters)
            let match = parameters["matched"] ?? ""
            router.route(url: String(url.dropFirst(match.characters.count)), parameters: parameters,handle: handle)
        }
        addComptent(comptent: Comptent(parser: parser,comptenter: comptenter))
        return router
    }
    
    func route(url:String,parameters:[String:String] = [:],handle:([String:String],UIViewController?) -> Void) {
        for comptent in self.comptents {
            if var param = comptent.parse(path: url) {
                param.merge(parameters, uniquingKeysWith: { (first, _) -> String in first })
                param["fullMatched"] = (parameters["fullMatched"] ?? "") + (param["matched"] ?? "")
                print("[router] route:",url,"parameters:",param)
                comptent.invoke(path:url,parameters:param,handle:handle)
            }
        }
    }
    
    func addMiddleware(middleware:@escaping Middleware ) {
        self.parent?.addMiddleware(middleware: middleware)
    }
}
