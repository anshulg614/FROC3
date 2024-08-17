//
//  BuyerOrRenterFulfillmentView.swift
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

struct BuyerOrRenterNotificationView: View {
    @Environment(\.presentationMode) var presentationMode
    let notification: NotificationItem
    @State private var showAlert = false
    @State private var images: [UIImage] = []
    @State private var data: [UIImage] = []
    @State private var shipmentImageURL: URL?
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage? = nil
    @State private var showGenerateLabelAlert = false
    @State private var imageUrl: String? = nil
    @EnvironmentObject var sessionStore: SessionStore
    @State private var showConfirmation = false // State for showing confirmation checkmark
    private let imageHeight: CGFloat = 175 // Consistent height for all images
    
    var body: some View {
        ZStack {
            DismissingKeyboardView()
            ScrollView {
                VStack(alignment: .center, spacing: 20) {
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Image(systemName: "arrow.left")
                                    .foregroundColor(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))

                                Text("Order Confirmation")
                                    .bold()
                                    .foregroundColor(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))

                            }
                        }
                        Spacer()
                    }
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 85, height: 85)
                        .foregroundColor(.green)
                    
                    Text("Your order has been confirmed by the seller and is being processed!")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    if let shipmentImageURL = shipmentImageURL {
                        VStack(alignment: .center, spacing: 0) { // Changed alignment to .center
                            infoBox(label: "Proof of Shipment:", value: "")
                                .font(.headline)
                            ZoomableImageView(url: shipmentImageURL, frameHeight: imageHeight)
                                .frame(height: imageHeight)
                                .padding()
                        }
                    } else {
                        Text("No shipment proof available yet.")
                            .font(.subheadline)
                            .padding(.horizontal)
                    }
                    
                    VStack(alignment: .leading, spacing: 15) {
                        if let expectedArrivalDate = notification.expectedArrivalDate {
                            infoBox(label: "Expected Arrival Date:", value: formattedDate(expectedArrivalDate))
                        }
                        if notification.type == .rent, let expectedReturnDate = notification.expectedReturnDate {
                            infoBox(label: "Expected Return Date:", value: formattedDate(expectedReturnDate))
                            HStack {
                                Spacer()
                                CountdownTimerView(endDate: expectedReturnDate)
                                    .padding(.horizontal)
                                    .onTapGesture {
                                        showAlert = true
                                    }
                                    .alert(isPresented: $showAlert) {
                                        Alert(
                                            title: Text("Important Notice"),
                                            message: Text("If you don't send the item back before the time expires, you could be fined or not get back your insurance money."),
                                            dismissButton: .default(Text("OK"))
                                        )
                                    }
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 15) {
                        infoBox(label: "Price:", value: String(format: "$%.2f", notification.price))
                        infoBox(label: "Estimated Time to Arrival:", value: "3 days")
                        if notification.type == .rent {
                            infoBox(label: "Rent Duration:", value: "\(notification.duration) days")
                        }
                    }
                    .padding(.vertical)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Seller Information")
                            .font(.title2)
                            .bold()
                        
                        InfoRow(label: "Username:", value: notification.username)
                        InfoRow(label: "Name:", value: notification.name)
                        InfoRow(label: "Address:", value: notification.address)
                        InfoRow(label: "Size:", value: notification.size)
                        InfoRow(label: "Action:", value: notification.actionText)
                        InfoRow(label: "Note:", value: notification.note ?? "")
                    }
                    .padding(.horizontal)
                    
                    TabView {
                        ForEach(notification.imageUrls, id: \.self) { imageUrl in
                            if let url = URL(string: imageUrl) {
                                ZoomableImageView(url: url, frameHeight: imageHeight)
                                    .frame(height: imageHeight)
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())
                    .frame(height: imageHeight)
                    .onAppear {
                        loadShipmentImage()
                    }
                    
                    if notification.type == .rent {
                        VStack {
                            Text("Upload Image with Tracking Label")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ImageSelectionView(selectedImages: $data)
                            
                            HStack {
                                Spacer()
                                Button(action: {
                                    let urlString = "https://cnsb.usps.com/label-manager/new-label"
                                    print("navigating to usps")
                                    if let url = URL(string: urlString) {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "doc.text.viewfinder")
                                        Text("Generate Label")
                                    }
                                    .padding()
                                    .frame(width: 325)
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                }
                                .simultaneousGesture(
                                    LongPressGesture().onEnded { _ in
                                        showGenerateLabelAlert = true
                                    }
                                )
                                .alert(isPresented: $showGenerateLabelAlert) {
                                    Alert(
                                        title: Text("Generate Label"),
                                        message: Text("You must upload an image with the shipping label. You will receive your insurance money when the user confirms they have the product."),
                                        dismissButton: .default(Text("OK"))
                                    )
                                }
                                Spacer()
                            }
                            .frame(height: 60)
                        }
                        
                        Button(action: {
                            if let firstImage = data.first {
                                uploadImage(image: firstImage) { url in
                                    if let url = url {
                                        self.imageUrl = url.absoluteString
                                        sendReturnNotificationToSeller {
                                            withAnimation {
                                                showConfirmation = true
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                                presentationMode.wrappedValue.dismiss()
                                            }
                                        }
                                    } else {
                                        print("Error uploading image")
                                    }
                                }
                            } else {
                                print("No image uploaded")
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrowshape.turn.up.left.circle")
                                Text("Return Item to Seller")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
            }
            
            if showConfirmation {
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.green)
                    Text("Return Notification Sent!")
                        .font(.title)
                        .bold()
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white.opacity(0.3))
                .transition(.opacity)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    private func uploadImage(image: UIImage, completion: @escaping (URL?) -> Void) {
        let storageRef = Storage.storage().reference().child("shipImages/\(UUID().uuidString).jpg")
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            storageRef.putData(imageData, metadata: nil) { (metadata, error) in
                if let error = error {
                    print("Error uploading image: \(error.localizedDescription)")
                    completion(nil)
                } else {
                    storageRef.downloadURL { (url, error) in
                        if let error = error {
                            print("Error fetching download URL: \(error.localizedDescription)")
                            completion(nil)
                        } else {
                            completion(url)
                        }
                    }
                }
            }
        }
    }
    
    private func loadShipmentImage() {
        guard let urlString = notification.shipImageUrl, let url = URL(string: urlString) else { return }
        shipmentImageURL = url
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    @ViewBuilder
    private func infoBox(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.headline)
            Spacer()
            Text(value)
                .font(.headline)
        }
        .padding(.horizontal)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func sendReturnNotificationToSeller(completion: (() -> Void)? = nil) {
        let db = Firestore.firestore()
        let sellerId = notification.buyer.id
        guard let currentUser = sessionStore.currentUser else {
            print("Current user is not available.")
            return
        }
        
        let notificationData: [String: Any] = [
            "username": currentUser.username,
            "type": "return",
            "actionText": "returned your item",
            "timestamp": FieldValue.serverTimestamp(),
            "productInfo": notification.productInfo,
            "price": notification.price,
            "size": notification.size,
            "duration": notification.duration,
            "name": notification.buyer.firstName,
            "address": "",
            "imageUrls": notification.imageUrls,
            "shipImageUrl": imageUrl ?? "", // Use the uploaded image URL here
            "expectedArrivalDate": notification.expectedArrivalDate ?? NSNull(),
            "expectedReturnDate": notification.expectedReturnDate ?? NSNull(),
            "icon": "archivebox",
            "buyer": [
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
        ]
        
        print("Sending notification to: \(sellerId)")
        db.collection("users").document(sellerId).collection("notifications").addDocument(data: notificationData) { error in
            if let error = error {
                print("Error adding notification: \(error.localizedDescription)")
            } else {
                print("Return notification sent to seller.")
                // Send push notification
                self.sessionStore.sendPushNotification(to: sellerId, message: "\(currentUser.username) returned your item")
                completion?()
            }
        }
    }
}
