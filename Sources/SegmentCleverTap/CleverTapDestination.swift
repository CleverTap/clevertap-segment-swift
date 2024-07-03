//
//  ExampleDestination.swift
//  ExampleDestination
//
//  Created by Cody Garvin on 9/13/21.
//

// NOTE: You can see this plugin in use in the DestinationsExample application.
//
// This plugin is NOT SUPPORTED by Segment.  It is here merely as an example,
// and for your convenience should you find it useful.
//

// MIT License
//
// Copyright (c) 2021 Segment
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import Segment
import CleverTap
//import ExampleModule // TODO: Import partner SDK module here

/**
 An implementation of the Example Analytics device mode destination as a plugin.
 */
 
@objc(SEGExampleDestination)
public class ObjCSegmentMixpanel: NSObject, ObjCDestination, ObjCDestinationShim {
    public func instance() -> DestinationPlugin { return ExampleDestination() }
}

public class CleverTapDestination: DestinationPlugin {
    let libVersion = 10206
    let libName = "Segment-Swift"
    
    public let timeline = Timeline()
    public let type = PluginType.destination
    // TODO: Fill this out with your settings key that matches your destination in the Segment App
    public let key = "CleverTap"
    public var analytics: Analytics? = nil
    
    private var clevertapSettings: CleverTapSettings?
        
    public init() { }

    public func update(settings: Settings, type: UpdateType) {
        // Skip if you have a singleton and don't want to keep updating via settings.
        guard type == .initial else { return }
        
        // Grab the settings and assign them for potential later usage.
        // Note: Since integrationSettings is generic, strongly type the variable.
        guard let tempSettings: CleverTapSettings = settings.integrationSettings(forPlugin: self) else { return }
        clevertapSettings = tempSettings
        
        // TODO: initialize partner SDK here
        
        guard let accountID = clevertapSettings["clevertap_account_id"] as? String,
              !accountID.isEmpty,
              let accountToken = clevertapSettings["clevertap_account_token"] as? String,
              !accountToken.isEmpty else {
            return
        }

        var region = settings["region"] as? String ?? ""
        region = region.replacingOccurrences(of: ".", with: "")

        if Thread.isMainThread {
            self.launchWithAccountId(accountID, token: accountToken, region: region)
        } else {
            DispatchQueue.main.sync {
                self.launchWithAccountId(accountID, token: accountToken, region: region)
            }
        }
        
    }
    
    public func identify(event: IdentifyEvent) -> IdentifyEvent? {
        
        guard let traits = event.traits?.dictionaryValue else{
            // TODO: Do something with traits if they exist
            return
        }
        
        // TODO: Do something with userId & traits in partner SDK
        
       if traits.count <= 0 {
           return
       }
       
       var profile = traits
       
       if let userId = traits.userId, !userId.isEmpty {
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
       
       for key in profile.keys {
           if profile[key] is [String: Any] {
               profile.removeValue(forKey: key)
           }
       }
       
       self.onUserLogin(profile)
        
       return event
    }
    
    public func track(event: TrackEvent) -> TrackEvent? {
        
//        var returnEvent = event
//        
//        // !!!: Sample of how to convert property keys
//        if let mappedProperties = try? event.properties?.mapTransform(ExampleDestination.eventNameMap,
//                                                                      valueTransform: ExampleDestination.eventValueConversion) {
//            returnEvent.properties = mappedProperties
//        }
                
        // TODO: Do something with event & properties in partner SDK from returnEvent
        
        if event.event == "Order Completed"{
            return self.handleOrderCompleted(event)
        }
        
        self.recordEvent(event.event, withProps: event.properties)
        
        return event
    }
    
    public func screen(event: ScreenEvent) -> ScreenEvent? {
        
        guard let screenName = event.name else{
            // TODO: Do something with properties if they exist
            return
        }
                    
        // TODO: Do something with name, category & properties in partner SDK
        
        CleverTap.sharedInstance()?.recordScreenView(screenName)
        
        return event
    }
    
//    public func group(event: GroupEvent) -> GroupEvent? {
//        
//        if let _ = event.traits?.dictionaryValue {
//            // TODO: Do something with traits if they exist
//        }
//        
//        // TODO: Do something with groupId & traits in partner SDK
//        
//        return event
//    }
    
    public func alias(event: AliasEvent) -> AliasEvent? {
        
        // TODO: Do something with previousId & userId in partner SDK
        if (!event.userId || event.userId.length <= 0){
            return
        }
        
        self.profilePush(["Identity" : event.userId])
        
        return event
    }
    
    public func reset() {
        // TODO: Do something with resetting partner SDK
    }
    
    
    //Local methods
    func onUserLogin(_ profile: [String: Any]) {
        do {
            try CleverTap.sharedInstance()?.onUserLogin(profile)
        } catch let error as NSError {
            CleverTap.sharedInstance()?.recordError(withMessage: error.localizedDescription, andErrorCode: 512)
        }
    }
    
    func handleOrderCompleted(_ event: TrackEvent) {
        guard event.event == "Order Completed" else {
            return
        }
        
        var details = [String: Any]()
        var items = [Any]()
        
        let segmentProps = event.properties
        
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
        
        CleverTap.sharedInstance()?.recordChargedEvent(withDetails: details, andItems: items)
    }
    
    func recordEvent(_ event: String, withProps props: [String: Any]) {
        do {
            CleverTap.sharedInstance()?.recordEvent(event, withProps: props)
        } catch {
            CleverTap.sharedInstance()?.recordError(withMessage: error.localizedDescription, andErrorCode: 512)
        }
    }
    
    func profilePush(_ profile: [String: Any]) {
        do {
            CleverTap.sharedInstance()?.profilePush(profile)
        } catch {
            if let exception = error as? NSException {
                CleverTap.sharedInstance()?.recordError(withMessage: exception.description, andErrorCode: 512)
            }
        }
    }
    
    func launchWithAccountId(_ accountID: String, token accountToken: String, region: String) {
        CleverTap.setCredentialsWithAccountID(accountID, token: accountToken, region: region)
        CleverTap.sharedInstance()?.setLibrary(libName)
        CleverTap.sharedInstance()?.setCustomSdkVersion(libName, version: libVersion)
        CleverTap.sharedInstance()?.notifyApplicationLaunched(options: nil)
    }
    
}

// Example of versioning for your plugin
extension CleverTapDestination: VersionedPlugin {
    public static func version() -> String {
        return __destination_version
    }
}

// Example of what settings may look like.
private struct CleverTapSettings: Codable {
    let clevertap_account_id: String
    let clevertap_account_token: String?
    let region: String?
}

// Rules for converting keys and values to the proper formats that bridge
// from Segment to the Partner SDK. These are only examples.
//private extension ExampleDestination {
//    
//    static var eventNameMap = ["ADD_TO_CART": "Product Added",
//                               "PRODUCT_TAPPED": "Product Tapped"]
//    
//    static var eventValueConversion: ((_ key: String, _ value: Any) -> Any) = { (key, value) in
//        if let valueString = value as? String {
//            return valueString
//                .replacingOccurrences(of: "-", with: "_")
//                .replacingOccurrences(of: " ", with: "_")
//        } else {
//            return value
//        }
//    }
//}
