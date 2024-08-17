//
//  FollowersListView.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 8/17/24.
//

import Foundation
import SwiftUI

struct FollowersListView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @EnvironmentObject var userStore: UserStore
    let user: User
    @State private var selectedUser: User? // To track the selected user for UserClosetView
    
    var body: some View {
        NavigationView {
            List(user.followers, id: \.self) { followerId in
                if let follower = userStore.users.first(where: { $0.id == followerId }) {
                    NavigationLink(destination: UserClosetView(user: follower)
                        .environmentObject(sessionStore)
                        .environmentObject(userStore)
                        .navigationBarTitleDisplayMode(.inline) // Ensure the title is displayed inline
                    ) {
                        HStack {
                            if let url = URL(string: follower.profilePictureURL) {
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
                            Text(follower.username)
                                .foregroundColor(.primary) // Make the text color match the primary color
                        }
                    }
                }
            }
            .navigationTitle("Followers")
            .onAppear {
                userStore.fetchUsers() // Ensure this is called to refresh users
            }
        }
    }
}
