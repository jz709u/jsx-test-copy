//
//  ChannelManager.swift
//  Runner
//
//  Created by Jay Zisch on 2026/04/21.
//
import Flutter

enum FlutterChannelName: String {
    case navigation
    case spotlight
    case live_activity
    case home_widget
    case home_widget_update
    
    var name: String { "jsx.app/\(self.rawValue)" }
}

actor FlutterChannelManager {
    
    private let navChannel: NavigationFlutterChannel
    
    init(binaryMessager: any FlutterBinaryMessenger,
         channel: FlutterMethodChannel) {
        self.navChannel = .init(messenger: binaryMessager)
    }
}

class NavigationFlutterChannel {

    private let channel: FlutterMethodChannel
    private let name: FlutterChannelName = .navigation
    
    init(messenger: any FlutterBinaryMessenger,
         userDefaults: UserDefaults = .jsxAppGroup) {
        channel = .init(name: name.rawValue,
                        binaryMessenger: messenger)
        
        channel.listenMethod { method, result in
            switch method {
            case .getPendingRoute:
                let _route = userDefaults.route
                userDefaults.route = nil
                result(_route)
            }
        }
    }
}

extension UserDefaults {
    var route: String? {
        get { string(forKey: "jsx_pending_route") }
        set { setValue(newValue, forKey: "jsx_pending_route") }
    }
}

extension FlutterMethodChannel {
    enum Method: String {
        case getPendingRoute
    }
    func listenMethod(_ listener: @escaping (Method, FlutterResult) -> Void ) {
        self.setMethodCallHandler { call, result in
            guard let method = Method(rawValue: call.method) else {
                result(FlutterMethodNotImplemented)
                return
            }
            listener(method, result)
        }
    }
}


