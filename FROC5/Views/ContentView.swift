//
//  ContentView.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 7/4/24.
//

import PhotosUI
import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import FirebaseMessaging
import WebKit
import Foundation
import JWTKit

struct ContentView: View {
    @StateObject private var postStore = PostStore()
    @StateObject private var userStore = UserStore()
    @StateObject private var sessionStore: SessionStore
    
    init() {
        let userStore = UserStore()
        _userStore = StateObject(wrappedValue: userStore)
        _sessionStore = StateObject(wrappedValue: SessionStore(userStore: userStore))
    }
    
    @State private var showingSignUp = false
    @State private var showingSignIn = false
    @State private var errorMessage: String?
    
    var body: some View {
        if sessionStore.isSignedIn {
            SignedInView()
                .environmentObject(postStore)
                .environmentObject(sessionStore)
                .environmentObject(userStore)
        } else {
            AuthenticationView(showingSignUp: $showingSignUp, showingSignIn: $showingSignIn, errorMessage: $errorMessage)
                .environmentObject(sessionStore)
                .environmentObject(userStore)
        }
    }
}

//ctrl + i to format code
// pink: E68AE6
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


