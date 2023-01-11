//
//  TpcWaterDispenserMapApp.swift
//  TpcWaterDispenserMap
//
//  Created by Riddle Ling on 2023/1/10.
//

import SwiftUI

@main
struct TpcWaterDispenserMapApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        LocationProvider.shared.start()
        return true
    }
}
