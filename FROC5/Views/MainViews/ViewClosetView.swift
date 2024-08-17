//
//  ViewClosetView.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 8/17/24.
//

import Foundation
import SwiftUI

struct ViewClosetsView: View {
    @EnvironmentObject var postStore: PostStore
    @EnvironmentObject var sessionStore: SessionStore
    @Binding var selectedTab: Int
    @State private var showingNotifications = false
    @State private var showingShippingPayment = false
    @State private var selectedPost: Post? // Track the selected post
    @State private var showingComments = false
    @State private var scrollViewProxy: ScrollViewProxy? // Store the scroll view proxy
    @State private var isShowingPostView = false // State to show PostView
    @State private var showingChats = false
    private let imageHeight: CGFloat = 475 // Consistent height for all images
    @State private var showingBlockConfirmation = false // Track the state of the block confirmation dialog
    @State private var showingFlagOptions = false // Track the state of the flag options dialog
    @State private var selectedFlagReason: String = "" // Track the selected flag reason
    @State private var showingSuccessAlert = false // Show success alert
    @State private var successMessage = "" // Message for success alert
    @State private var showingDeleteConfirmation = false // Track the state of the delete confirmation dialog
    @State private var showingGuestAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) { // Adjusted spacing to zero
                HStack {
                    Text("FROC")
                        .font(.custom("Billabong", size: 52)) // Updated font
                        .onTapGesture {
                            if let proxy = scrollViewProxy {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    proxy.scrollTo(postStore.posts.first?.id, anchor: .top) // Smooth scroll to the top
                                }
                            }
                        }

                    Spacer()
                    if sessionStore.isGuestMode {
                        // Disable action for guest mode
                        Button(action: {
                            showingGuestAlert = true
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))
                                .font(.largeTitle) // Adjust the size if needed
                        }
                    } else {
                        NavigationLink(destination: PostView()) {
                            Image(systemName: "plus")
                                .foregroundColor(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))
                                .font(.largeTitle) // Adjust the size if needed
                        }
                    }

                    Button(action: {
                        if sessionStore.isGuestMode {
                            showingGuestAlert = true
                        } else if let userId = sessionStore.currentUser?.id {
                            sessionStore.fetchNotifications(userId: userId)
                            sessionStore.resetNewNotificationCount() // Reset the new notification count
                            self.showingNotifications = true
                        }
                    }) {
                        ZStack {
                            Image(systemName: "bell.fill")
                                .font(.title) // Adjust the size if needed
                                .foregroundColor(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))
                            if sessionStore.newNotificationCount > 0 {
                                BadgeView(count: sessionStore.newNotificationCount)
                                    .offset(x: 10, y: -10)
                            }
                        }
                    }

                    Button(action: {

                    }) {
                        Image(systemName: "message.fill")
                            .font(.title)
                            .foregroundColor(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach($postStore.posts.filter { post in
                                guard let currentUser = sessionStore.currentUser else {
                                    return true
                                }
                                return !currentUser.blockedUsers.contains(post.user.id)
                            }) { $post in
                                VStack(alignment: .leading) {
                                    HStack {
                                        if let url = URL(string: post.user.profilePictureURL) {
                                            AsyncImage(url: url) { phase in
                                                if let image = phase.image {
                                                    image
                                                        .resizable()
                                                        .frame(width: 50, height: 50)
                                                        .clipShape(Circle())
                                                } else if phase.error != nil {
                                                    Color.red.frame(width: 50, height: 50).clipShape(Circle()) // Indicates an error
                                                } else {
                                                    Color.gray.frame(width: 50, height: 50).clipShape(Circle()) // Acts as a placeholder
                                                }
                                            }
                                        } else {
                                            Image(systemName: "person.crop.circle.fill")
                                                .resizable()
                                                .frame(width: 50, height: 50)
                                        }
                                        if post.user.username == sessionStore.currentUser?.username {
                                            NavigationLink(destination: MyClosetView()
                                                .environmentObject(postStore)
                                                .environmentObject(sessionStore)) {
                                                    Text(post.user.username)
                                                        .foregroundColor(.primary)
                                                }
                                        } else {
                                            NavigationLink(destination: UserClosetView(user: post.user)
                                                .environmentObject(postStore)
                                                .environmentObject(sessionStore)) {
                                                    Text(post.user.username)
                                                        .foregroundColor(.primary)
                                                }
                                        }
                                        Spacer()
                                        Menu {
                                            if sessionStore.currentUser?.username == "Admin.Account" || post.user.id == sessionStore.currentUser?.id {
                                                Button(action: {
                                                    selectedPost = post
                                                    showingDeleteConfirmation = true // Show the delete confirmation dialog
                                                }) {
                                                    Label("Delete Post", systemImage: "trash")
                                                }
                                            } else {
                                                Button(action: {
                                                    selectedPost = post
                                                    showingFlagOptions = true // Show the flag options dialog
                                                }) {
                                                    Label("Flag User", systemImage: "flag")
                                                }
                                                Button(action: {
                                                    selectedPost = post
                                                    showingBlockConfirmation = true // Show the block confirmation dialog
                                                }) {
                                                    Label("Block User", systemImage: "hand.raised.fill")
                                                }
                                            }
                                        } label: {
                                            Image(systemName: "ellipsis")
                                                .font(.title2) // Smaller font size
                                                .padding()
                                        }
                                        .confirmationDialog("Are you sure you want to delete this post?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                                            Button("Delete Post", role: .destructive) {
                                                deletePost()
                                            }
                                            Button("Cancel", role: .cancel) {}
                                        }
                                        .confirmationDialog("Select a reason for flagging this user", isPresented: $showingFlagOptions, titleVisibility: .visible) {
                                            Button("Inappropriate images and posts") {
                                                flagUser(reason: "Inappropriate images and posts")
                                            }
                                            Button("Abusive account") {
                                                flagUser(reason: "Abusive account")
                                            }
                                            Button("Objectionable content") {
                                                flagUser(reason: "Objectionable content")
                                            }
                                            Button("Cancel", role: .cancel) {}
                                        }
                                    }
                                    .padding(.horizontal)

                                    TabView {
                                        ForEach(post.imageUrls, id: \.self) { imageUrl in
                                            if let url = URL(string: imageUrl) {
                                                ZoomableImageView(url: url, frameHeight: imageHeight)
                                                    .frame(height: imageHeight)
                                            } else {
                                                Color.gray // Acts as a placeholder if URL is invalid
                                                    .frame(height: imageHeight)
                                            }
                                        }
                                    }
                                    .frame(height: imageHeight)
                                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                                    .onTapGesture(count: 2) {
                                        likePost(post: post)
                                    }
                                    .onTapGesture {
                                        selectedPost = post
                                        showingShippingPayment = true
                                    }
                                    HStack {
                                        Button(action: {
                                            if sessionStore.isGuestMode {
                                                showingGuestAlert = true
                                            } else {
                                                likePost(post: post)
                                            }
                                        }) {
                                            Image(systemName: post.likedBy.contains(sessionStore.currentUser?.id ?? "") ? "heart.fill" : "heart")
                                                .foregroundColor(.red)
                                        }

                                        Button(action: {
                                            if sessionStore.isGuestMode {
                                                showingGuestAlert = true
                                            } else {
                                                selectedPost = post
                                                showingComments = true
                                            }
                                        }) {
                                            Image(systemName: "bubble.left")
                                                .foregroundColor(.blue)
                                        }
                                        Image(systemName: "bookmark")
                                        Spacer()

                                        Button(action: {
                                            selectedPost = post
                                            showingShippingPayment = true
                                        }) {
                                            Text("Product Info")
                                                .bold()
                                                .padding(.vertical, 6)
                                                .padding(.horizontal, 36)
                                                .foregroundColor(.white)
                                                .background(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))
                                                .cornerRadius(10)
                                        }
                                        .frame(width: 180)
                                    }
                                    .padding(.horizontal)

                                    Text("\(post.numberOfLikes) likes")
                                        .font(.footnote) // Adjust the font size to make it smaller
                                        .padding(.horizontal)

                                    Text(post.caption)
                                        .padding(.horizontal)
                                }
                                .padding(.bottom)
                                .id(post.id) // Assign an ID for scrolling
                                .gesture(DragGesture(minimumDistance: 30, coordinateSpace: .local)
                                    .onEnded { value in
                                        if value.translation.width > 50 { // Swipe right
                                            if sessionStore.isGuestMode {
                                                showingGuestAlert = true
                                            } else {
                                                isShowingPostView = true
                                            }
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .alert(isPresented: $showingSuccessAlert) {
                        Alert(title: Text("Success"), message: Text(successMessage), dismissButton: .default(Text("OK")))
                    }
                    .alert(isPresented: $showingGuestAlert) {
                        Alert(
                            title: Text("Feature Unavailable"),
                            message: Text("You can only access this feature if you make an account."),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                    .onAppear {
                        self.scrollViewProxy = proxy
                    }
                }
                .refreshable {
                    postStore.refreshData()
                    if let userId = sessionStore.currentUser?.id {
                        sessionStore.fetchNotifications(userId: userId)
                    }
                }

                Spacer()
                if sessionStore.isGuestMode {
                    Button(action: {
                        sessionStore.signOut()
                        print("exited guest")
                    }) {
                        Text("Guest Mode: Sign Up")
                            .padding()
                            .background(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    .padding()
                }
            }

            .sheet(isPresented: $showingNotifications, onDismiss: {
                sessionStore.newNotificationCount = 0 // Reset the notification count when the notifications view is dismissed
            }) {
                NavigationView {
                    NotificationsView(showingNotifications: $showingNotifications)
                        .environmentObject(sessionStore) // Ensure sessionStore is passed to NotificationsView
                }
            }
            .sheet(isPresented: Binding(
                get: { showingShippingPayment && selectedPost != nil },
                set: { showingShippingPayment = $0 }
            )) {
                if let selectedPost = selectedPost {
                    ShippingPaymentView(post: selectedPost) // Pass the selected post
                }
            }
            .sheet(isPresented: Binding(
                get: { showingComments && selectedPost != nil },
                set: { showingComments = $0 }
            )) {
                if let selectedPost = selectedPost {
                    CommentsView(post: .constant(selectedPost)) // Show comments for the selected post
                        .environmentObject(postStore)
                        .environmentObject(sessionStore)
                        .presentationDetents([.medium]) // This line makes the sheet half the screen height
                }
            }
            .sheet(isPresented: $isShowingPostView) {
                PostView()
                    .environmentObject(postStore)
                    .environmentObject(sessionStore)
            }
        }
    }

    private func blockUser() {
        guard let post = selectedPost else {
            print("Selected post is nil")
            return
        }
        sessionStore.blockUser(blockedUserId: post.user.id) { success in
            if success {
                successMessage = "Post has been blocked."
                showingSuccessAlert = true
            }
        }
    }

    private func flagUser(reason: String) {
        guard let post = selectedPost else {
            print("Selected post is nil")
            return
        }
        sessionStore.sendNotificationToAdmin(flaggedUserId: post.user.id, flagReason: "Post marked \(reason)") { success in
            if success {
                successMessage = "Post has been flagged."
                showingSuccessAlert = true
            }
        }
    }

    private func deletePost() {
        guard let post = selectedPost else {
            print("Selected post is nil")
            return
        }
        postStore.deletePost(post) { success in
            if success {
                successMessage = "Post has been deleted."
                showingSuccessAlert = true
                selectedPost = nil // Clear the selected post
            }
        }
    }

    func likePost(post: Post) {
        guard let currentUser = sessionStore.currentUser else { return }
        postStore.toggleLike(post: post, userId: currentUser.id)
    }
}

struct BadgeView: View {
    var count: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.red)
                .frame(width: 24, height: 24)
            Text("\(count)")
                .foregroundColor(.white)
                .font(.caption)
        }
        .opacity(count > 0 ? 1 : 0) // Hide if count is 0
    }
}
