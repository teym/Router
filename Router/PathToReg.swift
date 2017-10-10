//
//  PathToReg.swift
//  Router
//
//  Created by 王航 on 2017/9/29.
//  Copyright © 2017年 mike. All rights reserved.
//

import Foundation
import SwiftyRe

extension String {
    var length:Int {
        return self.characters.count
    }
}
extension Array {
    public func appendWith<S>(contentsOf newElements: S) -> Array where S : Sequence, Element == S.Element {
        var arr = self
        arr.append(contentsOf: newElements)
        return arr
    }
}

enum NameToken {
    case Name(String)
    case Index(Int)
}
struct TokenInfo {
    let name:NameToken
    let prefix:String
    let delimiter:String
    let optional:Bool
    let i_repeat:Bool
    let partial:Bool
    let pattern:String
    init(name:NameToken, prefix:String,delimiter:String,optional:Bool,i_repeat:Bool,partial:Bool,pattern:String) {
        self.name = name
        self.prefix = prefix
        self.delimiter = delimiter
        self.optional = optional
        self.i_repeat = i_repeat
        self.partial = partial
        self.pattern = pattern
    }
    init(name:String, prefix:String,delimiter:String,optional:Bool,i_repeat:Bool,partial:Bool,pattern:String) {
        self.init(name: .Name(name),
                  prefix: prefix,
                  delimiter: delimiter,
                  optional: optional,
                  i_repeat: i_repeat,
                  partial: partial,
                  pattern: pattern)
    }
    init(name:Int, prefix:String,delimiter:String,optional:Bool,i_repeat:Bool,partial:Bool,pattern:String) {
        self.init(name: .Index(name),
                  prefix: prefix,
                  delimiter: delimiter,
                  optional: optional,
                  i_repeat: i_repeat,
                  partial: partial,
                  pattern: pattern)
    }
}
enum ParseToken{
    case Path(String)
    case Token(TokenInfo)
}

let PATH_REGEXP = Re([
    // Match escaped characters that would otherwise appear in future matches.
    // This allows the user to escape special characters that won't transform.
    "(\\\\.)",
    // Match Express-style parameters and un-named parameters with a prefix
    // and optional suffixes. Matches appear as:
    //
    // "/:test(\\d+)?" => ["/", "test", "\d+", undefined, "?"]
    // "/route(\\d+)"  => [undefined, undefined, undefined, "\d+", undefined]
    "(?:\\:(\\w+)(?:\\(((?:\\\\.|[^\\\\()])+)\\))?|\\(((?:\\\\.|[^\\\\()])+)\\))([+*?])?"
    ].joined(separator: "|"),"g")

/**
 * Parse a string for the raw tokens.
 *
 * @param  {string}  str
 * @param  {Object=} options
 * @return {!Array}
 */
