//
//  FROC3App.swift
//  FROC3
//
//  Created by Anshul Ganumpally on 3/22/24.
//

import SwiftUI
import Amplify
import AWSCognitoAuthPlugin // Assuming you are using the Cognito plugin

@main
struct FROCApp: App {
    
    init() {
        configureAmplify()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func configureAmplify() {
        do {
            // Add any plugins like `AWSCognitoAuthPlugin()` here
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.configure()
            print("Amplify configured")
        } catch {
            print("Failed to initialize Amplify: \(error)")
        }
    }
}
