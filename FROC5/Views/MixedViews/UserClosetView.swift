//
//  UserClosetView.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 8/17/24.
//

import Foundation
import SwiftUI

struct UserClosetView: View {
    @EnvironmentObject var postStore: PostStore
    @EnvironmentObject var sessionStore: SessionStore
    @EnvironmentObject var userStore: UserStore
    @State private var selectedPost: Post? // To track the selected post for detailed view
    @State private var showingPostDetail = false // To show the post detail view
    @State private var showingFollowersList = false
    @State private var isFollowing = false // Track follow status
    @State private var userFollowersCount = 0 // Track the number of followers
    @State private var showingMenu = false // Track the state of the menu
    @State private var showingBlockConfirmation = false // Track the state of the block
    @State private var showingGuestAlert = false
    @State private var showingFlagConfirmation = false // Track the state of the flag confirmation dialog
    @State private var selectedFlagReason: String? // Track the selected flag reason
    @Environment(\.presentationMode) var presentationMode
    @State private var showingSuccessAlert = false // Show success alert
    @State private var successMessage = "" // Message for success alert
    
    let user: User // User of the closet to display
    
    var body: some View {
        VStack {
            HStack {
                if !user.profilePictureURL.isEmpty,
                   let url = URL(string: user.profilePictureURL) {
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
                    Text("\(user.username)")
                        .font(.headline)
                    Text("Followers: \(user.followers.count) • Rented/Bought: \(user.numberOfBuyRents)")
                        .onTapGesture {
                                showingFollowersList = true
                            }
                }
                Spacer()
                Menu {
                    Button(action: {
                        showingFlagConfirmation = true
                    }) {
                        Label("Flag User", systemImage: "flag")
                    }
                    Button(action: {
                        showingBlockConfirmation = true // Show the block confirmation dialog
                    }) {
                        Label("Block User", systemImage: "hand.raised.fill")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title3) // Smaller font size
                        .padding(.trailing) // Adjust padding to move it more to the right
                        .foregroundColor(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))
                }
                .confirmationDialog("Are you sure you want to block this user?", isPresented: $showingBlockConfirmation, titleVisibility: .visible) {
                    Button("Block User", role: .destructive) {
                        blockUser()
                    }
                    Button("Cancel", role: .cancel) {}
                }
                .confirmationDialog("Why are you flagging this user?", isPresented: $showingFlagConfirmation, titleVisibility: .visible) {
                    Button("Inappropriate images and posts", role: .destructive) {
                        selectedFlagReason = "Inappropriate images and posts"
                        flagUser()
                    }
                    Button("Abusive account", role: .destructive) {
                        selectedFlagReason = "Abusive account"
                        flagUser()
                    }
                    Button("Objectionable content", role: .destructive) {
                        selectedFlagReason = "Objectionable content"
                        flagUser()
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }
            .padding([.top, .leading, .trailing])
            .alert(isPresented: $showingSuccessAlert) {
                Alert(title: Text("Success"), message: Text(successMessage), dismissButton: .default(Text("OK")))
            }
            
            // Follow/Unfollow and Message Buttons
            HStack(spacing: 10) { // Reduced space between buttons
                Spacer()
                if sessionStore.currentUser?.id != user.id {
                    Button(action: {
                        if sessionStore.isGuestMode {
                            showingGuestAlert = true
                        } else {
                            isFollowing.toggle() // Optimistically update UI
                            sessionStore.toggleFollow(user: user) { success in
                                if success {
                                } else {
                                    isFollowing.toggle() // Revert UI update if the action fails
                                }
                            }
                        }
                    }) {
                        Text(isFollowing ? "Following" : "Follow")
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 10)
                            .background(isFollowing ? Color.gray : Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))
                            .cornerRadius(10)
                    }
                }
                Button(action: {
                    if sessionStore.isGuestMode {
                        showingGuestAlert = true
                    } else {
                        // Message action placeholder
                    }
                }) {
                    Text("Message")
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                Spacer()
            }
            .padding(.vertical, 8)
            .alert(isPresented: $showingGuestAlert) {
                Alert(
                    title: Text("Feature Unavailable"),
                    message: Text("You can only access this feature if you make an account."),
                    dismissButton: .default(Text("OK"))
                )
            }

            .padding(.vertical, 8)
            
            // Display the username's closet
            Text("\(user.username)'s Closet")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 8)
            
            ScrollView {
                let columns = [GridItem(.flexible()), GridItem(.flexible())]
                LazyVGrid(columns: columns, spacing: 16) {
                    // Filter posts to show only those by the selected user
                    ForEach(postStore.posts.filter { $0.user.username == user.username }) { post in
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
                updateFollowStatus()
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
                get: { showingFollowersList && user != nil },
                set: { showingFollowersList = $0 }
            )) {
                FollowersListView(user: user)
                    .environmentObject(sessionStore)
                    .environmentObject(userStore)
            }
            .onAppear {
                if let currentUser = sessionStore.currentUser {
                    isFollowing = currentUser.following.contains(user.id)
                    userFollowersCount = user.followers.count
                }
            }
        }
    }
    
    private func blockUser() {
        sessionStore.blockUser(blockedUserId: user.id) { success in
            if success {
                successMessage = "User has been blocked."
                showingSuccessAlert = true
                self.presentationMode.wrappedValue.dismiss()
            }
        }
    }

    private func flagUser() {
        guard let flagReason = selectedFlagReason else { return }
        sessionStore.sendNotificationToAdmin(flaggedUserId: user.id, flagReason: "User marked \(flagReason)") { success in
            if success {
                successMessage = "User has been flagged."
                showingSuccessAlert = true
            }
        }
    }
    
    private func updateFollowStatus() {
        if let currentUser = sessionStore.currentUser,
           let updatedUser = userStore.users.first(where: { $0.id == user.id }) {
            isFollowing = currentUser.following.contains(user.id)
            userFollowersCount = updatedUser.followers.count
        }
    }
    
    private func refreshUserData() {
        userStore.fetchUsers() // Fetch updated users from Firestore
        if let currentUserID = sessionStore.currentUser?.id {
            sessionStore.fetchUserInfo(userId: currentUserID) // Refresh the current user's data
        }
    }
}
