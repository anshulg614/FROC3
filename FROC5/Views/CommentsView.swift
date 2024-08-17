//
//  CommentsView.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 8/17/24.
//

import Foundation
import Firebase
import SwiftUI

struct CommentsView: View {
    @EnvironmentObject var postStore: PostStore
    @EnvironmentObject var sessionStore: SessionStore
    @Binding var post: Post
    @State private var newCommentText: String = ""
    @State private var comments: [Comment] = []
    
    var body: some View {
        VStack {
            Text("Comments")
                .font(.headline)
                .padding(.top)
            
            ScrollView {
                ForEach(comments) { comment in
                    HStack {
                        if let url = URL(string: comment.profilePictureURL) {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                }
                            }
                        }
                        VStack(alignment: .leading) {
                            Text(comment.username)
                                .bold()
                            Text(comment.text)
                        }
                        Spacer()
                    }
                    .padding()
                }
            }
            .onAppear {
                postStore.fetchComments(for: post.id) { comments in
                    self.comments = comments
                }
            }
            
            HStack {
                TextField("Add a comment...", text: $newCommentText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: {
                    guard let currentUser = sessionStore.currentUser else { return }
                    let comment = Comment(
                        id: UUID().uuidString,
                        userId: currentUser.id,
                        username: currentUser.username,
                        profilePictureURL: currentUser.profilePictureURL,
                        text: newCommentText,
                        timestamp: Timestamp()
                    )
                    postStore.addComment(to: post.id, comment: comment, commenter: currentUser)
                    comments.append(comment)
                    newCommentText = ""
                }) {
                    Text("Post")
                        .bold()
                        .foregroundColor(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))
                }
            }
            .padding()
        }
        .padding()
    }
}

