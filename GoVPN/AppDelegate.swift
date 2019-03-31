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
    var vpns: [VPN] = []
    var preferencesWindow: PreferencesWindow?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("StatusBarButtonImage"))
        }
        
        loadVPNConfig()
    }
    
    @objc func showPreferences(_ sender: Any?) {
        if preferencesWindow == nil {
            preferencesWindow = NSStoryboard.init(name: NSStoryboard.Name("Preferences"), bundle: nil).instantiateInitialController() as? PreferencesWindow
        }
        
        if let window = preferencesWindow {
            window.showWindow(sender)
        }
    }
    
    @objc func selectVPN(_ sender: Any?) {
        if let menuItem = sender as? NSMenuItem {
            let vpn = vpns[Int(menuItem.keyEquivalent)!-1]
            connectToVPN(vpnName: vpn.name)
        }
    }
    
    @objc func selectVPNGroup(_ sender: Any?) {
        if let menuItem = sender as? NSMenuItem {
            let vpnGroups = Dictionary(grouping: self.vpns, by: { $0.group })
            if let groupsVpns = vpnGroups[menuItem.title] {
                connectTo(groupsVpns)
            }
        }
    }
    
    func connectToVPN(vpnName: String) {
        print("connectToVPN \(vpnName)")
        
        let otp = Shell.execute(launchPath: "/usr/local/bin/mimier", arguments: ["get", "gojek"])
        let script = ScriptGenerator.generateScript(name: "ConnectVPN", variables: ["$vpn_otp": otp, "$osx_vpn_name": "\(vpnName), Not Connected"])
        
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
    
    @objc func connectAll(_ sender: Any?) {
        connectTo(vpns)
    }
    
    func connectTo(_ vpns: [VPN]) {
        for vpn in vpns {
            if vpn.enabled {
                connectToVPN(vpnName: vpn.name)
            }
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func loadVPNConfig() {
        if let filePath = UserDefaults.standard.string(forKey: "ConfigFilePath"), let vpnConfigs = VPNConfigParser.load(filePath: filePath) {
            self.vpns = []
            for vpnConfig in vpnConfigs {
                var vpn: VPN
                if let encodedData = UserDefaults.standard.data(forKey: vpnConfig.name) {
                    vpn = try! JSONDecoder().decode(VPN.self, from: encodedData)
                } else {
                    vpn = vpnConfig
                }
                self.vpns.append(vpn)
            }
        }
        
        constructMenu()
    }
    
    func constructMenu() {
        let menu = NSMenu()
        
        let vpnGroups = Dictionary(grouping: self.vpns, by: { $0.group })
        
        if vpns.count > 0 {
            var count = 0
            for (groupName, groupVpns) in vpnGroups {
                if groupVpns.filter({ $0.enabled }).count > 0 {
                    let name = groupName ?? "Unknown"
                    let vpnGroupMenuItem = NSMenuItem(
                        title: name,
                        action: #selector(AppDelegate.selectVPNGroup(_:)),
                        keyEquivalent: "\(name.prefix(1))"
                    )
//                    vpnGroupMenuItem.submenu = NSMenu()
                    menu.addItem(vpnGroupMenuItem)
                    
                    for vpn in groupVpns {
                        if vpn.enabled {
                            count += 1
                            let menuItem = NSMenuItem(
                                title: "    \(vpn.name)",
                                action: #selector(AppDelegate.selectVPN(_:)),
                                keyEquivalent: "\(count)"
                            )
//                            vpnGroupMenuItem.submenu?.addItem(menuItem)
                            menu.addItem(menuItem)
                        }
                    }
                    menu.addItem(NSMenuItem.separator())
                }
            }
        } else {
            menu.addItem(NSMenuItem(title: "Invalid config", action: nil, keyEquivalent: ""))
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Connect all", action: #selector(AppDelegate.connectAll(_:)), keyEquivalent: "A"))
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(AppDelegate.showPreferences(_:)), keyEquivalent: ","))
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit GoVPN", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
 
}

