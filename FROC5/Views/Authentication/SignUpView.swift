//
//  SignUpView.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 8/16/24.
//

import Foundation
import SwiftUI
import Firebase

struct SignUpView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @Environment(\.presentationMode) var presentationMode
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var username: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var address: String = ""
    @State private var venmo: String = ""
    @State private var showVenmoField: Bool = true
    @State private var errorMessage: String?
    @State private var agreedToTerms: Bool = false
    @State private var showingTermsOfService = false

    private var db = Firestore.firestore()

    var body: some View {
        ZStack {
            DismissingKeyboardView()
            VStack {
                Text("FROC")
                    .font(.custom("Billabong", size: 80))
                    .padding(.top, 50)

                VStack(spacing: 10) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)

                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    TextField("Username", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    TextField("First Name", text: $firstName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    TextField("Last Name", text: $lastName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    TextField("Address (e.g., 123 Main St, City, State, ZIP)", text: $address)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)

                    if showVenmoField {
                        TextField("Venmo Username", text: $venmo)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .padding()

                Toggle(isOn: $showVenmoField) {
                    Text("Venmo")
                        .padding()
                        .foregroundColor(.gray)
                }

                HStack {
                    Button(action: {
                        self.agreedToTerms.toggle()
                    }) {
                        Image(systemName: agreedToTerms ? "checkmark.square" : "square")
                        Text("I agree to the")
                        Button(action: {
                            self.showingTermsOfService = true
                        }) {
                            Text("Terms of Service")
                                .underline()
                        }
                    }
                }
                .padding(.horizontal)
                .sheet(isPresented: $showingTermsOfService) {
                    TermsOfServiceView()
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                Button(action: {
                    if !agreedToTerms {
                        self.errorMessage = "You must agree to the Terms of Service"
                    } else if email.isEmpty || password.isEmpty || username.isEmpty || firstName.isEmpty || lastName.isEmpty || address.isEmpty {
                        self.errorMessage = "All fields except Venmo are required"
                    } else {
                        signUp(email: email, password: password)
                    }
                }) {
                    Text("Sign Up")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 220, height: 50)
                        .background(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))
                        .cornerRadius(10)
                }
                .padding(.top, 20)
            }
            .padding()
        }
    }

    func signUp(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else if let user = authResult?.user {
                var userData: [String: Any] = [
                    "username": self.username,
                    "email": email,
                    "firstName": self.firstName,
                    "lastName": self.lastName,
                    "address": self.address
                ]

                if self.showVenmoField {
                    userData["venmo"] = self.venmo
                }

                self.db.collection("users").document(user.uid).setData(userData) { error in
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                    } else {
                        sendWelcomeNotification(to: user.uid)
                        self.sessionStore.isSignedIn = true
                        self.presentationMode.wrappedValue.dismiss()

                        // Save the FCM token
                        if let fcmToken = Messaging.messaging().fcmToken {
                            self.sessionStore.saveUserFCMToken(userId: user.uid, fcmToken: fcmToken)
                        }
                    }
                }
            }
        }
    }

    func sendWelcomeNotification(to userId: String) {
        let notificationData: [String: Any] = [
            "username": self.username,
            "actionText": "Welcome to FROC!",
            "timestamp": FieldValue.serverTimestamp(),
            "icon": "party.popper"
        ]

        db.collection("users").document(userId).collection("notifications").addDocument(data: notificationData) { error in
            if let error = error {
                print("Error sending welcome notification: \(error.localizedDescription)")
            } else {
                sessionStore.sendPushNotification(to: userId, message: "Welcome to FROC!")
                print("Welcome notification sent successfully.")
            }
        }
    }
}
