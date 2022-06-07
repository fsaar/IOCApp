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
            try container.register { SA() }
            let value : SA = try container.resolve()
            let _ = value
            test(desc:"registration ",result:true)
            
            container.deregister(type: SA.self)
            do {
                let value2 : SA = try container.resolve()
                let _ = value2
                test(desc: "deregistration",result: false)
            }
            catch {
                test(desc: "deregistration",result: true)
            }
            
            try container.register(identifier: "classSA") { SA() }
            let valueWithId : SA = try container.resolve(identifier:"classSA")
            let _ = valueWithId
            test(desc:"registration with identifier",result:true)
            container.deregister(identifier:"classSA",type: SA.self)

            try container.register { SA() }
            let value3 : SA = try container.resolve(scope:.shared)
            let value4 : SA = try container.resolve(scope:.shared)
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


