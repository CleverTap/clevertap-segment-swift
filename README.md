<p align="center">
  <img src="https://github.com/CleverTap/clevertap-ios-sdk/blob/master/docs/images/clevertap-logo.png" width = "50%"/>
</p>

# CleverTap Segment Swift SDK
CleverTap destination plugin for Segment Swift Analytics.

## Installation
- In Xcode, navigate to **File -> Swift Package Manager -> Add Package Dependency.**
- Enter **https://github.com/CleverTap/clevertap-segment-swift.git** when choosing package repo and Click **Next.**
- On the next screen, Select an SDK version (by default, Xcode selects the latest stable version). Click **Next.**
- Click **Finish** and ensure that the `SegmentCleverTap` has been added to the appropriate target.

## Quick Start
```swift
import Segment
import SegmentCleverTap

let analytics = Analytics(configuration: Configuration(writeKey: "YOUR_WRITE_KEY_HERE"))
analytics.add(plugin: CleverTapDestination())
```
Refer [Sample App](ExampleSPM) for more details.

## Usage
### 1. Record User Information
Segment's `identify` API is mapped to CleverTap's `onUserLogin`.
```swift
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
analytics.identify(userId: "cleverTapSegmentSwiftUseriOS", traits: traits)
```
You can also use the Segment's `alias` method for user identification:

```swift
analytics.alias(newId: "new_id")
```

### 2. Record an Event
Segment's `track` API is mapped to CleverTap's `recordEvent`.

```swift
let properties: [String: Any] = [
    "eventproperty": "eventPropertyValue",
    "testPlan": "Pro",
    "testEvArr": [1, 2, 3]
]
analytics.track(name: "testEvent", properties: properties)
```

### 3. Record a Charged Event
Events tracked using the name `Order Completed` is mapped to CleverTap’s `Charged` event.
```swift
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
analytics.track(name: "Order Completed", properties: orderProperties)
```

### 4. Record Screen
Segment's `screen` API is mapped to CleverTap's `recordScreenView`.

```swift
analytics.screen(title: "Test Screen")
```

### 5. CleverTap Specific Features
Access CleverTap-specific features through the CleverTap instance

Refer to the CleverTap SDK [documentation](https://developer.clevertap.com/docs/ios) for more details.