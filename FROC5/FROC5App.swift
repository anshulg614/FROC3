//
//  FROC5App.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 7/4/24.
//

import SwiftUI
import Firebase

@main
struct FROC5App: App {
    
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            let userStore = UserStore()
            ContentView()
                .environmentObject(PostStore())
                .environmentObject(SessionStore(userStore: userStore))
                .environmentObject(userStore)
        }
    }
}
