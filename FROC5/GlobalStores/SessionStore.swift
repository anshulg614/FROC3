//
//  SessionStore.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 8/17/24.
//

import Foundation
import PhotosUI
import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class SessionStore: ObservableObject {
    @Published var isSignedIn: Bool = false
    @Published var currentUser: User?
    @Published var isGuestMode: Bool = false // Add this property
    @ObservedObject var userStore: UserStore
    @Published var newNotificationCount: Int = 0 // Add this line
    
    private var db = Firestore.firestore()
    private var storageRef = Storage.storage().reference()
    private var notificationManager = NotificationManager()
    
    init(userStore: UserStore) {
        self.userStore = userStore
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.isSignedIn = true
                self?.fetchUserInfo(userId: user.uid)
            } else {
                self?.isSignedIn = false
                self?.currentUser = nil
            }
        }
    }
    
    func signInAsGuest() {
        self.isSignedIn = true
        self.isGuestMode = true
        self.currentUser = User(id: "guest", username: "Guest", email: "", firstName: "Guest", lastName: "", address: "", profilePictureURL: "", venmo: "", followers: [], following: [], numberOfBuyRents: 0, notifications: [], blockedUsers: [])
    }

    func fetchUserInfo(userId: String) {
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists, let data = document.data() {
                let profilePictureURL = data["profilePictureURL"] as? String ?? ""
                let followers = data["followers"] as? [String] ?? []
                let following = data["following"] as? [String] ?? []
                let venmo = data["venmo"] as? String ?? "" // Fetch Venmo username
                let notificationsData = data["notifications"] as? [[String: Any]] ?? []
                let blockedUsers = data["blockedUsers"] as? [String] ?? [] // Fetch blockedUsers
                let fcmToken = data["fcmToken"] as? String ?? "" // Fetch FCM token
                
                let notifications = notificationsData.compactMap { dict -> NotificationItem? in
                    guard let typeString = dict["type"] as? String,
                          let type = NotificationItem.NotificationType(rawValue: typeString),
                          let username = dict["username"] as? String,
                          let actionText = dict["actionText"] as? String,
                          let timestampString = dict["timestamp"] as? String,
                          let productInfo = dict["productInfo"] as? String,
                          let price = dict["price"] as? Double,
                          let size = dict["size"] as? String,
                          let duration = dict["duration"] as? String,
                          let name = dict["name"] as? String,
                          let address = dict["address"] as? String,
                          let imageUrls = dict["imageUrls"] as? [String],
                          let shipImageUrl = dict["shipImageUrl"] as? String,
                          let icon = dict["icon"] as? String,
                          let isNew = dict["isNew"] as? Bool,
                          let buyerData = dict["buyer"] as? [String: Any] else {
                        return nil
                    }
                    let dateFormatter = ISO8601DateFormatter()
                    guard let timestamp = dateFormatter.date(from: timestampString) else {
                        return nil
                    }
                    let buyer = User(
                        id: buyerData["id"] as? String ?? "",
                        username: buyerData["username"] as? String ?? "",
                        email: buyerData["email"] as? String ?? "",
                        firstName: buyerData["firstName"] as? String ?? "",
                        lastName: buyerData["lastName"] as? String ?? "",
                        address: buyerData["address"] as? String ?? "",
                        profilePictureURL: buyerData["profilePictureURL"] as? String ?? "",
                        followers: buyerData["followers"] as? [String] ?? [],
                        numberOfBuyRents: buyerData["numberOfBuyRents"] as? Int ?? 0
                    )
                    let note = dict["note"] as? String
                    let venmo = dict["venmo"] as? String
                    return NotificationItem(
                        id: UUID().uuidString,
                        icon: icon,
                        type: type,
                        username: username,
                        actionText: actionText,
                        timestamp: timestamp,
                        productInfo: productInfo,
                        price: price,
                        size: size,
                        duration: duration,
                        name: name,
                        address: address,
                        imageUrls: imageUrls,
                        shipImageUrl: shipImageUrl,
                        buyer: buyer,
                        note: note,
                        venmo: venmo,
                        isNew: isNew
                    )
                }
                
                self.currentUser = User(
                    id: document.documentID,
                    username: data["username"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    firstName: data["firstName"] as? String ?? "",
                    lastName: data["lastName"] as? String ?? "",
                    address: data["address"] as? String ?? "",
                    profilePictureURL: profilePictureURL,
                    venmo: venmo, // Set Venmo username
                    followers: followers,
                    following: following,
                    numberOfBuyRents: data["numberOfBuyRents"] as? Int ?? 0,
                    notifications: notifications,
                    blockedUsers: blockedUsers, // Set blockedUsers
                    fcmToken: fcmToken // Set FCM token
                )
                self.fetchProfileImage(profilePictureURL: profilePictureURL)
                self.fetchNotifications(userId: userId)
            } else {
                print("Document does not exist")
            }
        }
    }

    func fetchNotifications(userId: String) {
        db.collection("users").document(userId).collection("notifications").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching notifications: \(error.localizedDescription)")
            } else {
                guard let documents = snapshot?.documents else {
                    print("No notification documents found")
                    return
                }
                print("Fetched \(documents.count) notification documents")
                let notifications = documents.compactMap { document -> NotificationItem? in
                    let data = document.data()
                    
                    print("Notification document data: \(data)")
                    let typeString = data["type"] as? String ?? "unknown"
                    let type = NotificationItem.NotificationType(rawValue: typeString) ?? .comment
                    let username = data["username"] as? String ?? "Unknown User"
                    let actionText = data["actionText"] as? String ?? "Unknown Action"
                    let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    let productInfo = data["productInfo"] as? String ?? "Unknown Product"
                    let price = data["price"] as? Double ?? 0.0
                    let size = data["size"] as? String ?? "Unknown Size"
                    let duration = data["duration"] as? String ?? "Unknown Duration"
                    let name = data["name"] as? String ?? "Unknown Name"
                    let address = data["address"] as? String ?? "Unknown Address"
                    let imageUrls = data["imageUrls"] as? [String] ?? ["Unknown URL"]
                    let shipImageUrl = data["shipImageUrl"] as? String ?? ""
                    let icon = data["icon"] as? String ?? "default_icon"
                    let expectedArrivalDate = (data["expectedArrivalDate"] as? Timestamp)?.dateValue()
                    let expectedReturnDate = (data["expectedReturnDate"] as? Timestamp)?.dateValue()
                    let note = data["note"] as? String ?? ""
                    let venmo = data["venmo"] as? String ?? ""
                    let isNew = data["isNew"] as? Bool ?? true
                    let buyerData = data["buyer"] as? [String: Any] ?? [:]
                    let buyer = User(
                        id: buyerData["id"] as? String ?? "Unknown Buyer ID",
                        username: buyerData["username"] as? String ?? "Unknown Buyer Username",
                        email: buyerData["email"] as? String ?? "Unknown Buyer Email",
                        firstName: buyerData["firstName"] as? String ?? "Unknown Buyer First Name",
                        lastName: buyerData["lastName"] as? String ?? "Unknown Buyer Last Name",
                        address: buyerData["address"] as? String ?? "Unknown Buyer Address",
                        profilePictureURL: buyerData["profilePictureURL"] as? String ?? "Unknown Buyer Profile URL",
                        followers: buyerData["followers"] as? [String] ?? [],
                        numberOfBuyRents: buyerData["numberOfBuyRents"] as? Int ?? 0
                    )
                    print("Parsed NotificationItem successfully")
                    return NotificationItem(
                        id: document.documentID,
                        icon: icon,
                        type: type,
                        username: username,
                        actionText: actionText,
                        timestamp: timestamp,
                        productInfo: productInfo,
                        price: price,
                        size: size,
                        duration: duration,
                        name: name,
                        address: address,
                        imageUrls: imageUrls,
                        shipImageUrl: shipImageUrl,
                        buyer: buyer,
                        expectedArrivalDate: expectedArrivalDate,
                        expectedReturnDate: expectedReturnDate,
                        note: note,
                        venmo: venmo,
                        isNew: isNew
                    )
                }
                print("Parsed notifications: \(notifications)")
                DispatchQueue.main.async {
                    self.currentUser?.notifications = notifications
                    self.newNotificationCount = notifications.filter { $0.isNew }.count // Update the count of new notifications
                    print("Notifications updated")
                }
            }
        }
    }

    func resetNewNotificationCount() {
        guard let userId = currentUser?.id else { return }
        let notificationsRef = db.collection("users").document(userId).collection("notifications")
        notificationsRef.getDocuments { [weak self] snapshot, error in
            guard let self = self else { return } // Capture self explicitly
            if let error = error {
                print("Error resetting notification count: \(error.localizedDescription)")
            } else {
                guard let documents = snapshot?.documents else { return }
                let batch = self.db.batch() // Use self.db here
                documents.forEach { document in
                    batch.updateData(["isNew": false], forDocument: document.reference)
                }
                batch.commit { error in
                    if let error = error {
                        print("Error committing batch update: \(error.localizedDescription)")
                    } else {
                        print("New notification count reset")
                        DispatchQueue.main.async {
                            self.newNotificationCount = 0
                        }
                    }
                }
            }
        }
    }

    func saveUserFCMToken(userId: String, fcmToken: String) {
        db.collection("users").document(userId).updateData(["fcmToken": fcmToken]) { error in
            if let error = error {
                print("Error updating FCM token: \(error.localizedDescription)")
            } else {
                print("FCM token updated successfully")
            }
        }
    }

    func sendNotificationToAdmin(flaggedUserId: String, flagReason: String, completion: @escaping (Bool) -> Void) {
        print("Sending notification to admin for flagging...")
        let adminId = "fhA46cyXc0M9loGVJuuBnkR8odx1" // Admin user ID
        guard let currentUser = self.currentUser else {
            print("Current user is not available.")
            completion(false)
            return
        }
        
        let notificationData: [String: Any] = [
            "type": "flag",
            "username": currentUser.username,
            "actionText": "Flagged \(flaggedUserId) \(flagReason)",
            "timestamp": FieldValue.serverTimestamp(),
            "productInfo": "Flagged User ID: \(flaggedUserId)",
            "price": 0.0,
            "size": "",
            "duration": "",
            "name": currentUser.firstName + " " + currentUser.lastName,
            "address": currentUser.address,
            "imageUrls": [],
            "shipImageUrl": "",
            "icon": "flag",
            "buyer": [
                "id": currentUser.id,
                "username": currentUser.username,
                "email": currentUser.email,
                "firstName": currentUser.firstName,
                "lastName": currentUser.lastName,
                "address": currentUser.address,
                "profilePictureURL": currentUser.profilePictureURL,
                "followers": currentUser.followers,
                "numberOfBuyRents": currentUser.numberOfBuyRents
            ]
        ]
        
        db.collection("users").document(adminId).collection("notifications").addDocument(data: notificationData) { error in
            if let error = error {
                print("Error adding notification: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Notification sent to admin.")
                completion(true)
            }
        }
    }
    
    func blockUser(blockedUserId: String, completion: @escaping (Bool) -> Void) {
        guard var currentUser = currentUser else { return }
        
        if !currentUser.blockedUsers.contains(blockedUserId) {
            currentUser.blockedUsers.append(blockedUserId)
            db.collection("users").document(currentUser.id).updateData(["blockedUsers": currentUser.blockedUsers]) { error in
                if let error = error {
                    print("Error blocking user: \(error.localizedDescription)")
                    completion(false)
                } else {
                    self.currentUser = currentUser
                    completion(true)
                }
            }
        } else {
            completion(false)
        }
    }
    
    func fetchProfileImage(profilePictureURL: String) {
        guard !profilePictureURL.isEmpty else { return }
        let imageRef = storageRef.child(profilePictureURL)
        imageRef.getData(maxSize: Int64(1 * 1024 * 1024)) { data, error in
            if let error = error {
                print("Error fetching profile image: \(error.localizedDescription)")
            } else if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.currentUser?.profilePicture = image
                }
            }
        }
    }
    
    func sendPushNotification(to userId: String, message: String) {
        notificationManager.sendPushNotification(to: userId, message: message)
    }
    
    func deleteNotification(notificationId: String, completion: @escaping (Bool) -> Void) {
        guard let currentUserId = currentUser?.id else {
            completion(false)
            return
        }
        
        let notificationRef = db.collection("users").document(currentUserId).collection("notifications").document(notificationId)
        notificationRef.delete { error in
            if let error = error {
                print("Error deleting notification: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Notification deleted")
                completion(true)
            }
        }
    }
    
    func toggleFollow(user: User, completion: @escaping (Bool) -> Void) {
        guard let currentUser = currentUser else { return }
        userStore.toggleFollow(currentUser: currentUser, user: user) { success in
            if success {
                self.currentUser = currentUser
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    
    
    func deleteAccount(completion: @escaping (Bool) -> Void) {
        guard let currentUser = currentUser else {
            completion(false)
            return
        }

        let userId = currentUser.id

        // Delete user document
        db.collection("users").document(userId).delete { error in
            if let error = error {
                print("Error deleting user document: \(error.localizedDescription)")
                completion(false)
            } else {
                // Delete user from authentication
                Auth.auth().currentUser?.delete { error in
                    if let error = error {
                        print("Error deleting user from authentication: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        // Clear local session
                        self.isSignedIn = false
                        self.currentUser = nil
                        completion(true)
                    }
                }
            }
        }
    }
    
    func signOut() {
        if isGuestMode {
            isSignedIn = false
            isGuestMode = false
            currentUser = nil
        } else {
            do {
                try Auth.auth().signOut()
                isSignedIn = false
                currentUser = nil
            } catch {
                print("Error signing out: \(error.localizedDescription)")
            }
        }
    }
}
