//
//  ScriptGenerator.swift
//  GoVPN
//
//  Created by Colin Harris on 5/1/19.
//  Copyright © 2019 Colin Harris. All rights reserved.
//

import Foundation

class ScriptGenerator {
    
    static func generateScript(name: String, variables: Dictionary<String, String>) -> String {
        let url = Bundle.main.url(forResource: name, withExtension: "scpt")!
        return generateScript(url: url, variables: variables)
    }
    
    static func generateScript(url: URL, variables: Dictionary<String, String>) -> String {
        var script = try! String(contentsOf: url, encoding: .utf8)
        
        for (key, value) in variables {
            script = script.replacingOccurrences(of: key, with: value)
        }
        
        return script
    }
    
}
