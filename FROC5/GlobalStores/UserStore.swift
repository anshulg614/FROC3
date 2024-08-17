//
//  UserStore.swift
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

class UserStore: ObservableObject {
    @Published var users: [User] = []

    private var db = Firestore.firestore()
    private var storageRef = Storage.storage().reference()
    private var notificationManager = NotificationManager()

    init() {
        fetchUsers()
    }
    
    func fetchUsers() {
        db.collection("users").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching users: \(error.localizedDescription)")
            } else {
                self.users = snapshot?.documents.compactMap { document -> User? in
                    let data = document.data()
                    let notificationsData = data["notifications"] as? [[String: Any]] ?? []
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
                        guard let timestamp = dateFormatter.date(from: timestampString),
                              let buyerId = buyerData["id"] as? String,
                              let buyerUsername = buyerData["username"] as? String,
                              let buyerEmail = buyerData["email"] as? String,
                              let buyerFirstName = buyerData["firstName"] as? String,
                              let buyerLastName = buyerData["lastName"] as? String,
                              let buyerAddress = buyerData["address"] as? String,
                              let buyerProfilePictureURL = buyerData["profilePictureURL"] as? String,
                              let buyerFollowers = buyerData["followers"] as? [String],
                              let buyerNumberOfBuyRents = buyerData["numberOfBuyRents"] as? Int else {
                            return nil
                        }

                        let buyer = User(
                            id: buyerId,
                            username: buyerUsername,
                            email: buyerEmail,
                            firstName: buyerFirstName,
                            lastName: buyerLastName,
                            address: buyerAddress,
                            profilePictureURL: buyerProfilePictureURL,
                            followers: buyerFollowers,
                            numberOfBuyRents: buyerNumberOfBuyRents
                        )

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
                            isNew: isNew
                        )
                    }
                    return User(
                        id: document.documentID,
                        username: data["username"] as? String ?? "",
                        email: data["email"] as? String ?? "",
                        firstName: data["firstName"] as? String ?? "",
                        lastName: data["lastName"] as? String ?? "",
                        address: data["address"] as? String ?? "",
                        profilePictureURL: data["profilePictureURL"] as? String ?? "",
                        venmo: data["venmo"] as? String ?? "", // Add venmo field here
                        followers: data["followers"] as? [String] ?? [],
                        following: data["following"] as? [String] ?? [],
                        numberOfBuyRents: data["numberOfBuyRents"] as? Int ?? 0,
                        notifications: notifications,
                        blockedUsers: data["blockedUsers"] as? [String] ?? [], // Add blockedUsers field here
                        fcmToken: data["fcmToken"] as? String ?? "" // Add fcmToken field here
                    )
                } ?? []
            }
        }
    }

    func updateUser(_ user: User, completion: @escaping (Error?) -> Void) {
        let notificationsData = user.notifications.map { notification -> [String: Any] in
            let buyerData: [String: Any] = [
                "id": notification.buyer.id,
                "username": notification.buyer.username,
                "email": notification.buyer.email,
                "firstName": notification.buyer.firstName,
                "lastName": notification.buyer.lastName,
                "address": notification.buyer.address,
                "profilePictureURL": notification.buyer.profilePictureURL,
                "followers": notification.buyer.followers,
                "numberOfBuyRents": notification.buyer.numberOfBuyRents
            ]

            return [
                "id": notification.id,
                "icon": notification.icon,
                "type": notification.type.rawValue,
                "username": notification.username,
                "actionText": notification.actionText,
                "timestamp": ISO8601DateFormatter().string(from: notification.timestamp),
                "productInfo": notification.productInfo,
                "price": notification.price,
                "size": notification.size,
                "duration": notification.duration,
                "name": notification.name,
                "address": notification.address,
                "imageUrls": notification.imageUrls,
                "shipImageUrl": notification.shipImageUrl ?? "",
                "buyer": buyerData,
                "isNew": notification.isNew
            ]
        }

        let userData: [String: Any] = [
            "username": user.username,
            "email": user.email,
            "firstName": user.firstName,
            "lastName": user.lastName,
            "address": user.address,
            "profilePictureURL": user.profilePictureURL,
            "venmo": user.venmo, // Add venmo field here
            "followers": user.followers,
            "following": user.following,
            "numberOfBuyRents": user.numberOfBuyRents,
            "notifications": notificationsData,
            "blockedUsers": user.blockedUsers, // Add blockedUsers field here,
            "fcmToken": user.fcmToken // Add fcmToken field here
        ]
        db.collection("users").document(user.id).setData(userData) { error in
            if let error = error {
                print("Error updating user data: \(error.localizedDescription)")
            }
            completion(error)
        }
    }
    
    func toggleFollow(currentUser: User, user: User, completion: @escaping (Bool) -> Void) {
        var currentUser = currentUser
        let user = user
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let currentUserRef = self.db.collection("users").document(currentUser.id)
            let userRef = self.db.collection("users").document(user.id)
            
            do {
                let currentUserDocument = try transaction.getDocument(currentUserRef)
                let userDocument = try transaction.getDocument(userRef)
                
                guard let currentUserData = currentUserDocument.data(),
                      let userData = userDocument.data() else {
                    return nil
                }
                
                var currentUserFollowing = currentUserData["following"] as? [String] ?? []
                var userFollowers = userData["followers"] as? [String] ?? []
                
                if currentUserFollowing.contains(user.id) {
                    currentUserFollowing.removeAll { $0 == user.id }
                    userFollowers.removeAll { $0 == currentUser.id }
                } else {
                    currentUserFollowing.append(user.id)
                    userFollowers.append(currentUser.id)

                    // Send notification to the user being followed
                    let message = "\(currentUser.username) started following you."
                    self.notificationManager.sendPushNotification(to: user.id, message: message)
                }
                
                transaction.updateData(["following": currentUserFollowing], forDocument: currentUserRef)
                transaction.updateData(["followers": userFollowers], forDocument: userRef)
                
                currentUser.following = currentUserFollowing
                
                // Update currentUser in Firestore
                self.updateUser(currentUser) { error in
                    if let error = error {
                        print("Error updating current user: \(error.localizedDescription)")
                        completion(false)
                        return
                    }
                    
                    // Update user in Firestore
                    if let index = self.users.firstIndex(where: { $0.id == user.id }) {
                        self.users[index].followers = userFollowers
                        self.updateUser(self.users[index]) { error in
                            if let error = error {
                                print("Error updating user: \(error.localizedDescription)")
                                completion(false)
                            } else {
                                completion(true)
                            }
                        }
                    } else {
                        completion(true)
                    }
                }
                
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
            return nil
        }) { (_, error) in
            if let error = error {
                print("Error toggling follow: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    func uploadProfileImage(image: UIImage, completion: @escaping (URL?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.75) else { return }
        let imageRef = storageRef.child("profile_pictures/\(UUID().uuidString).jpg")
        imageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("Error uploading profile image: \(error.localizedDescription)")
                completion(nil)
            } else {
                imageRef.downloadURL { url, error in
                    if let error = error {
                        print("Error getting download URL: \(error.localizedDescription)")
                        completion(nil)
                    } else {
                        completion(url)
                    }
                }
            }
        }
    }
}
