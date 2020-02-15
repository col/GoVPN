//
//  NEService.swift
//  GoVPN
//
//  Created by Colin Harris on 13/2/20.
//  Copyright © 2020 Colin Harris. All rights reserved.
//

import Foundation
import SystemConfiguration
import NetworkExtension
import XPC

let SessionStateChangedNotification = "SessionStateChangedNotification"

class VPNService {
    
    private let configuration: NEConfiguration
    private let session: ne_session_t
    
    private var gotInitialSessionStatus: Bool
    private var sessionStatus: ne_session_status_t?
    
    init(configuration: NEConfiguration) {
        self.configuration = configuration
        self.gotInitialSessionStatus = false
        
        // Get the configuration identifier to initialize the ne_session_t
        var rawUuid = configuration.identifier!.uuid
        
        // Create the ne_session
        session = withUnsafeMutablePointer(to: &rawUuid) { uuidPtr in
            uuidPtr.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<uuid_t>.size) { bytePtr in
                ne_session_create(bytePtr, NESessionTypeVPN)
            }
        }
        
        // Setup the callbacks
        self.setupEventCallback()
        self.refreshSession()
    }
    
    func name() -> String {
        return configuration.name
    }
    
    func serverAddress() -> String {
        return configuration.vpn.protocol.serverAddress ?? "unknown"
    }
    
    func serviceProtocol() -> String {
        let serviceProtocol = configuration.vpn.protocol
        let serviceProtocolClassName = String(describing: type(of: serviceProtocol))
        
        if( serviceProtocol is NEVPNProtocolIKEv2 )
        {
            return "IKEv2"
        }
        else if( serviceProtocol is NEVPNProtocolIPSec )
        {
            return "IPSec"
        }
        else if( serviceProtocolClassName == "NEVPNProtocolL2TP" )
        {
            // The NEVPNProtocolL2TP is a private class of the public NetworkExtension.framework
            return "L2TP"
        }
        
        return "Unknown"
    }
    
    func refreshSession() {
        ne_session_get_status(session, VPNServicesManager.shared.serviceQueue, { status in
            DispatchQueue.main.async {
                self.sessionStatus = status
                self.gotInitialSessionStatus = true
                // Post a notification to refresh the UI
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: SessionStateChangedNotification), object: nil)
            }
        })
    }
    
    func state() -> SCNetworkConnectionStatus {
        if( self.gotInitialSessionStatus )
        {
            return SCNetworkConnectionGetStatusFromNEStatus(self.sessionStatus!)
        }
        else
        {
            return .invalid
        }
    }
    
    func statusName() -> String {
        switch state() {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting"
        case .disconnected:
            return "Disconnected"
        case .disconnecting:
            return "Disconnecting"
        case .invalid:
            return "Invalid"
        }
    }
    
    func connect() {
        ne_session_start(session)
    }
    
    func disconnect() {
        ne_session_stop(session)
    }
    
    func setupEventCallback() {
        ne_session_set_event_handler(session, VPNServicesManager.shared.serviceQueue, { result in
            self.refreshSession()
        })
    }
    
    deinit {
        ne_session_set_event_handler(session, VPNServicesManager.shared.serviceQueue, { result in
            // Nothing
        })
        
        // Cancel and release the session
        ne_session_cancel(session);
        ne_session_release(session);
    }
}
