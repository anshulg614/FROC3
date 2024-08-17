//
//  notification.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 8/17/24.
//

import Foundation
import SwiftUI
import Firebase

struct NotificationItem: Identifiable {
    enum NotificationType: String {
        case comment, purchase, like, rent, `return`
    }
    var id: String
    var icon: String
    var type: NotificationType
    var username: String
    var actionText: String
    var timestamp: Date
    var productInfo: String
    var price: Double
    var size: String
    var duration: String
    var name: String
    var address: String
    var imageUrls: [String]
    var shipImageUrl: String? // Change to optional
    var buyer: User
    var expectedArrivalDate: Date?
    var expectedReturnDate: Date?
    var note: String? // New field
    var venmo: String? // New field
    var isNew: Bool // Add isNew property

    init(id: String = UUID().uuidString, icon: String, type: NotificationType, username: String, actionText: String, timestamp: Date = Date(), productInfo: String, price: Double, size: String, duration: String, name: String, address: String, imageUrls: [String], shipImageUrl: String? = nil, buyer: User, expectedArrivalDate: Date? = nil, expectedReturnDate: Date? = nil, note: String? = nil, venmo: String? = nil, isNew: Bool = true) {
        self.id = id
        self.icon = icon
        self.type = type
        self.username = username
        self.actionText = actionText
        self.timestamp = timestamp
        self.productInfo = productInfo
        self.price = price
        self.size = size
        self.duration = duration
        self.name = name
        self.address = address
        self.imageUrls = imageUrls
        self.shipImageUrl = shipImageUrl
        self.buyer = buyer
        self.expectedArrivalDate = expectedArrivalDate
        self.expectedReturnDate = expectedReturnDate
        self.note = note
        self.venmo = venmo
        self.isNew = isNew
    }
}

