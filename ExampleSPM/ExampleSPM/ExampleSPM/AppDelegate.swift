//
//  AppDelegate.swift
//  ExampleSPM
//
//  Created by Aishwarya Nanna on 03/07/24.
//

import UIKit
import UserNotifications
import Segment
import SegmentCleverTap
import CleverTapSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        Analytics.debugLogsEnabled = true
        Analytics.main.add(plugin: CleverTapDestination())
        CleverTap.setDebugLevel(3)
        
        // push notifications
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .alert, .badge]) {
            (granted, error) in
            if (granted) {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Analytics.main.registeredForRemoteNotifications(deviceToken: deviceToken)
    }
}

extension Analytics {
    static var main: Analytics = {
        let analytics = Analytics(
            configuration: Configuration(writeKey: "cuSIiei29JvXHD24aM8IsDP0ACnjyC9s")
                .flushAt(3)
                .flushInterval(10)
                .setTrackedApplicationLifecycleEvents([
                    .applicationOpened,
                    .applicationInstalled
                ])
        )
        return analytics
    }()
}

