//
//  VPNConfigParser.swift
//  GoVPN
//
//  Created by Colin Harris on 5/1/19.
//  Copyright © 2019 Colin Harris. All rights reserved.
//

import Foundation
import AppKit

class VPNConfigManager {
    
    static let userDefaults = UserDefaults(suiteName: "com.colharris.GoVPN")
    
    static func load() -> [VPN]? {
        return userDefaults?.array(forKey: "vpns") as? [VPN]
    }
    
    static func save(vpns: [VPN]) {
        userDefaults?.set(vpns, forKey: "vpns")
    }
    
}
