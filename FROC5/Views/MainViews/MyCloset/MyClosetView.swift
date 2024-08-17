//
//  MyClosetView.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 8/17/24.
//

import Foundation
import SwiftUI

struct MyClosetView: View {
    @EnvironmentObject var postStore: PostStore
    @EnvironmentObject var sessionStore: SessionStore
    @EnvironmentObject var userStore: UserStore
    @State private var showingSettings = false
    @State private var selectedPost: Post? // To track the selected post for detailed view
    @State private var showingPostDetail = false // To show the post detail view
    @State private var showingFollowersList = false
    
    var body: some View {
        VStack {
            HStack {
                if let profilePictureURL = sessionStore.currentUser?.profilePictureURL,
                   let url = URL(string: profilePictureURL) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                        }
                    }
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(sessionStore.currentUser?.username ?? "") ")
                        .font(.headline)

                    Text("Followers: \(sessionStore.currentUser?.followers.count ?? 0) • Rented/Bought: \(sessionStore.currentUser?.numberOfBuyRents ?? 0)")
                        .onTapGesture {
                                showingFollowersList = true
                            }
                        
                }
                Spacer()
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "ellipsis")
                        .font(.title3)
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
                        .environmentObject(sessionStore)
                }
            }
            .padding([.top, .leading, .trailing])
            
            // Display the username's closet
            VStack(spacing: 0) { // Use VStack to stack the HStack and the Divider
                HStack {
                    Text("\(sessionStore.currentUser?.firstName ?? "")'s Closet")
                    Image(systemName: "hanger") // Using the system icon for a hanger
                        .foregroundColor(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0)) // Adjust color as needed
                }
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
                
                Divider()
                    .frame(height: 1.5) // Adjust the thickness of the line
                    .background(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0)) // Adjust color as needed
                    .padding(.top, 10) // Adjust spacing as needed
            }
            
            ScrollView {
                let columns = [GridItem(.flexible()), GridItem(.flexible())]
                LazyVGrid(columns: columns, spacing: 16) {
                    // Filter posts to show only those by the current user
                    ForEach(postStore.posts.filter { $0.user.username == sessionStore.currentUser?.username }) { post in
                        // Use Button to handle post click
                        Button(action: {
                            selectedPost = post
                            showingPostDetail = true
                        }) {
                            Rectangle()
                                .foregroundColor(.gray)
                                .aspectRatio(1, contentMode: .fit)
                                .overlay(
                                    AsyncImage(url: URL(string: post.imageUrls.first ?? "")) { phase in
                                        if let image = phase.image {
                                            image.resizable().scaledToFill().clipped()
                                        } else {
                                            Image(systemName: "photo")
                                                .resizable()
                                                .scaledToFill()
                                                .clipped()
                                        }
                                    }
                                )
                        }
                        .clipped()
                    }
                }
                .padding(.horizontal)
            }
            .refreshable {
                refreshUserData()
            }
        }
        .sheet(isPresented: Binding(
            get: { showingPostDetail && selectedPost != nil },
            set: { showingPostDetail = $0 }
        )) {
            if let selectedPost = selectedPost {
                PostDetailView(post: .constant(selectedPost))
                    .environmentObject(postStore)
                    .environmentObject(sessionStore)
            }
        }
        .sheet(isPresented: Binding(
            get: { showingFollowersList && sessionStore.currentUser != nil },
            set: { showingFollowersList = $0 }
        )) {
            if let currentUser = sessionStore.currentUser {
                FollowersListView(user: currentUser)
                    .environmentObject(sessionStore)
                    .environmentObject(userStore)
            }
        }
    }
    
    private func refreshUserData() {
        if let currentUserID = sessionStore.currentUser?.id {
            sessionStore.fetchUserInfo(userId: currentUserID) // Refresh the current user's data
        }
        postStore.refreshData() // Refresh the posts data
    }
}

struct MyClosetView_Previews: PreviewProvider {
    static var previews: some View {
        MyClosetView()
    }
}
