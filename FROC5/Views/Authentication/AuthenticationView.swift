//
//  AuthenticationView.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 8/16/24.
//

import Foundation
import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @Binding var showingSignUp: Bool
    @Binding var showingSignIn: Bool
    @Binding var errorMessage: String?

    var body: some View {
        VStack {
            Spacer()

            Text("FROC")
                .font(.custom("Billabong", size: 80))
                .padding(.top, 30)

            Button(action: {
                showingSignUp = true
            }) {
                Text("Sign Up")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 220, height: 50)
                    .background(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))
                    .cornerRadius(10)
            }
            .padding(.bottom, 10)
            .sheet(isPresented: $showingSignUp) {
                SignUpView()
            }

            Button(action: {
                showingSignIn = true
            }) {
                Text("Sign In")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 220, height: 50)
                    .background(Color.green)
                    .cornerRadius(10)
            }
            .sheet(isPresented: $showingSignIn) {
                SignInView()
            }

            Button(action: {
                sessionStore.signInAsGuest()
            }) {
                Text("Continue as Guest")
                    .font(.footnote)
                    .foregroundColor(.blue)
            }
            .padding(.top, 10)

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }

            Spacer()

            Text("© FROC 2024 ©")
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(.bottom, 20)
        }
        .padding()
    }
}
