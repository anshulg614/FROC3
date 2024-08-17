//
//  SignInView.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 8/16/24.
//

import Foundation
import SwiftUI
import Firebase

struct SignInView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            DismissingKeyboardView()
            VStack {
                Text("FROC")
                    .font(.custom("Billabong", size: 80))
                    .padding(.top, 20)
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .padding()
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Button(action: {
                    signIn(email: email, password: password)
                }) {
                    Text("Sign In")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 220, height: 50)
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .padding(.top, 20)
            }
            .padding()
        }
    }
    
    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else if let user = authResult?.user {
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
