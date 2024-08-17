//
//  AdminApprovalView.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 8/17/24.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

struct AdminApprovalView: View {
    @EnvironmentObject var sessionStore: SessionStore
    var notification: NotificationItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            DismissingKeyboardView()
            
            Text(notification.actionText)
                .font(.headline)
            
            Text("Product Info: \(notification.productInfo)")
                .font(.subheadline)
            
            Text("Price: \(notification.price, specifier: "%.2f")")
                .font(.subheadline)
            
            Text("Size: \(notification.size)")
                .font(.subheadline)
            
            Text("Note: \(notification.note ?? "")")
                .font(.subheadline)
            
            Text("Venmo: \(notification.venmo ?? "")")
                .font(.subheadline)
            
            if notification.type == .rent {
                Text("Rent Duration: \(notification.duration) days")
                    .font(.subheadline)
            }
            
            Text("Buyer: \(notification.buyer.firstName) \(notification.buyer.lastName)")
                .font(.subheadline)
            
            Text("Address: \(notification.buyer.address)")
                .font(.subheadline)
            
            Text("Current Date and Time: \(formattedDate(Date()))")
                .font(.subheadline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(notification.imageUrls, id: \.self) { imageUrl in
                        AsyncImage(url: URL(string: imageUrl)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 100, height: 100)
                            case .success(let image):
                                image.resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 100, height: 100)
                            case .failure:
                                Image(systemName: "xmark.circle")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.red)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                }
            }
            .frame(height: 120)
            
            Button(action: {
                print("Approve button tapped for notification: \(notification.id)")
                approveNotification(notification: notification)
            }) {
                HStack {
                    Image(systemName: "checkmark.circle")
                    Text("Approve")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .navigationBarTitle("Admin Approval", displayMode: .inline)
    }
    
    private func approveNotification(notification: NotificationItem) {
        print("Approving notification: \(notification.id)")
        
        // Send the notification to the seller
        sendNotificationToSeller(notification: notification) {
            print("Notification sent to seller for notification: \(notification.id)")
            
            // After sending the notification to the seller, send a push notification
            if let sellerId = notification.shipImageUrl, !sellerId.isEmpty {
                sessionStore.sendPushNotification(to: sellerId, message: "Your item has been requested for fulfillment!")
            } else {
                print("Error: sellerId is empty.")
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func sendNotificationToSeller(notification: NotificationItem, completion: @escaping () -> Void) {
        print("Preparing to send notification to seller for notification: \(notification.id)")
        let db = Firestore.firestore()
        let sellerId = notification.shipImageUrl ?? "" // Replace with actual seller ID
        
        print("sellerId: \(sellerId)")
        if sellerId.isEmpty {
            print("Error: sellerId is empty.")
            return
        }
        
        let notificationData: [String: Any] = [
            "username": notification.username,
            "type": notification.type.rawValue,
            "actionText": "wants to \(notification.type.rawValue)",
            "timestamp": FieldValue.serverTimestamp(),
            "productInfo": notification.productInfo,
            "price": notification.price,
            "size": notification.size,
            "duration": notification.duration,
            "name": notification.name,
            "address": notification.address,
            "imageUrls": notification.imageUrls,
            "icon": notification.icon,
            "buyer": notification.buyer.toDict(),
            "note": notification.note ?? "",
            "venmo": notification.venmo ?? ""
        ]
        
        print("Notification data prepared for seller: \(notificationData)")
        
        if let buyerDict = notificationData["buyer"] as? [String: Any] {
            print("Buyer data: \(buyerDict)")
        } else {
            print("Error: Buyer data is not a valid dictionary")
        }
        
        let fieldsPart1 = ["username", "type", "actionText", "timestamp", "productInfo", "price"]
        let fieldsPart2 = ["size", "duration", "name", "address", "imageUrls", "icon", "buyer"]

        func checkFields(fields: [String], in data: [String: Any]) {
            for field in fields {
                if data[field] == nil {
                    print("Error: \(field) is nil")
                } else {
                    print("\(field): \(String(describing: data[field]))")
                }
            }
        }

        checkFields(fields: fieldsPart1, in: notificationData)
        checkFields(fields: fieldsPart2, in: notificationData)

        let userDocRef = db.collection("users").document(sellerId)
        print("User document reference created: \(userDocRef.path)")
        
        let notificationsCollectionRef = userDocRef.collection("notifications")
        print("Notifications collection reference created: \(notificationsCollectionRef.path)")
        
        notificationsCollectionRef.addDocument(data: notificationData) { error in
            if let error = error {
                print("Error adding notification: \(error.localizedDescription)")
            } else {
                print("Notification sent to seller with sellerId: \(sellerId)")
                completion()
            }
        }
    }
}

