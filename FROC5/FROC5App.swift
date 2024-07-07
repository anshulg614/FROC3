//
//  FROC5App.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 7/4/24.
//

import SwiftUI
import Firebase

@UIApplicationMain
class FROC5App: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        return true
    }
}
