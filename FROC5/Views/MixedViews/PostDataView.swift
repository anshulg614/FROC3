//
//  PostDetailView.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 8/17/24.
//

import Foundation
import SwiftUI

struct PostDataView: View {
    @EnvironmentObject var postStore: PostStore
    @EnvironmentObject var sessionStore: SessionStore
    @State private var showingComments = false
    @State private var showingShippingPayment = false
    @State private var selectedPost: Post? // Track the selected post
    @State private var showingGuestAlert = false

    let post: Post
    private let imageHeight: CGFloat = 475 // Consistent height for all images

    var body: some View {
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
                            // handle delete post action
                        }) {
                            Label("Delete Post", systemImage: "trash")
                        }
                    } else {
                        Button(action: {
                            selectedPost = post
                            // handle flag post action
                        }) {
                            Label("Flag User", systemImage: "flag")
                        }
                        Button(action: {
                            selectedPost = post
                            // handle block user action
                        }) {
                            Label("Block User", systemImage: "hand.raised.fill")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title2) // Smaller font size
                        .padding()
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
                likePost()
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
                        likePost()
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
        .alert(isPresented: $showingGuestAlert) {
            Alert(
                title: Text("Feature Unavailable"),
                message: Text("You can only access this feature if you make an account."),
                dismissButton: .default(Text("OK"))
            )
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
        .sheet(isPresented: Binding(
            get: { showingShippingPayment && selectedPost != nil },
            set: { showingShippingPayment = $0 }
        )) {
            if let selectedPost = selectedPost {
                ShippingPaymentView(post: selectedPost) // Pass the selected post
            }
        }
    }
    private func likePost() {
        guard let currentUser = sessionStore.currentUser else { return }
        postStore.toggleLike(post: post, userId: currentUser.id)
    }
}
