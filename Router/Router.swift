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

public protocol Router {
    var root:UINavigationController?{get}
    func push(path:String)
    func replace(path:String)
    func pop()
    
    func addRouter(path:String,comptent:@escaping (String,[String:String])->UIViewController?)
    func addDefaultRouter(comptent:@escaping (String,[String:String])->UIViewController?)
    func addSubRouter(path:String, comptent:@escaping (String,[String:String])->Void) -> Router
    func addSubRouter(path:String, comptent:@escaping (String,[String:String])->Void, root:UINavigationController?) -> Router
}

class MRouter:NSObject, Router, Module {
    static func interfaces() -> [AnyObject] {
        return [Router.self as AnyObject]
    }
    static func loadOnStart() -> Bool {
        return false
    }
    let router:PathRouter
    required init(inject: ModuleInject) {
        let nav = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController
        self.router = PathRouter(parent: nil, root: nav)
        super.init()
    }

    var root: UINavigationController?{
        return self.router.root
    }
    func push(path:String){
        self.router.push(path: path)
    }
    func replace(path:String){
        self.router.replace(path: path)
    }
    func pop(){
        self.router.pop()
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
    func addSubRouter(path:String, comptent:@escaping (String,[String:String])->Void, root:UINavigationController?) -> Router{
        return self.router.addSubRouter(path: path, comptent: comptent, root: root)
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
    
    let root:UINavigationController?
    weak var parent:PathRouter?
    var comptents = [Comptent]()
    
    init(parent:PathRouter?, root:UINavigationController? = nil) {
        self.parent = parent
        self.root = root
        super.init()
    }
    
    func push(path:String){
        if let nav = self.root {
            if let controller = self.comptent(url: path) {
                nav.pushViewController(controller, animated: true)
            }
        }else {
            self.parent?.push(path: path)
        }
    }
    func replace(path:String){
        if let nav = self.root {
            if let controller = self.comptent(url: path) {
                var list = nav.viewControllers
                _ = list.popLast()
                list.append(controller)
                nav.setViewControllers(list, animated: false)
            }
        }else {
            self.parent?.replace(path: path)
        }
    }
    func pop(){
        if let nav = self.root {
            nav.popViewController(animated: true)
        }else {
            self.parent?.pop()
        }
    }
    func addComptent(comptent:Comptent){
        guard comptent.isDefault else {
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
        return self.addSubRouter(path: path, comptent: comptent, root: nil)
    }
    func addSubRouter(path:String, comptent:@escaping (String,[String:String])->Void, root:UINavigationController?) -> Router{
        let router = PathRouter(parent: self, root: root)
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
            comptent(url,parameters)
            return router.comptent(url: url)
        }
        addComptent(comptent: Comptent(parser: parser,comptenter: comptenter))
        return router
    }
    
    func comptent(url:String)->UIViewController? {
        for comptent in self.comptents {
            if let parameters = comptent.parser(url) {
                return comptent.comptenter(url, parameters)
            }
        }
        return nil
    }
}
