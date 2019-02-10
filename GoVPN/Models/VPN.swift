
//
//  VPN.swift
//  GoVPN
//
//  Created by Colin Harris on 7/1/19.
//  Copyright © 2019 Colin Harris. All rights reserved.
//

import Foundation

@objc
class VPN: NSObject {
    @objc var name: String
    @objc var enabled: Bool
    
    init(name: String, enabled: Bool) {
        self.name = name
        self.enabled = enabled
    }
}
