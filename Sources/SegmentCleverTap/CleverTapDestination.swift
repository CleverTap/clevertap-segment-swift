//
//  CleverTapDestination.swift
//  SegmentCleverTap
//
//  Created by Nishant Kumar on 04/09/25.
//

import Foundation
import Segment
import CleverTapSDK

public class CleverTapDestination: DestinationPlugin, RemoteNotifications {
    let libVersion: Int32 = 10000
    let libName = "Segment-Swift"
    
    public let timeline = Timeline()
    public let type = PluginType.destination
    public let key = "CleverTap"
    public var analytics: Analytics? = nil
        
    public init() { }

    public func update(settings: Settings, type: UpdateType) {
        // Skip if you have a singleton and don't want to keep updating via settings.
        guard type == .initial else { return }
        
        // Grab the settings and assign them for potential later usage.
        // Note: Since integrationSettings is generic, strongly type the variable.
        guard let clevertapSettings: CleverTapSettings = settings.integrationSettings(forPlugin: self) else {
            log("CleverTapSettings not available. Not loading CleverTap Destination.")
            return
        }
        
        guard let accountID = clevertapSettings.clevertap_account_id as? String,
              !accountID.isEmpty,
              let accountToken = clevertapSettings.clevertap_account_token as? String,
              !accountToken.isEmpty else {
            log("CleverTap+Segment integration attempted initialization without account ID or account token.")
            return
        }

        var region = clevertapSettings.region as? String ?? ""
        region = region.replacingOccurrences(of: ".", with: "")

        if Thread.isMainThread {
            self.launchWithAccountId(accountID, token: accountToken, region: region)
        } else {
            DispatchQueue.main.sync {
                self.launchWithAccountId(accountID, token: accountToken, region: region)
            }
        }
        log("Configured CleverTap+Segment integration and initialized CleverTap.")
    }
    
    public func identify(event: IdentifyEvent) -> IdentifyEvent? {
        guard let traits = event.traits?.dictionaryValue else {
            log("Identify: Traits is nil.")
            return nil
        }
        
       if traits.count <= 0 {
           log("Identify: Traits doesn't have values.")
           return nil
       }
       
       var profile = traits
       
       if let userId = event.userId, !userId.isEmpty {
           profile["Identity"] = userId
       }
       
       if let email = profile["email"] as? String {
           profile["Email"] = email
       }
       
       if let name = profile["name"] as? String {
           profile["Name"] = name
       }
       
       if let phone = profile["phone"] {
           let phoneString = "\(phone)"
           profile["phone"] = phoneString
           profile["Phone"] = phoneString
       }
       
       if let gender = traits["gender"] as? String {
           let lowercasedGender = gender.lowercased()
           if lowercasedGender == "m" || lowercasedGender == "male" {
               profile["Gender"] = "M"
           } else if lowercasedGender == "f" || lowercasedGender == "female" {
               profile["Gender"] = "F"
           }
       }
       
       if let birthdayString = traits["birthday"] as? String {
           let dateFormatter = DateFormatter()
           let enUSPOSIXLocale = Locale(identifier: "en_US_POSIX")
           dateFormatter.locale = enUSPOSIXLocale
           dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
           if let date = dateFormatter.date(from: birthdayString) {
               profile["DOB"] = date
           }
       } else if let birthdayDate = traits["birthday"] as? Date {
           profile["DOB"] = birthdayDate
       }
        
       let nestedKeys = profile.keys.filter { profile[$0] is [String: Any] }
       nestedKeys.forEach { profile.removeValue(forKey: $0) }
       
       self.onUserLogin(profile)
       return event
    }
    
    public func track(event: TrackEvent) -> TrackEvent? {
        if event.event == "Order Completed"{
            self.handleOrderCompleted(event)
        } else {
            self.recordEvent(event.event, withProps: event.properties?.dictionaryValue ?? [:])
        }
        return event
    }
    
    public func screen(event: ScreenEvent) -> ScreenEvent? {
        guard let screenName = event.name else {
            log("Screen: Event name is empty.")
            return nil
        }
        
        CleverTap.sharedInstance()?.recordScreenView(screenName)
        return event
    }
    
    public func alias(event: AliasEvent) -> AliasEvent? {
        guard let userId = event.userId, !userId.isEmpty else {
            log("Alias: UserId is nil or empty.")
            return nil
        }
        
        self.profilePush(["Identity" : userId])
        return event
    }
    
    public func reset() {
        // TODO: Do something with resetting partner SDK
    }
    
    public func registeredForRemoteNotifications(deviceToken: Data) {
        CleverTap.sharedInstance()?.setPushToken(deviceToken)
    }
    
    public func receivedRemoteNotification(userInfo: [AnyHashable: Any]) {
        CleverTap.sharedInstance()?.handleNotification(withData: userInfo)
    }
    
    public func handleAction(identifier: String, userInfo: [String: Any]) {
        CleverTap.sharedInstance()?.handleNotification(withData: userInfo)
    }
    
    private func onUserLogin(_ profile: [String: Any]) {
        do {
            try CleverTap.sharedInstance()?.onUserLogin(profile)
        } catch let error as NSError {
            log("Identify: Error pushing profile \(error.localizedDescription).")
            CleverTap.sharedInstance()?.recordError(withMessage: error.localizedDescription, andErrorCode: 512)
        }
    }
    
    private func handleOrderCompleted(_ event: TrackEvent) {
        guard event.event == "Order Completed" else {
            return
        }
        
        var details = [String: Any]()
        var items = [Any]()
        
        if let segmentProps = event.properties?.dictionaryValue {
            for (key, value) in segmentProps {
                if key == "products", let value = value as? [Any], !value.isEmpty {
                    items = value
                } else if value is [String: Any] || value is [Any] {
                    continue
                } else if key == "order_id" {
                    details["Charged ID"] = value
                    details[key] = value
                } else if key == "total" {
                    details["Amount"] = value
                    details[key] = value
                } else {
                    details[key] = value
                }
            }
        }
        
        CleverTap.sharedInstance()?.recordChargedEvent(withDetails: details, andItems: items)
    }
    
    private func recordEvent(_ event: String, withProps props: [String: Any]) {
        do {
            CleverTap.sharedInstance()?.recordEvent(event, withProps: props)
        } catch {
            CleverTap.sharedInstance()?.recordError(withMessage: error.localizedDescription, andErrorCode: 512)
        }
    }
    
    private func profilePush(_ profile: [String: Any]) {
        do {
            CleverTap.sharedInstance()?.profilePush(profile)
        } catch {
            if let exception = error as? NSException {
                log("Alias: Error pushing profile \(error.localizedDescription).")
                CleverTap.sharedInstance()?.recordError(withMessage: exception.description, andErrorCode: 512)
            }
        }
    }
    
    private func launchWithAccountId(_ accountID: String, token accountToken: String, region: String) {
        CleverTap.setCredentialsWithAccountID(accountID, token: accountToken, region: region)
        CleverTap.sharedInstance()?.setLibrary(libName)
        CleverTap.sharedInstance()?.setCustomSdkVersion(libName, version: libVersion)
        CleverTap.sharedInstance()?.notifyApplicationLaunched(withOptions: nil)
    }

    private func log(_ message: String) {
        analytics?.log(message: "[CleverTapSegmentSwift]: \(message)")
    }
}

extension CleverTapDestination: VersionedPlugin {
    public static func version() -> String {
        return __destination_version
    }
}

private struct CleverTapSettings: Codable {
    let clevertap_account_id: String?
    let clevertap_account_token: String?
    let region: String?
}
