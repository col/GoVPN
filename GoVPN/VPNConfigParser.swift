//
//  VPNConfigParser.swift
//  GoVPN
//
//  Created by Colin Harris on 5/1/19.
//  Copyright © 2019 Colin Harris. All rights reserved.
//

import Foundation

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
    
    private enum CodingKeys: String, CodingKey {
        case userDefinedName = "UserDefinedName"
    }
}

class VPNConfigParser {
    
    static func load(filePath: String) -> Config? {
        do {
            let content = try String(contentsOf: URL(fileURLWithPath: filePath), encoding: String.Encoding.ascii)
            
            if let prefixRange = content.range(of: "<!DOCTYPE"), let suffixRange = content.range(of: "</plist>") {
                let plistContent = content[prefixRange.lowerBound..<suffixRange.upperBound]                
                let data = plistContent.data(using: .utf8)!
                
                let decoder = PropertyListDecoder()
                return try! decoder.decode(Config.self, from: data)
            } else {
                print("VPNConfigParser - Error: Not a valid config file")
                return nil
            }
        } catch {
            print("VPNConfigParser - Error: \(error)")
            return nil
        }
    }
    
}
