//
//  ViewController.swift
//  ExampleSPM
//
//  Created by Aishwarya Nanna on 03/07/24.
//

import UIKit
import Segment
import SegmentCleverTap
import CleverTapSDK

class ViewController: UIViewController, CleverTapInboxViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        registerAppInbox()
        initializeAppInbox()
    }

    @IBAction func identifyButton(_ sender: Any) {
        let floatAttribute = 12.3
        let integerAttribute: Int = 18
        let shortAttribute: Int16 = 2
        let birthdate: Date = Date(timeIntervalSince1970: 946684800) // 1 Jan 2000
        let traits: [String: Any] = [
            "email": "support@clevertap.com",
            "bool": true,
            "double": 3.14159,
            "stringInt": "1",
            "integerAttribute": integerAttribute,
            "floatAttribute": floatAttribute,
            "shortAttribute": shortAttribute,
            "gender": "female",
            "name": "Segment CleverTap",
            "phone": "+15555555556",
            "birthday": birthdate,
            "testArr": ["1", "2", "3"],
            "address": [
                "city": "New York",
                "country": "US"
            ]
        ]
        
        Analytics.main.identify(userId: "cleverTapSegmentSwiftUseriOS", traits: traits)
    }
    
    @IBAction func trackButton(_ sender: Any) {
        let properties: [String: Any] = [
            "eventproperty": "eventPropertyValue",
            "testPlan": "Pro",
            "testEvArr": [1, 2, 3]
        ]
        Analytics.main.track(name: "testEvent", properties: properties)
        
        let orderProperties: [String: Any] = [
            "checkout_id": "fksdjfsdjfisjf9sdfjsd9f",
            "order_id": "50314b8e9bcf000000000000",
            "affiliation": "Google Store",
            "total": 30,
            "revenue": 25,
            "currency": "USD",
            "products": [
                [
                    "product_id": "507f1f77bcf86cd799439011",
                    "sku": "45790-32",
                    "name": "Monopoly: 3rd Edition",
                    "price": 19,
                    "quantity": 1,
                    "category": "Games"
                ],
                [
                    "product_id": "505bd76785ebb509fc183733",
                    "sku": "46493-32",
                    "name": "Uno Card Game",
                    "price": 3,
                    "quantity": 2,
                    "category": "Games"
                ]
            ]
        ]
        Analytics.main.track(name: "Order Completed", properties: orderProperties)
    }
    
    @IBAction func aliasButton(_ sender: Any) {
        Analytics.main.alias(newId: "1144334")
    }
    
    @IBAction func screenButton(_ sender: Any) {
        Analytics.main.screen(title: "Test Screen")
    }
    
    @IBAction func showAppInbox(_ sender: Any) {
        let style = CleverTapInboxStyleConfig.init()
        style.title = "App Inbox"
        style.navigationTintColor = .black
        
        if let inboxController = CleverTap.sharedInstance()?.newInboxViewController(with: style, andDelegate: self) {
            let navigationController = UINavigationController.init(rootViewController: inboxController)
            self.present(navigationController, animated: true, completion: nil)
        }
    }
    
    private func registerAppInbox() {
        CleverTap.sharedInstance()?.registerInboxUpdatedBlock({
            let messageCount = CleverTap.sharedInstance()?.getInboxMessageCount()
            let unreadCount = CleverTap.sharedInstance()?.getInboxMessageUnreadCount()
            print("Inbox Message:\(String(describing: messageCount))/\(String(describing: unreadCount)) unread")
        })
    }
    
    private func initializeAppInbox() {
        CleverTap.sharedInstance()?.initializeInbox(callback: ({ (success) in
            let messageCount = CleverTap.sharedInstance()?.getInboxMessageCount()
            let unreadCount = CleverTap.sharedInstance()?.getInboxMessageUnreadCount()
            print("Inbox Message:\(String(describing: messageCount))/\(String(describing: unreadCount)) unread")
        }))
    }
    
}

