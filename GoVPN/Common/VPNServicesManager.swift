//
//  VPNServicesManager.swift
//  GoVPN
//
//  Created by Colin Harris on 13/2/20.
//  Copyright © 2020 Colin Harris. All rights reserved.
//

import Foundation
import os

class VPNServicesManager {
    
    static let shared = VPNServicesManager()
    
    var services: [VPNService] = []
    let serviceQueue: DispatchQueue
    
    private init() {
        self.services = []
        self.serviceQueue = DispatchQueue(label: "Network Extension Service Queue")
    }
    
    func loadConfigurationsWithHandler(handler: @escaping (Error?) -> Void) {
        let manager = NEConfigurationManager.sharedManager() as! NEConfigurationManager
            
        manager.loadConfigurations(
            withCompletionQueue: self.serviceQueue,
            handler: { (configurations: [NEConfiguration]?, error: Error?) -> Void in
                if let error = error {
                    os_log("ERROR loading configurations - %@", type: .error, error.localizedDescription)
                    return
                }
                
                DispatchQueue.main.async {
                    // Process the configurations
                    self.processConfigurations(configurations: configurations)
                    handler(error)
                }
            }
        )
    }
    
    func processConfigurations(configurations: [NEConfiguration]?) {
        // Fill the array
        self.services.removeAll()
        for configuration in configurations ?? [] {
            let service = VPNService(configuration: configuration)
            self.services.append(service)
        }
        
        // Refresh the states
        for service in self.services {
            service.refreshSession()
        }
    }
    
    func service(named name: String) -> VPNService? {
        return self.services.first { service in
            service.name() == name
        }
    }
}
