//
//  PostStore.swift
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

class PostStore: ObservableObject {
    @Published var posts: [Post] = []

    private var db = Firestore.firestore()
    private var storageRef = Storage.storage().reference()
    private var notificationManager = NotificationManager()

    init() {
        refreshData()
        fetchPosts()
    }

    func fetchPosts() {
        db.collection("posts").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching posts: \(error.localizedDescription)")
            } else {
                if let snapshot = snapshot {
                    let documents = snapshot.documents
                    var posts: [Post] = []

                    let group = DispatchGroup()

                    for document in documents {
                        group.enter()
                        let data = document.data()
                        let imageUrls = data["imageUrls"] as? [String] ?? []
                        let likedBy = data["likedBy"] as? [String] ?? []
                        let timestamp = data["timestamp"] as? Timestamp ?? Timestamp(date: Date(timeIntervalSince1970: 0))

                        self.fetchComments(for: document.documentID) { comments in
                            let userId = data["userId"] as? String ?? ""
                            self.fetchUser(for: userId) { user in
                                guard let user = user else {
                                    group.leave()
                                    return
                                }
                                let post = Post(
                                    id: document.documentID,
                                    user: user,
                                    imageUrls: imageUrls,
                                    caption: data["caption"] as? String ?? "",
                                    saleOption: Post.SaleOption(rawValue: data["saleOption"] as? String ?? "Purchase") ?? .purchase,
                                    purchasePrice: data["purchasePrice"] as? String ?? "",
                                    rentPrice: data["rentPrice"] as? String ?? "",
                                    sizes: data["sizes"] as? [String] ?? [],
                                    description: data["description"] as? String ?? "",
                                    numberOfLikes: data["numberOfLikes"] as? Int ?? 0,
                                    likedBy: likedBy,
                                    comments: comments,
                                    timestamp: timestamp,
                                    clothingCategories: data["clothingCategories"] as? [String] ?? [],
                                    seasonalCollections: data["seasonalCollections"] as? [String] ?? [],
                                    occasions: data["occasions"] as? [String] ?? [],
                                    color: data["color"] as? String ?? "",
                                    brand: data["brand"] as? String ?? "",
                                    title: data["title"] as? String ?? "",
                                    gender: data["gender"] as? String ?? ""
                                )
                                posts.append(post)
                                group.leave()
                            }
                        }
                    }

                    group.notify(queue: .main) {
                        self.posts = posts.sorted(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() })
                    }
                }
            }
        }
    }
    func fetchComments(for postId: String, completion: @escaping ([Comment]) -> Void) {
        db.collection("posts").document(postId).collection("comments").order(by: "timestamp", descending: false).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching comments: \(error.localizedDescription)")
                completion([])
            } else {
                if let snapshot = snapshot {
                    let comments = snapshot.documents.map { document in
                        let data = document.data()
                        return Comment(
                            id: document.documentID,
                            userId: data["userId"] as? String ?? "",
                            username: data["username"] as? String ?? "",
                            profilePictureURL: data["profilePictureURL"] as? String ?? "",
                            text: data["text"] as? String ?? "",
                            timestamp: data["timestamp"] as? Timestamp ?? Timestamp()
                        )
                    }
                    completion(comments)
                } else {
                    completion([])
                }
            }
        }
    }

    func fetchUser(for userId: String, completion: @escaping (User?) -> Void) {
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists, let data = document.data() {
                let user = User(
                    id: userId,
                    username: data["username"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    firstName: data["firstName"] as? String ?? "",
                    lastName: data["lastName"] as? String ?? "",
                    address: data["address"] as? String ?? "",
                    profilePictureURL: data["profilePictureURL"] as? String ?? "",
                    followers: data["followers"] as? [String] ?? [], // Corrected to be an array of strings
                    numberOfBuyRents: data["numberOfBuyRents"] as? Int ?? 0
                )
                completion(user)
            } else {
                print("Error fetching user: \(error?.localizedDescription ?? "No data")")
                completion(nil)
            }
        }
    }

    private func sendNotification(to userId: String, type: NotificationItem.NotificationType, actionText: String, post: Post, actor: User) {
        let notificationData: [String: Any] = [
            "username": actor.username,
            "type": type.rawValue,
            "actionText": actionText,
            "timestamp": FieldValue.serverTimestamp(),
            "productInfo": post.description,
            "price": post.rentPrice.isEmpty ? Double(post.purchasePrice)! : Double(post.rentPrice)!,
            "size": post.sizes.joined(separator: ", "), // Assuming sizes are array of strings
            "duration": "", // Assuming duration is not relevant for likes and comments
            "name": actor.firstName + " " + actor.lastName,
            "address": "", // Assuming address is not relevant for likes and comments
            "imageUrl": post.imageUrls.first ?? "",
            "icon": type == .comment ? "bubble.right" : "heart", // Icon for comments and likes
        ]

        db.collection("users").document(userId).collection("notifications").addDocument(data: notificationData) { error in
            if let error = error {
                print("Error adding notification: \(error.localizedDescription)")
            } else {
                print("Notification sent to user.")
            }
        }
    }

    func addComment(to postId: String, comment: Comment, commenter: User) {
        let commentData: [String: Any] = [
            "userId": comment.userId,
            "username": comment.username,
            "profilePictureURL": comment.profilePictureURL,
            "text": comment.text,
            "timestamp": comment.timestamp
        ]
        db.collection("posts").document(postId).collection("comments").addDocument(data: commentData) { error in
            if let error = error {
                print("Error adding comment: \(error.localizedDescription)")
            } else {
                // Fetch the post to get the post details and the post owner's ID
                self.db.collection("posts").document(postId).getDocument { document, error in
                    if let document = document, document.exists, let data = document.data() {
                        let userId = data["userId"] as? String ?? ""
                        self.fetchUser(for: userId) { user in
                            guard let user = user else { return }
                            let post = Post(
                                id: document.documentID,
                                user: user,
                                imageUrls: data["imageUrls"] as? [String] ?? [],
                                caption: data["caption"] as? String ?? "",
                                saleOption: Post.SaleOption(rawValue: data["saleOption"] as? String ?? "Purchase") ?? .purchase,
                                purchasePrice: data["purchasePrice"] as? String ?? "",
                                rentPrice: data["rentPrice"] as? String ?? "",
                                sizes: data["sizes"] as? [String] ?? [],
                                description: data["description"] as? String ?? "",
                                numberOfLikes: data["numberOfLikes"] as? Int ?? 0,
                                likedBy: data["likedBy"] as? [String] ?? [],
                                comments: [] // Comments will be fetched separately
                            )

                            // Send notification to the post owner
                            self.sendNotification(
                                to: userId,
                                type: .comment,
                                actionText: "commented '\(comment.text)'",
                                post: post,
                                actor: commenter
                            )

                            // Send push notification to the post owner
                            self.notificationManager.sendPushNotification(
                                to: post.user.id,
                                message: "\(commenter.username) commented: '\(comment.text)' on your post."
                            )
                        }
                    }
                }
            }
        }
    }

    func toggleLike(post: Post, userId: String) {
        var updatedPost = post

        if updatedPost.likedBy.contains(userId) {
            // Unlike the post
            updatedPost.likedBy.removeAll { $0 == userId }
            updatedPost.numberOfLikes -= 1
        } else {
            // Like the post
            updatedPost.likedBy.append(userId)
            updatedPost.numberOfLikes += 1

            // Send notification to the post owner
            fetchUser(for: userId) { liker in
                guard let liker = liker else { return }
                self.notificationManager.sendPushNotification(
                    to: post.user.id,
                    message: "\(liker.username) liked your post."
                )
            }
        }

        // Update Firestore
        let postData: [String: Any] = [
            "numberOfLikes": updatedPost.numberOfLikes,
            "likedBy": updatedPost.likedBy
        ]

        db.collection("posts").document(updatedPost.id).updateData(postData) { error in
            if let error = error {
                print("Error updating post: \(error.localizedDescription)")
            } else {
                if let index = self.posts.firstIndex(where: { $0.id == updatedPost.id }) {
                    self.posts[index] = updatedPost
                }
            }
        }
    }

    func fetchUserProfilePictures() {
        let userIds = posts.map { $0.user.id }
        let uniqueUserIds = Array(Set(userIds))

        uniqueUserIds.forEach { userId in
            fetchUser(for: userId) { user in
                guard let user = user else { return }
                self.posts = self.posts.map { post in
                    var updatedPost = post
                    if post.user.id == userId {
                        updatedPost.user = user
                    }
                    return updatedPost
                }
            }
        }
    }

    func deletePost(_ post: Post, completion: @escaping (Bool) -> Void) {
        // Implement the deletion logic, for example:
        db.collection("posts").document(post.id).delete { error in
            if let error = error {
                print("Error deleting post: \(error.localizedDescription)")
                completion(false)
            } else {
                // Remove post from local store
                self.posts.removeAll { $0.id == post.id }
                completion(true)
            }
        }
    }

    func refreshData() {
        fetchPosts()
        fetchUserProfilePictures()
    }

    func addPost(_ post: Post, images: [UIImage]) {
        let imageRefs = images.map { _ in "posts/\(UUID().uuidString).jpg" }
        let uploadGroup = DispatchGroup()

        var uploadedImageUrls: [String] = []

        for (index, image) in images.enumerated() {
            uploadGroup.enter()
            let imageRef = storageRef.child(imageRefs[index])
            guard let imageData = image.jpegData(compressionQuality: 0.75) else { continue }

            imageRef.putData(imageData, metadata: nil) { _, error in
                if let error = error {
                    print("Error uploading image: \(error.localizedDescription)")
                    uploadGroup.leave()
                } else {
                    imageRef.downloadURL { url, error in
                        if let error = error {
                            print("Error getting download URL: \(error.localizedDescription)")
                        } else if let url = url {
                            uploadedImageUrls.append(url.absoluteString)
                        }
                        uploadGroup.leave()
                    }
                }
            }
        }

        uploadGroup.notify(queue: .main) {
            let postData: [String: Any] = [
                "userId": post.user.id,
                "caption": post.caption,
                "saleOption": post.saleOption.rawValue,
                "purchasePrice": post.purchasePrice,
                "rentPrice": post.rentPrice,
                "description": post.description,
                "numberOfLikes": post.numberOfLikes,
                "likedBy": post.likedBy,
                "imageUrls": uploadedImageUrls,
                "sizes": post.sizes,
                "timestamp": FieldValue.serverTimestamp(),
                "clothingCategories": post.clothingCategories,
                "seasonalCollections": post.seasonalCollections,
                "occasions": post.occasions,
                "color": post.color,
                "brand": post.brand,
                "title": post.title,
                "gender": post.gender
            ]
            self.db.collection("posts").addDocument(data: postData) { error in
                if let error = error {
                    print("Error adding post: \(error.localizedDescription)")
                } else {
                    self.fetchPosts()
                }
            }
        }
    }
}
