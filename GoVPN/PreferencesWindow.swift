//
//  PreferencesWindow.swift
//  GoVPN
//
//  Created by Colin Harris on 5/1/19.
//  Copyright © 2019 Colin Harris. All rights reserved.
//

import Cocoa

class PreferencesWindow: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
        
        NSApp.activate(ignoringOtherApps: true)
        self.window?.makeKeyAndOrderFront(self)
    }

}
 
