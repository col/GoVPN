//
//  PreferencesViewController.swift
//  GoVPN
//
//  Created by Colin Harris on 5/1/19.
//  Copyright © 2019 Colin Harris. All rights reserved.
//

import Cocoa

class PreferencesViewController: NSViewController {

    @IBOutlet var configFileTextField: NSTextField!
    @IBOutlet var versionLabel: NSTextField!
    @IBOutlet var availableVPNsAC: NSArrayController!
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        if let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String,
            let buildNumber = Bundle.main.infoDictionary!["CFBundleVersion"] as? String {
            versionLabel.stringValue = "v\(appVersion) (\(buildNumber))"
        }
            
        configFileTextField.stringValue = UserDefaults.standard.string(forKey: "ConfigFilePath") ?? ""
        
        availableVPNsAC.content = nil
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            for vpn in appDelegate.vpns {
                availableVPNsAC.addObject(vpn)
            }
        }
    }
    
    @IBAction func chooseConfigFile(_ sender: Any) {
        let chooseFilePanel = NSOpenPanel()
        chooseFilePanel.canChooseFiles = true
        chooseFilePanel.canChooseDirectories = false
        chooseFilePanel.canCreateDirectories = false
        chooseFilePanel.allowsMultipleSelection = false
        chooseFilePanel.begin { (result) -> Void in
            if result == NSApplication.ModalResponse.OK {
                if let url = chooseFilePanel.url {
                    let filePath = url.relativePath
                    UserDefaults.standard.set(filePath, forKey: "ConfigFilePath")
                    self.configFileTextField.stringValue = filePath
                }
            }
        }
        reloadVPNConfig()
    }
    
    @IBAction func cancel(_ sender: Any) {
        reloadVPNConfig()
        self.view.window?.windowController?.close()
    }
    
    @IBAction func save(_ sender: Any) {
        for vpn in availableVPNsAC!.arrangedObjects as! [VPN] {
            UserDefaults.standard.set(vpn.enabled, forKey: vpn.name)
        }
        reloadVPNConfig()
        self.view.window?.windowController?.close()
    }
    
    func reloadVPNConfig() {
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.loadVPNConfig()
        }
    }
}
