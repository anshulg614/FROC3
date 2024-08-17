//
//  FulfillmentView.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 8/17/24.
//

import Foundation
import SwiftUI
import FirebaseStorage
import Firebase
import FirebaseFirestore

struct FulfillmentView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var sessionStore: SessionStore
    @State var notification: NotificationItem
    @State private var images: [UIImage] = []
    @State private var data: [UIImage] = []
    
    @State private var showAlert = false
    @State private var showGenerateLabelAlert = false
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage? = nil
    @State private var uploadImageUrl: String = ""
    @State private var shipImageUrl: String = ""
    @State private var note: String = ""
    @State private var showConfirmation = false // State for showing confirmation checkmark
    private let imageHeight: CGFloat = 250 // Consistent height for all images
    
    var body: some View {
        ZStack {
            DismissingKeyboardView()
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Image(systemName: "arrow.left")
                                    .foregroundColor(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))

                                Text("Fulfillment")
                                    .bold()
                                    .foregroundColor(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))

                            }
                        }
                        Spacer()
                    }
                    
                    // Carousel for multiple images
                    TabView {
                        ForEach(notification.imageUrls, id: \.self) { imageUrl in
                            ZoomableImageView(url: URL(string: imageUrl), frameHeight: imageHeight)
                                .frame(height: imageHeight)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())
                    .frame(height: imageHeight)
                    .onAppear {
                        loadImages()
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        infoBox(label: "Product Info:", value: notification.productInfo)
                        infoBox(label: "Price:", value: String(format: "$%.2f", notification.price))
                        infoBox(label: "Requested on:", value: formattedDate(Date()))
                        if notification.type == .rent {
                            infoBox(label: "Rent Duration:", value: "\(notification.duration) days")
                        }
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Buyer Information")
                            .font(.title2)
                            .bold()
                        
                        InfoRow(label: "Username:", value: notification.buyer.username)
                        InfoRow(label: "Name:", value: notification.buyer.firstName + " " + notification.buyer.lastName)
                        InfoRow(label: "Address:", value: notification.buyer.address)
                        InfoRow(label: "Size:", value: notification.size)
                        InfoRow(label: "Order sent on:", value: formattedDate(Date()))
                        InfoRow(label: "Action:", value: notification.actionText)
                        InfoRow(label: "Note:", value: notification.note ?? "")
                        TextField("Note to recipient (e.g. Product shipped!)", text: $note)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                            .frame(height: 50) // Increase the height of the text field
                            .frame(maxWidth: .infinity) // Make sure it takes up the available width
                        
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 5) { // Adjusted spacing
                        if let expectedArrivalDate = notification.expectedArrivalDate {
                            infoBox(label: "Expected Arrival Date:", value: formattedDate(expectedArrivalDate))
                        }
                        if notification.type == .rent, let expectedReturnDate = notification.expectedReturnDate {
                            infoBox(label: "Expected Return Date:", value: formattedDate(expectedReturnDate))
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
                        }
                    }
                    .padding(.horizontal)
                    
                    // Upload Image Section
                    VStack(alignment: .leading, spacing: 5) { // Adjusted spacing
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
                                    message: Text("You must upload an image with the shipping label. You will receive your money when the user confirms they have the product."),
                                    dismissButton: .default(Text("OK"))
                                )
                            }
                            Spacer()
                        }
                        .frame(height: 60)
                    }
                    
                    HStack {
                        Spacer()
                        Button(action: {
                            handleConfirmAndShip {
                                withAnimation {
                                    showConfirmation = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Confirm & Ship")
                            }
                            .padding()
                            .frame(width: 200)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .simultaneousGesture(
                            LongPressGesture().onEnded { _ in
                                showAlert = true
                            }
                        )
                        .alert(isPresented: $showAlert) {
                            Alert(
                                title: Text("Confirm & Ship"),
                                message: Text("Once you press this button, you will confirm the shipment and send the image to the buyer or renter."),
                                primaryButton: .default(Text("Confirm")) {
                                    handleConfirmAndShip {
                                        withAnimation {
                                            showConfirmation = true
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                            presentationMode.wrappedValue.dismiss()
                                        }
                                    }
                                },
                                secondaryButton: .cancel()
                            )
                        }
                        
                        Button("Don't Fulfill") {
                            handleDontFulfill {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        Spacer()
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal)
                .padding(.top, 20)
            }
            
            if showConfirmation {
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.green)
                    Text("Order Fulfilled!")
                        .font(.title)
                        .bold()
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white.opacity(0.3))
                .transition(.opacity)
            }
        }
        .navigationBarHidden(true)
    }
    
    private func loadImages() {
        notification.imageUrls.forEach { urlString in
            guard let url = URL(string: urlString) else { return }
            
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.images.append(image)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.images.append(UIImage(systemName: "photo")!)
                    }
                }
            }.resume()
        }
        
        if let shipImageUrlString = notification.shipImageUrl, let url = URL(string: shipImageUrlString) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.images.append(image)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.images.append(UIImage(systemName: "photo")!)
                    }
                }
            }.resume()
        }
    }
    
    private func handleImageUpload(completion: @escaping (String?) -> Void) {
        guard let selectedImage = data.first else { return }
        
        let storageRef = Storage.storage().reference().child("shipImages/\(UUID().uuidString).jpg")
        if let imageData = selectedImage.jpegData(compressionQuality: 0.8) {
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
                            completion(url?.absoluteString)
                        }
                    }
                }
            }
        }
    }
    
    private func handleConfirmAndShip(completion: (() -> Void)? = nil) {
        handleImageUpload { imageUrl in
            guard let imageUrl = imageUrl else { return }
            self.notification.shipImageUrl = imageUrl
            
            let expectedArrivalDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
            var expectedReturnDate: Date? = nil
            
            if self.notification.type == .rent {
                if let duration = Int(self.notification.duration) {
                    expectedReturnDate = Calendar.current.date(byAdding: .day, value: 3 + duration, to: Date())
                } else {
                    expectedReturnDate = nil
                }
            }
            
            self.sendNotificationToBuyerOrRenter(expectedArrivalDate: expectedArrivalDate, expectedReturnDate: expectedReturnDate)
            
            completion?()
        }
    }
    
    private func handleDontFulfill(completion: @escaping () -> Void) {
        guard let currentUserId = sessionStore.currentUser?.id else {
            print("Current user ID is not available.")
            return
        }
        
        sessionStore.deleteNotification(notificationId: notification.id) { success in
            if success {
                print("Notification successfully deleted")
                completion()
            } else {
                print("Failed to delete notification")
            }
        }
        sessionStore.fetchNotifications(userId: currentUserId)
    }
    
    private func sendNotificationToBuyerOrRenter(expectedArrivalDate: Date?, expectedReturnDate: Date?) {
        let db = Firestore.firestore()
        let buyerId = notification.buyer.id
        
        let buyerRef = db.collection("users").document(buyerId)
        
        // Use a Firestore transaction to ensure atomic updates
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let buyerDocument: DocumentSnapshot
            do {
                try buyerDocument = transaction.getDocument(buyerRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let currentNumberOfBuyRents = buyerDocument.data()?["numberOfBuyRents"] as? Int else {
                let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to retrieve numberOfBuyRents from snapshot \(buyerDocument)"])
                errorPointer?.pointee = error
                return nil
            }
            
            // Update the numberOfBuyRents field
            transaction.updateData(["numberOfBuyRents": currentNumberOfBuyRents + 1], forDocument: buyerRef)
            
            return nil
        }) { (object, error) in
            if let error = error {
                print("Error updating numberOfBuyRents: \(error)")
            } else {
                print("Successfully updated numberOfBuyRents")
            }
        }
        
        guard let currentUser = sessionStore.currentUser else {
            print("Current user is not available.")
            return
        }
        print(currentUser.id)
        
        let notificationData: [String: Any] = [
            "username": currentUser.username,
            "type": notification.type.rawValue,
            "actionText": "confirmed your order!",
            "timestamp": FieldValue.serverTimestamp(),
            "productInfo": notification.productInfo,
            "price": notification.price,
            "size": notification.size,
            "duration": notification.duration,
            "name": currentUser.firstName,
            "address": currentUser.address,
            "imageUrls": notification.imageUrls,
            "shipImageUrl": notification.shipImageUrl ?? "",
            "expectedArrivalDate": expectedArrivalDate ?? NSNull(),
            "expectedReturnDate": expectedReturnDate ?? NSNull(),
            "icon": "shippingbox",
            "note": note,
            "buyer": [
                "id": currentUser.id,
                "username": currentUser.username,
                "email": notification.buyer.email,
                "firstName": notification.buyer.firstName,
                "lastName": notification.buyer.lastName,
                "address": notification.buyer.address,
                "profilePictureURL": notification.buyer.profilePictureURL,
                "followers": notification.buyer.followers,
                "numberOfBuyRents": notification.buyer.numberOfBuyRents
            ]
        ]
        
        db.collection("users").document(buyerId).collection("notifications").addDocument(data: notificationData) { error in
            if let error = error {
                print("Error adding notification: \(error.localizedDescription)")
            } else {
                print("Notification sent to buyer/renter.")
                // Send push notification
                self.sessionStore.sendPushNotification(to: buyerId, message: "\(currentUser.username) confirmed your order!")
            }
        }
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
}