func parse(str:String, options:[String:AnyObject]) -> [ParseToken] {
    var tokens = [ParseToken]()
    var key = 0
    var index = 0
    var path = ""
    let defaultDelimiter = (options["delimiter"] as? String) ?? "/"
    let delimiters = (options["delimiters"] as? String) ?? "./"
    var pathEscaped = false
    
    while let ret = PATH_REGEXP.exec(str) {
        let res = ret.values
        let offset = ret.index
        let m = res[0]
        let escaped = res[1]
        path += str.slice(start: index, end: offset)
        index = offset + m.length
        
        // Ignore already escaped sequences.
        if !escaped.isEmpty {
            path.append(escaped[1] ?? "")
            pathEscaped = true
            continue
        }
    
        var prev = ""
        let next = str[index] ?? ""
        let name = res[2]
        let capture = res[3]
        let group = res[4]
        let modifier = res[5]
    
        if (!pathEscaped && path.length > 0) {
            let k = path.length - 1
            if delimiters.contains(path[k] ?? "") {
                prev = path[k] ?? ""
                path = path.slice(start: 0, end: k)
          }
        }
    
        // Push the current path onto the tokens.
        if (path.length > 0) {
            tokens.append(.Path(path))
            path = ""
            pathEscaped = false
        }
    
        let partial = !prev.isEmpty && !next.isEmpty && next != prev
        let i_repeat = modifier == "+" || modifier == "*"
        let optional = modifier == "?" || modifier == "*"
        let delimiter = !prev.isEmpty ? prev : defaultDelimiter
        let pattern = capture.isEmpty && group.isEmpty ?
            "[^" + escapeString(str: delimiter) + "]+?" :
            escapeGroup(group: capture.isEmpty ? group : capture)

        if !name.isEmpty {
            tokens.append(.Token(TokenInfo(name: name,
                                           prefix: prev,
                                           delimiter: delimiter,
                                           optional: optional,
                                           i_repeat: i_repeat,
                                           partial: partial,
                                           pattern: pattern)))
        }else {
            tokens.append(.Token(TokenInfo(name: key,
                                           prefix: prev,
                                           delimiter: delimiter,
                                           optional: optional,
                                           i_repeat: i_repeat,
                                           partial: partial,
                                           pattern: pattern)))
            key += 1
        }
      }
    
      // Push any remaining characters.
      if (!path.isEmpty || index < str.length) {
        let p = path + str.slice(start: index)
        tokens.append(.Path(p))
      }

      return tokens
}
//
///**
// * Compile a string to a template function for the path.
// *
// * @param  {string}             str
// * @param  {Object=}            options
// * @return {!function(Object=, Object=)}
// */
//function compile (str, options) {
//  return tokensToFunction(parse(str, options))
//}
//
///**
// * Expose a method for transforming tokens into the path function.
// */
//function tokensToFunction (tokens) {
//  // Compile all the tokens into regexps.
//  var matches = new Array(tokens.length)
//
//  // Compile all the patterns before compilation.
//  for (var i = 0; i < tokens.length; i++) {
//    if (typeof tokens[i] === 'object') {
//      matches[i] = new RegExp('^(?:' + tokens[i].pattern + ')$')
//    }
//  }
//
//  return function (data, options) {
//    var path = ''
//    var encode = (options && options.encode) || encodeURIComponent
//
//    for (var i = 0; i < tokens.length; i++) {
//      var token = tokens[i]
//
//      if (typeof token === 'string') {
//        path += token
//        continue
//      }
//
//      var value = data ? data[token.name] : undefined
//      var segment
//
//      if (Array.isArray(value)) {
//        if (!token.repeat) {
//          throw new TypeError('Expected "' + token.name + '" to not repeat, but got array')
//        }
//
//        if (value.length === 0) {
//          if (token.optional) continue
//
//          throw new TypeError('Expected "' + token.name + '" to not be empty')
//        }
//
//        for (var j = 0; j < value.length; j++) {
//          segment = encode(value[j])
//
//          if (!matches[i].test(segment)) {
//            throw new TypeError('Expected all "' + token.name + '" to match "' + token.pattern + '"')
//          }
//
//          path += (j === 0 ? token.prefix : token.delimiter) + segment
//        }
//
//        continue
//      }
//
//      if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') {
//        segment = encode(String(value))
//
//        if (!matches[i].test(segment)) {
//          throw new TypeError('Expected "' + token.name + '" to match "' + token.pattern + '", but got "' + segment + '"')
//        }
//
//        path += token.prefix + segment
//        continue
//      }
//
//      if (token.optional) {
//        // Prepend partial segment prefixes.
//        if (token.partial) path += token.prefix
//
//        continue
//      }
//
//      throw new TypeError('Expected "' + token.name + '" to be ' + (token.repeat ? 'an array' : 'a string'))
//    }
//
//    return path
//  }
//}

/**
 * Escape a regular expression string.
 *
 * @param  {string} str
 * @return {string}
 */
func escapeString (str:String) -> String {
    return Re("([\\.\\+\\*\\?\\=\\^\\!\\:\\$\\{\\}\\(\\)\\[\\]\\|\\/\\\\])", "g").replace(str, {"\\" + $0.values[1]})
//  return str.replace(/([.+*?=^!:${}()[\]|/\\])/g, '\\$1')
}

/**
 * Escape the capturing group by escaping special characters and meaning.
 *
 * @param  {string} group
 * @return {string}
 */
func escapeGroup (group:String) -> String {
    return Re("([\\=\\!\\:\\$\\/\\(\\)])","g").replace(group, {"\\" + $0.values[1]})
//  return group.replace(/([=!:$/()])/g, '\\$1')
}

/**
 * Get the flags for a regexp from the options.
 *
 * @param  {Object} options
 * @return {string}
 */
func flags(options:[String:AnyObject]) -> String {
    let sensitive = (options["sensitive"] as? Bool) ?? false
    return sensitive ? "" : "i"
}

