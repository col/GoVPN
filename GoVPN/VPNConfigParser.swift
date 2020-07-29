//
//  VPNConfigParser.swift
//  GoVPN
//
//  Created by Colin Harris on 5/1/19.
//  Copyright © 2019 Colin Harris. All rights reserved.
//

import Foundation
import os.log

struct Config: Decodable {
    let payloadContent: [Payload]
    
    init() {
        self.payloadContent = []
    }
    
    private enum CodingKeys: String, CodingKey {
        case payloadContent = "PayloadContent"
    }
}

struct Payload: Decodable {
    let userDefinedName: String
    
    func name() -> String {
        return userDefinedName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func selected() -> Bool {
        return true
    }
    
    private enum CodingKeys: String, CodingKey {
        case userDefinedName = "UserDefinedName"
    }
}

class VPNConfigParser {
    
    static func load(filePath: String) -> [VPN]? {
        do {
            let content = try String(contentsOf: URL(fileURLWithPath: filePath), encoding: String.Encoding.ascii)
            
            if let prefixRange = content.range(of: "<!DOCTYPE"), let suffixRange = content.range(of: "</plist>") {
                let plistContent = content[prefixRange.lowerBound..<suffixRange.upperBound]                
                let data = plistContent.data(using: .utf8)!
                
                let decoder = PropertyListDecoder()
                let config = try! decoder.decode(Config.self, from: data)
                
                return config.payloadContent.map { payload in
                    VPN(name: payload.name(), enabled: payload.selected())
                }.filter { vpn in
                    vpn.enabled
                }
            } else {
                os_log("VPNConfigParser - Error: Not a valid config file", type: .error)
                return nil
            }
        } catch {
            os_log("VPNConfigParser - Error: %s", type: .error, error.localizedDescription)
            return nil
        }
    }
    
}
