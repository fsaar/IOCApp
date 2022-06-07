//
//  ViewController.swift
//  iocApp
//
//  Created by Frank Saar on 07/06/2022.
//

import UIKit
import IOCFramework

struct SA : Hashable {
    let uuid = UUID()
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid.uuidString)
    }
    
    static func ==(lhs : Self,rhs : Self) -> Bool {
        return lhs.uuid.uuidString == rhs.uuid.uuidString
    }
}

class ViewController: UIViewController {

    
    let container = IOCContainer()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            container.register(type: SA.self) { SA() }
            let value = try container.resolve(type:SA.self)
            test(desc:"registration ",result:value != nil)
            
            container.deregister(type: SA.self)
            let value2 = try container.resolve(type:SA.self)
            test(desc: "deregistration",result: value2 == nil)

            container.register(type: SA.self,scope:.shared) { SA() }
            let value3 = try container.resolve(type:SA.self)
            let value4 = try container.resolve(type:SA.self)
            let succ = value3 == value4
            test(desc:"Shared scope",result:succ)
        }
        catch let error {
            print(error)
        }
       
    }
    
    func test(desc: String,result: Bool) {
        
        print("\(desc): \(result ? "Success" : "Failure")")
        assert(result)

    }

}


