//
//  AppDelegate.swift
//  GoVPN
//
//  Created by Colin Harris on 5/1/19.
//  Copyright © 2019 Colin Harris. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    var config: Config = Config()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("StatusBarButtonImage"))
        }
        
        if let newConfig = VPNConfigParser.load(filePath: "/Users/col/.gojek.mobileconfig") {
            self.config = newConfig
        }
        
        constructMenu()
    }
    
    @objc func selectVPN(_ sender: Any?) {
        if let menuItem = sender as? NSMenuItem {
            let payload = config.payloadContent[Int(menuItem.keyEquivalent)!-1]
            print("Selected \(payload.userDefinedName)")
            
            let otp = Shell.execute(launchPath: "/usr/local/bin/mimier", arguments: ["get", "gojek"])
            let script = ScriptGenerator.generateScript(name: "ConnectVPN", variables: ["$vpn_otp": otp, "$osx_vpn_name": "\(payload.userDefinedName), Not Connected"])
            
            if let script = NSAppleScript(source: script) {
                var error: NSDictionary?
                let output: NSAppleEventDescriptor = script.executeAndReturnError(&error)
                if let error = error {
                    print("error: \(error)")
                } else {
                    print(output.stringValue ?? "unknown")
                }
            }
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func constructMenu() {
        let menu = NSMenu()
        
        if config.payloadContent.count > 0 {
            var count = 0
            for payload in config.payloadContent {
                count += 1
                menu.addItem(
                    NSMenuItem(
                        title: payload.userDefinedName.trimmingCharacters(in: .whitespacesAndNewlines),
                        action: #selector(AppDelegate.selectVPN(_:)),
                        keyEquivalent: "\(count)"
                    )
                )
            }
        } else {
            menu.addItem(NSMenuItem(title: "Invalid config", action: nil, keyEquivalent: ""))
        }
        
//        menu.addItem(NSMenuItem.separator())
//        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(NSApplication.terminate(_:)), keyEquivalent: ","))
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit GoVPN", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
 
}

