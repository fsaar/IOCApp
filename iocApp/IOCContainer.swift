//
//  IOCContainer.swift
//  iocApp
//
//  Created by Frank Saar on 07/06/2022.
//

import Foundation

fileprivate struct WeakRef {
    fileprivate (set) weak var ref: AnyObject?
}


class IOCContainer {
    enum ContainerError : Error {
        case recursion
    }
    
    enum Scope  {
        case transient
        case shared
        case weak
    }
    
    private var resolverRecursionCount = 0
    typealias ClassResolverBlock = () -> AnyObject
    private var blockStorage : [String:(block:ClassResolverBlock,scope:Scope)] = [:]
    private var singletonStorage : [String:AnyObject] = [:]
    private var weakSingletonStorage : [String:WeakRef] = [:]

    func register<T:AnyObject>(type : T.Type,scope : Scope = .transient,block: @escaping ClassResolverBlock ) {
        let identifier = String(describing: T.self)
        blockStorage[identifier] = (block,scope)
    }
    
    func resolve<T: AnyObject>(type : T.Type) throws -> T? {
        resolverRecursionCount += 1
        defer {
            resolverRecursionCount -= 1
        }
        guard resolverRecursionCount < 10 else {
            throw ContainerError.recursion
        }
        
        let identifier = String(describing: T.self)
        guard let tuple = blockStorage[identifier] else {
            return nil
        }
        switch tuple.scope {
        case .transient:
            return tuple.block() as? T
        case .shared:
            if let instance = singletonStorage[identifier] as? T {
                return instance
            }
            guard let newInstance = tuple.block() as? T else {
                return nil
            }
            singletonStorage[identifier] = newInstance
            return newInstance
        case .weak:
            if let instance = weakSingletonStorage[identifier]?.ref as? T {
                return instance
            }
            guard let newInstance = tuple.block() as? T else {
                return nil
            }
            let weakRef = WeakRef(ref: newInstance)
            weakSingletonStorage[identifier] = weakRef
            return newInstance
        }
    }
    
    func deregister<T>(type : T.Type)  {
        let identifier = String(describing: T.self)
        blockStorage[identifier] = nil
        singletonStorage[identifier] = nil

    }
}
