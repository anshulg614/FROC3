//
//  PostDetailView.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 8/17/24.
//

import Foundation
import SwiftUI
import Firebase

struct PostDetailView: View {
    @EnvironmentObject var postStore: PostStore
    @EnvironmentObject var sessionStore: SessionStore
    @Binding var post: Post
    @State private var showingComments = false
    @State private var showingShippingPayment = false
    @State private var showingMessagesView = false
    @State private var dynamicImageHeight: CGFloat = 475 // Default height for images
    @State private var showingDeleteConfirmation = false // Track the state of the delete confirmation dialog
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            ScrollView {
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
                        Text(post.user.username)
                            .font(.headline)
                        Spacer()
                        Menu {
                            if post.user.id == sessionStore.currentUser?.id {
                                Button(action: {
                                    showingDeleteConfirmation = true // Show the delete confirmation dialog
                                }) {
                                    Label("Delete Post", systemImage: "trash")
                                }
                            } else {
                                // Other menu items
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.title) // Smaller font size
                                .padding()
                                .foregroundColor(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))
                        }
                        .confirmationDialog("Are you sure you want to delete this post?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                            Button("Delete Post", role: .destructive) {
                                deletePost()
                            }
                            Button("Cancel", role: .cancel) {}
                        }
                    }
                    .padding()

                    TabView {
                        ForEach(post.imageUrls, id: \.self) { imageUrl in
                            ZoomableImageView(url: URL(string: imageUrl), frameHeight: dynamicImageHeight)
                                .frame(height: dynamicImageHeight)
                                .onTapGesture {
                                    showingShippingPayment = true
                                }
                        }
                    }
                    .frame(height: dynamicImageHeight)
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    
                    HStack {
                        Button(action: {
                            likePost(post: post)
                        }) {
                            Image(systemName: post.likedBy.contains(sessionStore.currentUser?.id ?? "") ? "heart.fill" : "heart")
                                .foregroundColor(post.likedBy.contains(sessionStore.currentUser?.id ?? "") ? .red : .red)
                        }
                        Button(action: {
                            if !sessionStore.isGuestMode {
                                showingComments = true
                            }
                        }) {
                            Image(systemName: "bubble.left")
                        }
                        Image(systemName: "bookmark")
                        Spacer()
                        Button(action: {
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
                    .padding()
                    
                    Text("\(post.numberOfLikes) likes")
                        .font(.footnote)
                        .padding(.horizontal)
                    
                    Text(post.caption)
                        .padding(.horizontal)
                }
                .padding(.bottom)
                .onTapGesture(count: 2) {
                    likePost(post: post)
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { showingComments },
            set: { showingComments = $0 }
        )) {
            CommentsView(post: $post)
                .environmentObject(postStore)
                .environmentObject(sessionStore)
                .presentationDetents([.medium]) // This line makes the sheet half the screen height
        }
        .sheet(isPresented: Binding(
            get: { showingShippingPayment },
            set: { showingShippingPayment = $0 }
        )) {
            ShippingPaymentView(post: post) // Pass the selected post
                .environmentObject(sessionStore)
        }
    }
    
    private func deletePost() {
        postStore.deletePost(post) { success in
            if success {
                presentationMode.wrappedValue.dismiss() // Dismiss the view if deletion is successful
            } else {
                // Handle the error if needed
            }
        }
    }

    func likePost(post: Post) {
        guard let currentUser = sessionStore.currentUser else { return }
        postStore.toggleLike(post: post, userId: currentUser.id)
    }
}
