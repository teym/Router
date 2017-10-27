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
    typealias RootMiddleware = (String, [String : String], UIViewController?, () -> Void) -> Void
    static func interfaces() -> [AnyObject] {
        return [Router.self as AnyObject]
    }
    static func loadOnStart() -> Bool {
        return false
    }
    var router:PathRouter! = nil
    var root: UINavigationController? = nil
    var middlewares:[RootMiddleware] = []
    required init(inject: ModuleInject) {
        super.init()
        self.router = PathRouter(parent: self)
        self.addMiddleware { [weak self] (a,b,c,d) in self?.rootMiddleware(type: a, parameters: b, controller: c, next: d)}
    }
    func rootMiddleware(type:String, parameters:[String : String], controller:UIViewController?, next:() -> Void){
        guard let controller = controller else { return }
        guard let nav = self.rootNav() else { return }
        var list = type == "push" ? nav.viewControllers : Array(nav.viewControllers.dropLast())
        if let index = list.index(of: controller) {
            list.remove(at: index)
            nav.setViewControllers(list.appendWith(contentsOf: [controller]), animated: true)
        }else{
            if type == "push" {
                nav.pushViewController(controller, animated: true)
            }else {
                nav.setViewControllers(list.appendWith(contentsOf: [controller]), animated: true)
            }
        }
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
        print("[router] push:",path)
        let (path,parameters) = urlParse(url: path)
        if let controller = self.router.comptent(url: path, parameters: parameters){
            if let nav = self.rootNav() {
                if let index = nav.viewControllers.index(of: controller) {
                    var views = nav.viewControllers
                    views.remove(at: index)
                    views.append(controller)
                    nav.setViewControllers(views, animated: false)
                }else {
                    nav.pushViewController(controller, animated: true)
                }
//                print("[router] pushed:",path," controller:",controller)
            }
        }
    }
    func replace(path:String){
        print("[router] replace:",path)
        let (path,parameters) = urlParse(url: path)
        if let controller = self.router.comptent(url: path, parameters: parameters){
            if let nav = self.rootNav(){
                var list = nav.viewControllers
                _ = list.popLast()
                if let index = list.index(of: controller) {
                    list.remove(at: index)
                }
                list.append(controller)
                nav.setViewControllers(list, animated: false)
//                print("[router] replaced:",path," controller:",controller)
            }
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
    func rootNav() -> UINavigationController? {
        guard self.root == nil else {
            return self.root
        }
        self.root = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController
        return self.root
    }
    
    func addMiddleware(middleware: @escaping RootMiddleware) {
        middlewares.append(middleware)
    }
}

class PathRouter:NSObject,Router {
    struct Comptent {
        typealias MatchParser = (String)->[String:String]?
        typealias Comptenter = (String,[String:String]) -> UIViewController?
        let parser: MatchParser
        let comptenter: Comptenter
        let isDefault:Bool
        init(parser: @escaping MatchParser,comptenter: @escaping Comptenter,isDefault:Bool = false) {
            self.parser = parser
            self.comptenter = comptenter
            self.isDefault = isDefault
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
        let comptenter = { (url:String,parameters:[String:String]) -> UIViewController? in
            return comptent(url, parameters)
        }
        addComptent(comptent: Comptent(parser: parser,comptenter: comptenter))
    }
    func addDefaultRouter(comptent:@escaping (String,[String:String])->UIViewController?){
        print("[router] addDefaultRouter")
        let parser = { (url:String) -> [String:String]? in
            return ["matched":url]
        }
        let comptenter = { (url:String,parameters:[String:String]) -> UIViewController? in
            return comptent(url, parameters)
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
        let comptenter = { (url:String,parameters:[String:String]) -> UIViewController? in
            comptent(url,parameters)
            let match = parameters["matched"] ?? ""
            return router.comptent(url: String(url.dropFirst(match.characters.count)), parameters: parameters)
        }
        addComptent(comptent: Comptent(parser: parser,comptenter: comptenter))
        return router
    }
    
    func comptent(url:String,parameters:[String:String] = [:])->UIViewController? {
        for comptent in self.comptents {
            if var param = comptent.parser(url) {
                param.merge(parameters, uniquingKeysWith: { (first, _) -> String in first })
                param["fullMatched"] = (parameters["fullMatched"] ?? "") + (param["matched"] ?? "")
                print("[router] route:",url,"parameters:",param)
                return comptent.comptenter(url, param)
            }
        }
        return nil
    }
    
    func addMiddleware(middleware: (String, [String : String], UIViewController?, () -> Void) -> Void) {
        self.parent?.addMiddleware(middleware: middleware)
    }
}
