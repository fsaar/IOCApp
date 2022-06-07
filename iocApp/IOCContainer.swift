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
    private var transientStorage : [String:AnyObject] = [:]
    private var singletonStorage : [String:AnyObject] = [:]
    private var weakSingletonStorage : [String:WeakRef] = [:]

    func register<T:AnyObject>(type : T.Type, tag: String? = nil,scope : Scope = .transient,block: @escaping ClassResolverBlock ) {
        let identifier = key(for: type,tag:tag)
        blockStorage[identifier] = (block,scope)
    }
    
    func resolve<T: AnyObject>(type : T.Type,tag: String? = nil) throws -> T? {
        resolverRecursionCount += 1
        defer {
            resolverRecursionCount -= 1
        }
        guard resolverRecursionCount < 10 else {
            throw ContainerError.recursion
        }
        let identifier = key(for: type, tag: tag)
        guard let tuple = blockStorage[identifier] else {
            return nil
        }
        
        switch tuple.scope {
        case .transient:
            let obj = instance(for : type,with: identifier, storage: &transientStorage, block: tuple.block)
            return obj
        case .shared:
            let obj = instance(for: type,with: identifier, storage: &singletonStorage,block:tuple.block)
            return obj
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

fileprivate extension IOCContainer {
    func instance<T:AnyObject>(for type:T.Type,with identifier: String,storage :inout  [String:AnyObject],block:ClassResolverBlock) -> T? {
       
        if let instance = storage[identifier] as? T {
            return instance
        }
        guard let newInstance = block() as? T else {
            return nil
        }
        storage[identifier] = newInstance
        return newInstance
    }
    
    func key<T:AnyObject>(for type:T.Type,tag: String? = nil) -> String {
        let normalisedTag = tag ?? ""
        let identifier = "\(String(describing: T.self))\(normalisedTag)"
        return identifier
    }
}
