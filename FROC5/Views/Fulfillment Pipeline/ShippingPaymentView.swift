//
//  ShippingAndPaymentView.swift
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

struct ShippingPaymentView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var rentDuration: Int = 1 // Default rent duration
    @State private var isRent: Bool = false
    @State private var name: String = ""
    @State private var note: String = ""
    @State private var ven: String = ""
    @State private var selectedSize: String = "" // Change to single selected size
    @State private var showPaymentInfo = false
    @State private var imageLoadError = false
    @State private var showConfirmation = false // State for showing confirmation checkmark
    @State private var showingGuestAlert = false
    
    @EnvironmentObject var sessionStore: SessionStore
    var post: Post // Accept the entire post object
    
    init(post: Post) {
        self.post = post
        _isRent = State(initialValue: post.saleOption != .purchase)
    }
    
    var body: some View {
        ZStack {
            DismissingKeyboardView()
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Spacer(minLength: 4)
                    // Navigation Bar
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Image(systemName: "arrow.left")
                                    .foregroundColor(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))
                                
                                Text("Shipping & Payment")
                                    .bold()
                                    .foregroundColor(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Product Image and Info
                    if imageLoadError {
                        Text("Failed to load images. Please try again later.")
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    } else {
                        TabView {
                            ForEach(post.imageUrls, id: \.self) { imageUrl in
                                AsyncImage(url: URL(string: imageUrl)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(height: 300) // Adjusted image size
                                    case .success(let image):
                                        image.resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(height: 300) // Adjusted image size
                                    case .failure:
                                        Image(systemName: "xmark.circle")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(height: 300) // Adjusted image size
                                            .foregroundColor(.red)
                                            .onAppear {
                                                imageLoadError = true
                                            }
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            }
                        }
                        .tabViewStyle(PageTabViewStyle())
                        .frame(height: 300)
                    }
                    
                    Text("@\(post.user.username): \(post.description.isEmpty || post.description == "Default product description" ? post.title : post.description)")
                        .font(.body) // Changed to .body for a smaller font size
                        .bold()
                        .padding()
                        .background(Color(.systemGray4))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    
                    HStack {
                        Text("Price: $\(isRent ? (Double(post.rentPrice)! * Double(rentDuration)) : Double(post.purchasePrice)!, specifier: "%.2f") + \(isRent ? (Double(post.rentPrice)! * 0.03 * Double(rentDuration)) : Double(post.purchasePrice)! * 0.06, specifier: "%.2f") transaction fees")
                            .font(.headline)
                    }
                    .padding(.horizontal)
                    
                    if isRent {
                        let insuranceCost = Double(post.purchasePrice)! * 0.25
                        Text("Insurance: $\(insuranceCost, specifier: "%.2f") (This amount is held as insurance and will be refunded once the product is returned in good condition.)")
                            .font(.subheadline)
                            .padding(.horizontal)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(post.sizes, id: \.self) { size in
                                Button(action: {
                                    selectedSize = size // Ensure only one size is selected
                                }) {
                                    Text(size)
                                        .foregroundColor(selectedSize == size ? .white : Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))
                                        .padding()
                                        .background(selectedSize == size ? Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0) : Color.clear)
                                        .cornerRadius(5)
                                }
                                .padding(.leading, 10)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 44) // Set a fixed height for the ScrollView
                    
                    if post.saleOption == .purchaseOrRent {
                        Toggle(isOn: $isRent) {
                            Text(isRent ? "Rent" : "Buy")
                                .font(.headline)
                        }
                        .padding(.horizontal)
                    } else {
                        Text(post.saleOption == .purchase ? "Buy" : "Rent")
                            .font(.headline)
                            .padding(.horizontal)
                    }
                    
                    if (isRent && post.saleOption == .purchaseOrRent) || post.saleOption == .rent {
                        Picker("Rent Duration", selection: $rentDuration) {
                            ForEach(1...40, id: \.self) { day in
                                Text("\(day) day\(day > 1 ? "s" : "")")
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 120) // Set the height to limit picker size
                        .clipped() // Clip the overflowing part of the picker
                        .padding(.horizontal)
                    }
                    
                    // Note and Venmo Username TextFields
                    VStack(spacing: 4) { // Add vertical spacing between fields
                        TextField("Note to recipient (e.g. I love this product!)", text: $note)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                            .frame(height: 50) // Increase the height of the text field
                            .frame(maxWidth: .infinity) // Make sure it takes up the available width
                        
                        TextField("Your venmo username...", text: $ven)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                            .frame(height: 50) // Increase the height of the text field
                            .frame(maxWidth: .infinity) // Make sure it takes up the available width
                    }
                    
                    // Payment Button
                    Button(action: {
                        if sessionStore.isGuestMode {
                            showingGuestAlert = true
                        } else {
                            print("Pay with Venmo button tapped")
                            let venmoUsername = "FROC-Marketplace"
                            let baseAmount = isRent ? Double(post.rentPrice)! * Double(rentDuration) : Double(post.purchasePrice)!
                            let taxAmount = isRent ? baseAmount * 0.03 : baseAmount * 0.06
                            let insuranceAmount = isRent ? Double(post.purchasePrice)! * 0.25 : 0
                            let paymentAmount = baseAmount + taxAmount + insuranceAmount
                            let paymentNote = """
                            Payment for \(isRent ? "renting" : "buying") the item
                            Size: \(selectedSize)
                            Description: \(post.description)
                            Duration: \(rentDuration) day(s)
                            \(isRent ? "Insurance cost: $\(insuranceAmount) (will be returned once the product is returned)" : "")
                            """
                            
                            // Encode the payment note to ensure it’s URL safe
                            let encodedNote = paymentNote.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                            
                            // Create the Venmo URL string
                            let venmoURLString = "venmo://paycharge?txn=pay&recipients=\(venmoUsername)&amount=\(paymentAmount)&note=\(encodedNote)"
                            
                            // Open the URL to launch Venmo app
                            if let venmoURL = URL(string: venmoURLString), UIApplication.shared.canOpenURL(venmoURL) {
                                UIApplication.shared.open(venmoURL)
                            } else {
                                print("Venmo app is not installed.")
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "creditcard") // Placeholder for Venmo icon
                            Text("Pay with Venmo")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        if sessionStore.isGuestMode {
                            showingGuestAlert = true
                        } else {
                            print("Confirm Payment button tapped")
                            sendNotificationToAdminForApproval {
                                withAnimation {
                                    showConfirmation = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("Confirm Payment")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .simultaneousGesture(LongPressGesture().onEnded { _ in
                        showPaymentInfo = true
                    })
                    .alert(isPresented: $showPaymentInfo) {
                        Alert(
                            title: Text("Payment Information"),
                            message: Text("Make sure to pay on venmo before clicking this button. Once the payment is sent, the FROC team will review it and ensure the buyer receives the product before the seller receives their money. We take a little bit extra money for insurance if the product is rented out as insurance in case a product is not returned on time or if the product is damaged. If the product is not returned, the seller keeps the insurance money."),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                    .alert(isPresented: $showingGuestAlert) {
                        Alert(
                            title: Text("Feature Unavailable"),
                            message: Text("You can only access this feature if you make an account."),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                }
            }
            
            
            if showConfirmation {
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.green)
                    Text("Order Sent!")
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
        .onAppear {
            print("ShippingPaymentView appeared")
        }
    }
    
    private func sendNotificationToAdminForApproval(completion: @escaping () -> Void) {
        print("Sending notification to admin for approval...")
        let db = Firestore.firestore()
        let adminId = "fhA46cyXc0M9loGVJuuBnkR8odx1" // Replace with the actual admin user ID
        guard let currentUser = sessionStore.currentUser else {
            print("Current user is not available.")
            return
        }
        let buyerData: [String: Any] = [
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
        let notificationData: [String: Any] = [
            "username": currentUser.username,
            "type": isRent ? "rent" : "purchase",
            "actionText": isRent ? "admin wants to rent" : "admin wants to buy",
            "timestamp": FieldValue.serverTimestamp(),
            "productInfo": post.description,
            "price": isRent ? Double(post.rentPrice)! * Double(rentDuration) : Double(post.purchasePrice)!,
            "size": selectedSize,
            "duration": isRent ? "\(rentDuration)" : "",
            "name": currentUser.firstName + currentUser.lastName,
            "address": currentUser.address,
            "imageUrls": post.imageUrls, // Add all image URLs of the post
            "icon": isRent ? "tag" : "cart",  // Add the icon to the notification data
            "buyer": buyerData, // Add buyer data to the notification
            "shipImageUrl": post.user.id,
            "note": note,
            "venmo": ven
        ]
        db.collection("users").document(adminId).collection("notifications").addDocument(data: notificationData) { error in
            if let error = error {
                print("Error adding notification: \(error.localizedDescription)")
            } else {
                print("Notification sent to seller.")
                completion()
            }
        }
    }
}

