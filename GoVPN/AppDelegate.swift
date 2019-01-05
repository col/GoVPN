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
            let vpnNum = Int(menuItem.keyEquivalent)!
            let payload = config.payloadContent[vpnNum-1]
            print("Selected \(payload.userDefinedName)")
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
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit GoVPN", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
}

