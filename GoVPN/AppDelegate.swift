//
//  AppDelegate.swift
//  GoVPN
//
//  Created by Colin Harris on 5/1/19.
//  Copyright © 2019 Colin Harris. All rights reserved.
//

import Cocoa
import os

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

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
        
        if let windowController = preferencesWindow {
            windowController.showWindow(sender)
            
            // Ensure the window becomes active and appears in front
            NSApp.activate(ignoringOtherApps: true)
            windowController.window?.makeKeyAndOrderFront(self)
        }
    }
    
    @objc func selectVPN(_ sender: Any?) {
        if let menuItem = sender as? NSMenuItem {
            if let vpn = menuItem.representedObject as? VPN {
                if let vpnService = VPNServicesManager.shared.service(named: vpn.name),
                    vpnService.state() == .connected || vpnService.state() == .connecting
                {
                    vpnService.disconnect()
                } else {
                    connectToVPN(vpnName: vpn.name)
                }                
            }
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
        os_log("connectToVPN %s", type: .info, vpnName)

        let mimierPath = "/usr/local/bin/mimier"
        if !FileManager.default.fileExists(atPath: mimierPath) {
            let alert = NSAlert.init()
            alert.messageText = "mimier not found in system"
            alert.informativeText = "Check at https://github.com/gowtham-sai/mimier"
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Open in Browser")
            let alertResp = alert.runModal()
            if alertResp.rawValue == 1001 {
                let url = URL(string: "https://github.com/gowtham-sai/mimier")!
                NSWorkspace.shared.open(url)
            }
            return
        }

        let otp = Shell.execute(launchPath: mimierPath, arguments: ["get", "gojek"])
        let otpInt = Int(otp.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0

        
        if otpInt < 10000 {
            let alert = NSAlert.init()
            alert.messageText = "mimier not configured"
            alert.informativeText = "command: /usr/local/bin/mimier get gojek \n\nresult \n\(otp)"
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }

        os_log("Otp is %d", type: .info, otpInt)

        let script = ScriptGenerator.generateScript(name: "ConnectVPN",
                                                    variables: ["$vpn_otp": String(otpInt), "$osx_vpn_name": "\(vpnName), Not Connected"])

        os_log("connected")
        
        if let script = NSAppleScript(source: script) {
            var error: NSDictionary?
            let output: NSAppleEventDescriptor = script.executeAndReturnError(&error)
            if let error = error {
                os_log("error: %@", type: .error, error)
            } else {
                os_log("ouput %s", type: .info, output.stringValue ?? "unknown")
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
        
        VPNServicesManager.shared.loadConfigurationsWithHandler { error in
            if let error = error {
                os_log("Error loading VPNServices. Error: %@", type: .error, error.localizedDescription)
            }
            self.constructMenu()
        }
    }
    
    func constructMenu() {
        let menu = NSMenu()
        
        let vpnGroups = Dictionary(grouping: self.vpns, by: { $0.group })
        let groupNames = vpnGroups.keys.sorted(by: { $0 ?? "" < $1 ?? "" })
        
        if vpns.count > 0 {
            var count = 0
            for groupName in groupNames {
                let groupVpns = vpnGroups[groupName]!
                if groupVpns.filter({ $0.enabled }).count > 0 {
                    var indent = 0
                    if let name = groupName {
                        indent = 1
                        let vpnGroupMenuItem = NSMenuItem(
                            title: name,
                            action: #selector(AppDelegate.selectVPNGroup(_:)),
                            keyEquivalent: "\(name.prefix(1))"
                        )
                        menu.addItem(vpnGroupMenuItem)
                    }
                    
                    for vpn in groupVpns {
                        if vpn.enabled {
                            count += 1
                            menu.addItem(menuItem(for: vpn, number: count, indent: indent))
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
        
        menu.delegate = self
        statusItem.menu = menu
    }
 
    func menuItem(for vpn: VPN, number: Int, indent: Int = 0) -> NSMenuItem {
        let menuItem = NSMenuItem(
            title: vpn.name,
            action: #selector(AppDelegate.selectVPN(_:)),
            keyEquivalent: "\(number)"
        )
        menuItem.indentationLevel = indent
        menuItem.representedObject = vpn
        return menuItem
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        os_log("menuWillOpen")
        for menuItem in statusItem.menu?.items ?? [] {
            if let vpn = menuItem.representedObject as? VPN {
                if let vpnService = VPNServicesManager.shared.service(named: vpn.name),
                    vpnService.state() == .connected || vpnService.state() == .connecting
                {
                    menuItem.state = .on
                } else {
                    menuItem.state = .off
                }
            }
        }
    }
}

