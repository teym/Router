//
//  Router.swift
//  Router
//
//  Created by 王航 on 2017/9/29.
//  Copyright © 2017年 mike. All rights reserved.
//

import Foundation
import UIKit
import Module

public protocol Router: NSObjectProtocol {
    func push(path:String)
    func replace(path:String)
    func pop()
    
    func addRouter(path:String,comptent:@escaping (String,[String:String])->UIViewController?)
    func addDefaultRouter(comptent:@escaping (String,[String:String])->UIViewController?)
    func addSubRouter(path:String, comptent:@escaping (String,[String:String])->Void) -> Router
}

class MRouter:NSObject, Router, Module {
    static func interfaces() -> [AnyObject] {
        return [Router.self as AnyObject]
    }
    static func loadOnStart() -> Bool {
        return false
    }
    var router:PathRouter! = nil
    var root: UINavigationController? = nil
    required init(inject: ModuleInject) {
        super.init()
        self.root = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController
        self.router = PathRouter(parent: self)
    }

    func push(path:String){
        if let controller = self.router.comptent(url: path){
            if let nav = self.root {
                if let index = nav.viewControllers.index(of: controller) {
                    var views = nav.viewControllers
                    views.remove(at: index)
                    views.append(controller)
                    nav.setViewControllers(views, animated: false)
                }else {
                    nav.pushViewController(controller, animated: true)
                }
            }
        }
    }
    func replace(path:String){
        if let controller = self.router.comptent(url: path){
            if let nav = self.root{
                var list = nav.viewControllers
                _ = list.popLast()
                if let index = list.index(of: controller) {
                    list.remove(at: index)
                }
                list.append(controller)
                nav.setViewControllers(list, animated: false)
            }
        }
    }
    func pop(){
        self.root?.popViewController(animated: true)
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
        let parser = { (url:String) -> [String:String]? in
            return ["matched":url]
        }
        let comptenter = { (url:String,parameters:[String:String]) -> UIViewController? in
            return comptent(url, parameters)
        }
        addComptent(comptent: Comptent(parser: parser, comptenter: comptenter, isDefault:true))
    }
    func addSubRouter(path:String, comptent:@escaping (String,[String:String])->Void) -> Router {
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
            return router.comptent(url: String(url.dropFirst(match.characters.count)))
        }
        addComptent(comptent: Comptent(parser: parser,comptenter: comptenter))
        return router
    }
    
    func comptent(url:String)->UIViewController? {
        let uri = URLComponents(string: url)
        let path = uri?.path ?? url
        for comptent in self.comptents {
            if var parameters = comptent.parser(path) {
                if let comp = uri{
                    let kvs = (comp.queryItems ?? []).map({ (item) -> (String,String) in
                        return (item.name,item.value ?? "")
                    })
                    parameters.merge(kvs, uniquingKeysWith: { (first, _) -> String in first })
                }
                
                return comptent.comptenter(url, parameters)
            }
        }
        return nil
    }
}
