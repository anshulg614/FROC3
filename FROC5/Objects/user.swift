//
//  user.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 8/17/24.
//

import Foundation
import Firebase
import SwiftUI

struct User: Identifiable, Equatable {
    var id: String
    var username: String
    var email: String
    var firstName: String
    var lastName: String
    var address: String
    var profilePicture: UIImage
    var profilePictureURL: String
    var venmo: String // New field for Venmo username
    var posts: [Post]
    var followers: [String]
    var following: [String]
    var numberOfBuyRents: Int
    var notifications: [NotificationItem]
    var blockedUsers: [String] // New field for blocked users
    var fcmToken: String // New field for FCM token
    
    init(id: String = UUID().uuidString, username: String, email: String, firstName: String, lastName: String, address: String, profilePicture: UIImage = UIImage(), profilePictureURL: String = "", venmo: String = "", posts: [Post] = [], followers: [String] = [], following: [String] = [], numberOfBuyRents: Int = 0, notifications: [NotificationItem] = [], blockedUsers: [String] = [], fcmToken: String = "") {
        self.id = id
        self.username = username
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.address = address
        self.profilePicture = profilePicture
        self.profilePictureURL = profilePictureURL
        self.venmo = venmo
        self.posts = posts
        self.followers = followers
        self.following = following
        self.numberOfBuyRents = numberOfBuyRents
        self.notifications = notifications
        self.blockedUsers = blockedUsers
        self.fcmToken = fcmToken
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
}

extension User {
    func toDict() -> [String: Any] {
        return [
            "id": self.id,
            "username": self.username,
            "email": self.email,
            "firstName": self.firstName,
            "lastName": self.lastName,
            "address": self.address,
            "profilePictureURL": self.profilePictureURL,
            "followers": self.followers,
            "numberOfBuyRents": self.numberOfBuyRents
        ]
    }
}