///**
// * Pull out keys from a regexp.
// *
// * @param  {!RegExp} path
// * @param  {Array=}  keys
// * @return {!RegExp}
// */
//function regexpToRegexp (path, keys) {
//  if (!keys) return path
//
//  // Use a negative lookahead to match only capturing groups.
//  var groups = path.source.match(/\((?!\?)/g)
//
//  if (groups) {
//    for (var i = 0; i < groups.length; i++) {
//      keys.push({
//        name: i,
//        prefix: null,
//        delimiter: null,
//        optional: false,
//        repeat: false,
//        partial: false,
//        pattern: null
//      })
//    }
//  }
//
//  return path
//}
//
///**
// * Transform an array into a regexp.
// *
// * @param  {!Array}  path
// * @param  {Array=}  keys
// * @param  {Object=} options
// * @return {!RegExp}
// */
//function arrayToRegexp (path, keys, options) {
//  var parts = []
//
//  for (var i = 0; i < path.length; i++) {
//    parts.push(pathToRegexp(path[i], keys, options).source)
//  }
//
//  return new RegExp('(?:' + parts.join('|') + ')', flags(options))
//}

/**
 * Create a path regexp from string input.
 *
 * @param  {string}  path
 * @param  {Array=}  keys
 * @param  {Object=} options
 * @return {!RegExp}
 */
func stringToRegexp (path:String, options:[String:AnyObject] = [:]) -> (Re,[TokenInfo]) {
    return tokensToRegExp(tokens:parse(str:path, options:options), options:options)
}

/**
 * Expose a function for taking tokens and returning a RegExp.
 *
 * @param  {!Array}  tokens
 * @param  {Array=}  keys
 * @param  {Object=} options
 * @return {!RegExp}
 */
func tokensToRegExp (tokens:[ParseToken], options:[String:AnyObject]) -> (Re,[TokenInfo]) {
//  options = options || {}
    
    let strict = (options["strict"] as? Bool) ?? false
    let end = (options["end"] as? Bool) ?? true
    let delimiter = escapeString(str: (options["delimiter"] as? String) ?? "/")
    let endsWith = [String]().appendWith(contentsOf: ([options["endsWith"]] as? [String]) ?? []).map({escapeString(str: $0)}).appendWith(contentsOf:["$"]).joined(separator: "|")
    var route = ""
    var keys = [TokenInfo]()

  // Iterate over the tokens and create our regexp string.
    for i in 0..<tokens.count {
        let token = tokens[i]
        switch token {
        case .Path(let path):
            route += escapeString(str: path)
        case .Token(let token):
            let prefix = escapeString(str: token.prefix)
            var capture = "(?:" + token.pattern + ")"
            
            keys.append(token)
            
            if (token.i_repeat) {
                capture += "(?:" + prefix + capture + ")*"
            }
            
            if (token.optional) {
                if (!token.partial) {
                    capture = "(?:" + prefix + "(" + capture + "))?"
                } else {
                    capture = prefix + "(" + capture + ")?"
                }
            } else {
                capture = prefix + "(" + capture + ")"
            }
            
            route += capture
        }
    }
    
    if (end) {
        if (!strict){
            route += "(?:" + delimiter + ")?"
        }
        route += endsWith == "$" ? "$" : "(?=" + endsWith + ")"
    } else {
        if (!strict) {
            route += "(?:" + delimiter + "(?=" + endsWith + "))?"
        }
        route += "(?=" + delimiter + "|" + endsWith + ")"
    }

    return (Re("^" + route, flags(options: options)) , keys)
}
//
///**
// * Normalize the given path string, returning a regular expression.
// *
// * An empty array can be passed in for the keys, which will hold the
// * placeholder key descriptions. For example, using `/user/:id`, `keys` will
// * contain `[{ name: 'id', delimiter: '/', optional: false, repeat: false }]`.
// *
// * @param  {(string|RegExp|Array)} path
// * @param  {Array=}                keys
// * @param  {Object=}               options
// * @return {!RegExp}
// */
//function pathToRegexp (path, keys, options) {
//  if (path instanceof RegExp) {
//    return regexpToRegexp(path, keys)
//  }
//
//  if (Array.isArray(path)) {
//    return arrayToRegexp(/** @type {!Array} */ (path), keys, options)
//  }
//
//  return stringToRegexp(/** @type {string} */ (path), keys, options)
//}
