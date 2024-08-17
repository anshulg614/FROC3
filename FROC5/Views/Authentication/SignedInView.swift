//
//  SignedInView.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 8/16/24.
//

import Foundation
import SwiftUI

struct SignedInView: View {
    @EnvironmentObject var postStore: PostStore
    @EnvironmentObject var sessionStore: SessionStore
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ViewClosetsView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "eye.fill")
                    Text("View Closets")
                        .foregroundColor(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))
                }
                .environmentObject(postStore)
                .environmentObject(sessionStore)
            
            if !sessionStore.isGuestMode {
                SearchView()
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                        Text("Search Closets")
                            .foregroundColor(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))
                    }
                    .environmentObject(postStore)
                    .environmentObject(sessionStore)
                MyClosetView()
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("My Closet")
                            .foregroundColor(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))
                    }
                    .environmentObject(postStore)
                    .environmentObject(sessionStore)
            }
        }
        .accentColor(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0)) // This changes the tint color of the tab bar icons
    }
}
