
//
//  VPN.swift
//  GoVPN
//
//  Created by Colin Harris on 7/1/19.
//  Copyright © 2019 Colin Harris. All rights reserved.
//

import Foundation

@objc
class VPN: NSObject, Codable {
    @objc var name: String
    @objc var enabled: Bool
    @objc var group: String?
    
    init(name: String, enabled: Bool, group: String? = nil) {
        self.name = name
        self.enabled = enabled
        self.group = group
    }
}
