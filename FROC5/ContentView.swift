//
//  ContentView.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 7/4/24.
//

import PhotosUI
import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

struct ContentView: View {
    @StateObject private var postStore = PostStore()
    @StateObject private var userStore = UserStore()
    @StateObject private var sessionStore: SessionStore

    init() {
        let userStore = UserStore()
        _userStore = StateObject(wrappedValue: userStore)
        _sessionStore = StateObject(wrappedValue: SessionStore(userStore: userStore))
    }

    @State private var showingSignUp = false
    @State private var showingSignIn = false
    @State private var errorMessage: String?

    var body: some View {
        if sessionStore.isSignedIn {
            SignedInView()
                .environmentObject(postStore)
                .environmentObject(sessionStore)
                .environmentObject(userStore)
        } else {
            VStack {
                Button("Sign Up") {
                    showingSignUp = true
                }
                .padding()
                .sheet(isPresented: $showingSignUp) {
                    SignUpView()
                        .environmentObject(sessionStore)
                        .environmentObject(userStore)
                }

                Button("Sign In") {
                    showingSignIn = true
                }
                .padding()
                .sheet(isPresented: $showingSignIn) {
                    SignInView()
                        .environmentObject(sessionStore)
                        .environmentObject(userStore)
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .padding()
        }
    }
}

struct SignUpView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @Environment(\.presentationMode) var presentationMode
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var username: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var address: String = ""
    @State private var errorMessage: String?

    private var db = Firestore.firestore()

    var body: some View {
        VStack {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding()

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("First Name", text: $firstName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Last Name", text: $lastName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Address", text: $address)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }

            Button("Sign Up") {
                signUp(email: email, password: password)
            }
            .padding()
        }
        .padding()
    }

    func signUp(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else if let user = authResult?.user {
                let userData: [String: Any] = [
                    "username": self.username,
                    "email": email,
                    "firstName": self.firstName,
                    "lastName": self.lastName,
                    "address": self.address
                ]
                self.db.collection("users").document(user.uid).setData(userData) { error in
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                    } else {
                        self.sessionStore.isSignedIn = true
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct SignInView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding()

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }

            Button("Sign In") {
                signIn(email: email, password: password)
            }
            .padding()
        }
        .padding()
    }

    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else {
                self.sessionStore.isSignedIn = true
                self.presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

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
                }
                .tag(0)
                .environmentObject(postStore)
                .environmentObject(sessionStore)

            MyClosetView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("My Closet")
                }
                .tag(1)
                .environmentObject(postStore)
                .environmentObject(sessionStore)
        }
    }
}

class UserStore: ObservableObject {
    @Published var users: [User] = []

    private var db = Firestore.firestore()
    private var storageRef = Storage.storage().reference()

    func fetchUsers() {
        db.collection("users").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching users: \(error.localizedDescription)")
            } else {
                self.users = snapshot?.documents.compactMap { document -> User? in
                    let data = document.data()
                    let notificationsData = data["notifications"] as? [[String: Any]] ?? []
                    let notifications = notificationsData.compactMap { dict -> NotificationItem? in
                        guard let typeString = dict["type"] as? String,
                              let type = NotificationItem.NotificationType(rawValue: typeString),
                              let username = dict["username"] as? String,
                              let actionText = dict["actionText"] as? String,
                              let timestampString = dict["timestamp"] as? String,
                              let productInfo = dict["productInfo"] as? String,
                              let price = dict["price"] as? Double,
                              let size = dict["size"] as? String,
                              let duration = dict["duration"] as? String,
                              let name = dict["name"] as? String,
                              let address = dict["address"] as? String,
                              let imageUrls = dict["imageUrls"] as? [String],
                              let shipImageUrl = dict["shipImageUrl"] as? String,
                              let icon = dict["icon"] as? String,
                              let buyerData = dict["buyer"] as? [String: Any] else {
                            return nil
                        }

                        let dateFormatter = ISO8601DateFormatter()
                        guard let timestamp = dateFormatter.date(from: timestampString),
                              let buyerId = buyerData["id"] as? String,
                              let buyerUsername = buyerData["username"] as? String,
                              let buyerEmail = buyerData["email"] as? String,
                              let buyerFirstName = buyerData["firstName"] as? String,
                              let buyerLastName = buyerData["lastName"] as? String,
                              let buyerAddress = buyerData["address"] as? String,
                              let buyerProfilePictureURL = buyerData["profilePictureURL"] as? String,
                              let buyerFollowers = buyerData["followers"] as? [String],
                              let buyerNumberOfBuyRents = buyerData["numberOfBuyRents"] as? Int else {
                            return nil
                        }

                        let buyer = User(
                            id: buyerId,
                            username: buyerUsername,
                            email: buyerEmail,
                            firstName: buyerFirstName,
                            lastName: buyerLastName,
                            address: buyerAddress,
                            profilePictureURL: buyerProfilePictureURL,
                            followers: buyerFollowers,
                            numberOfBuyRents: buyerNumberOfBuyRents
                        )

                        return NotificationItem(
                            id: UUID().uuidString,
                            icon: icon,
                            type: type,
                            username: username,
                            actionText: actionText,
                            timestamp: timestamp,
                            productInfo: productInfo,
                            price: price,
                            size: size,
                            duration: duration,
                            name: name,
                            address: address,
                            imageUrls: imageUrls,
                            shipImageUrl: shipImageUrl,
                            buyer: buyer
                        )
                    }
                    return User(
                        id: document.documentID,
                        username: data["username"] as? String ?? "",
                        email: data["email"] as? String ?? "",
                        firstName: data["firstName"] as? String ?? "",
                        lastName: data["lastName"] as? String ?? "",
                        address: data["address"] as? String ?? "",
                        profilePictureURL: data["profilePictureURL"] as? String ?? "",
                        followers: data["followers"] as? [String] ?? [],
                        following: data["following"] as? [String] ?? [],
                        numberOfBuyRents: data["numberOfBuyRents"] as? Int ?? 0,
                        notifications: notifications
                    )
                } ?? []
            }
        }
    }

    func updateUser(_ user: User, completion: @escaping (Error?) -> Void) {
        let notificationsData = user.notifications.map { notification -> [String: Any] in
            let buyerData: [String: Any] = [
                "id": notification.buyer.id,
                "username": notification.buyer.username,
                "email": notification.buyer.email,
                "firstName": notification.buyer.firstName,
                "lastName": notification.buyer.lastName,
                "address": notification.buyer.address,
                "profilePictureURL": notification.buyer.profilePictureURL,
                "followers": notification.buyer.followers,
                "numberOfBuyRents": notification.buyer.numberOfBuyRents
            ]
            
            return [
                "id": notification.id,
                "icon": notification.icon,
                "type": notification.type.rawValue,
                "username": notification.username,
                "actionText": notification.actionText,
                "timestamp": ISO8601DateFormatter().string(from: notification.timestamp),
                "productInfo": notification.productInfo,
                "price": notification.price,
                "size": notification.size,
                "duration": notification.duration,
                "name": notification.name,
                "address": notification.address,
                "imageUrls": notification.imageUrls,
                "shipImageUrl": notification.shipImageUrl,
                "buyer": buyerData
            ]
        }

        let userData: [String: Any] = [
            "username": user.username,
            "email": user.email,
            "firstName": user.firstName,
            "lastName": user.lastName,
            "address": user.address,
            "profilePictureURL": user.profilePictureURL,
            "followers": user.followers,
            "following": user.following,
            "numberOfBuyRents": user.numberOfBuyRents,
            "notifications": notificationsData
        ]
        db.collection("users").document(user.id).setData(userData) { error in
            if let error = error {
                print("Error updating user data: \(error.localizedDescription)")
            }
            completion(error)
        }
    }

    func toggleFollow(currentUser: User, user: User, completion: @escaping (Bool) -> Void) {
        var currentUser = currentUser
        let user = user

        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let currentUserRef = self.db.collection("users").document(currentUser.id)
            let userRef = self.db.collection("users").document(user.id)

            do {
                let currentUserDocument = try transaction.getDocument(currentUserRef)
                let userDocument = try transaction.getDocument(userRef)

                guard let currentUserData = currentUserDocument.data(),
                      let userData = userDocument.data() else {
                    return nil
                }

                var currentUserFollowing = currentUserData["following"] as? [String] ?? []
                var userFollowers = userData["followers"] as? [String] ?? []

                if currentUserFollowing.contains(user.id) {
                    currentUserFollowing.removeAll { $0 == user.id }
                    userFollowers.removeAll { $0 == currentUser.id }
                } else {
                    currentUserFollowing.append(user.id)
                    userFollowers.append(currentUser.id)
                }

                transaction.updateData(["following": currentUserFollowing], forDocument: currentUserRef)
                transaction.updateData(["followers": userFollowers], forDocument: userRef)

                currentUser.following = currentUserFollowing

                // Update currentUser in Firestore
                self.updateUser(currentUser) { error in
                    if let error = error {
                        print("Error updating current user: \(error.localizedDescription)")
                        completion(false)
                        return
                    }

                    // Update user in Firestore
                    if let index = self.users.firstIndex(where: { $0.id == user.id }) {
                        self.users[index].followers = userFollowers
                        self.updateUser(self.users[index]) { error in
                            if let error = error {
                                print("Error updating user: \(error.localizedDescription)")
                                completion(false)
                            } else {
                                completion(true)
                            }
                        }
                    } else {
                        completion(true)
                    }
                }

            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
            return nil
        }) { (_, error) in
            if let error = error {
                print("Error toggling follow: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }

    func uploadProfileImage(image: UIImage, completion: @escaping (URL?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.75) else { return }
        let imageRef = storageRef.child("profile_pictures/\(UUID().uuidString).jpg")
        imageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("Error uploading profile image: \(error.localizedDescription)")
                completion(nil)
            } else {
                imageRef.downloadURL { url, error in
                    if let error = error {
                        print("Error getting download URL: \(error.localizedDescription)")
                        completion(nil)
                    } else {
                        completion(url)
                    }
                }
            }
        }
    }
}


class SessionStore: ObservableObject {
    @Published var isSignedIn: Bool = false
    @Published var currentUser: User?
    @ObservedObject var userStore: UserStore

    private var db = Firestore.firestore()
    private var storageRef = Storage.storage().reference()

    init(userStore: UserStore) {
        self.userStore = userStore
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.isSignedIn = true
                self?.fetchUserInfo(userId: user.uid)
            } else {
                self?.isSignedIn = false
                self?.currentUser = nil
            }
        }
    }

    func fetchUserInfo(userId: String) {
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists, let data = document.data() {
                let profilePictureURL = data["profilePictureURL"] as? String ?? ""
                let followers = data["followers"] as? [String] ?? []
                let following = data["following"] as? [String] ?? []
                let notificationsData = data["notifications"] as? [[String: Any]] ?? []
                let notifications = notificationsData.compactMap { dict -> NotificationItem? in
                    guard let typeString = dict["type"] as? String,
                          let type = NotificationItem.NotificationType(rawValue: typeString),
                          let username = dict["username"] as? String,
                          let actionText = dict["actionText"] as? String,
                          let timestampString = dict["timestamp"] as? String,
                          let productInfo = dict["productInfo"] as? String,
                          let price = dict["price"] as? Double,
                          let size = dict["size"] as? String,
                          let duration = dict["duration"] as? String,
                          let name = dict["name"] as? String,
                          let address = dict["address"] as? String,
                          let imageUrls = dict["imageUrls"] as? [String],
                          let shipImageUrl = dict["shipImageUrl"] as? String,
                          let icon = dict["icon"] as? String,
                          let buyerData = dict["buyer"] as? [String: Any] else {
                        return nil
                    }

                    let dateFormatter = ISO8601DateFormatter()
                    guard let timestamp = dateFormatter.date(from: timestampString) else {
                        return nil
                    }

                    let buyer = User(
                        id: buyerData["id"] as? String ?? "",
                        username: buyerData["username"] as? String ?? "",
                        email: buyerData["email"] as? String ?? "",
                        firstName: buyerData["firstName"] as? String ?? "",
                        lastName: buyerData["lastName"] as? String ?? "",
                        address: buyerData["address"] as? String ?? "",
                        profilePictureURL: buyerData["profilePictureURL"] as? String ?? "",
                        followers: buyerData["followers"] as? [String] ?? [],
                        numberOfBuyRents: buyerData["numberOfBuyRents"] as? Int ?? 0
                    )

                    return NotificationItem(
                        id: UUID().uuidString,
                        icon: icon,
                        type: type,
                        username: username,
                        actionText: actionText,
                        timestamp: timestamp,
                        productInfo: productInfo,
                        price: price,
                        size: size,
                        duration: duration,
                        name: name,
                        address: address,
                        imageUrls: imageUrls,
                        shipImageUrl: shipImageUrl,
                        buyer: buyer
                    )
                }
                self.currentUser = User(
                    id: document.documentID,
                    username: data["username"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    firstName: data["firstName"] as? String ?? "",
                    lastName: data["lastName"] as? String ?? "",
                    address: data["address"] as? String ?? "",
                    profilePictureURL: profilePictureURL,
                    followers: followers,
                    following: following,
                    notifications: notifications
                )
                self.fetchProfileImage(profilePictureURL: profilePictureURL)
                self.fetchNotifications(userId: userId) // Ensure to fetch notifications
            } else {
                print("Document does not exist")
            }
        }
    }

    func fetchProfileImage(profilePictureURL: String) {
        guard !profilePictureURL.isEmpty else { return }
        let imageRef = storageRef.child(profilePictureURL)
        imageRef.getData(maxSize: Int64(1 * 1024 * 1024)) { data, error in
            if let error = error {
                print("Error fetching profile image: \(error.localizedDescription)")
            } else if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.currentUser?.profilePicture = image
                }
            }
        }
    }

    func fetchNotifications(userId: String) {
        db.collection("users").document(userId).collection("notifications").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching notifications: \(error.localizedDescription)")
            } else {
                guard let documents = snapshot?.documents else {
                    print("No notification documents found")
                    return
                }

                print("Fetched \(documents.count) notification documents")

                let notifications = documents.compactMap { document -> NotificationItem? in
                    let data = document.data()
                    
                    print("Notification document data: \(data)")

                    let typeString = data["type"] as? String ?? "unknown"
                    let type = NotificationItem.NotificationType(rawValue: typeString) ?? .comment

                    let username = data["username"] as? String ?? "Unknown User"
                    let actionText = data["actionText"] as? String ?? "Unknown Action"
                    let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    let productInfo = data["productInfo"] as? String ?? "Unknown Product"
                    let price = data["price"] as? Double ?? 0.0
                    let size = data["size"] as? String ?? "Unknown Size"
                    let duration = data["duration"] as? String ?? "Unknown Duration"
                    let name = data["name"] as? String ?? "Unknown Name"
                    let address = data["address"] as? String ?? "Unknown Address"
                    let imageUrls = data["imageUrls"] as? [String] ?? ["Unknown URL"]
                    let shipImageUrl = data["shipImageUrl"] as? String ?? ""
                    let icon = data["icon"] as? String ?? "default_icon"

                    let buyerData = data["buyer"] as? [String: Any] ?? [:]

                    let buyer = User(
                        id: buyerData["id"] as? String ?? "Unknown Buyer ID",
                        username: buyerData["username"] as? String ?? "Unknown Buyer Username",
                        email: buyerData["email"] as? String ?? "Unknown Buyer Email",
                        firstName: buyerData["firstName"] as? String ?? "Unknown Buyer First Name",
                        lastName: buyerData["lastName"] as? String ?? "Unknown Buyer Last Name",
                        address: buyerData["address"] as? String ?? "Unknown Buyer Address",
                        profilePictureURL: buyerData["profilePictureURL"] as? String ?? "Unknown Buyer Profile URL",
                        followers: buyerData["followers"] as? [String] ?? [],
                        numberOfBuyRents: buyerData["numberOfBuyRents"] as? Int ?? 0
                    )

                    print("Parsed NotificationItem successfully")

                    return NotificationItem(
                        id: document.documentID,
                        icon: icon,
                        type: type,
                        username: username,
                        actionText: actionText,
                        timestamp: timestamp,
                        productInfo: productInfo,
                        price: price,
                        size: size,
                        duration: duration,
                        name: name,
                        address: address,
                        imageUrls: imageUrls,
                        shipImageUrl: shipImageUrl,
                        buyer: buyer
                    )
                }

                print("Parsed notifications: \(notifications)")

                DispatchQueue.main.async {
                    self.currentUser?.notifications = notifications
                    print("Notifications updated")
                }
            }
        }
    }

    func toggleFollow(user: User, completion: @escaping (Bool) -> Void) {
        guard let currentUser = currentUser else { return }
        userStore.toggleFollow(currentUser: currentUser, user: user) { success in
            if success {
                self.currentUser = currentUser
                completion(true)
            } else {
                completion(false)
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            isSignedIn = false
            currentUser = nil
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}


struct ViewClosetsView: View {
    @EnvironmentObject var postStore: PostStore
    @EnvironmentObject var sessionStore: SessionStore
    @Binding var selectedTab: Int
    @State private var showingNotifications = false
    @State private var showingShippingPayment = false
    @State private var selectedPost: Post? // Track the selected post
    @State private var showingComments = false
    @State private var scrollViewProxy: ScrollViewProxy? // Store the scroll view proxy

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) { // Adjusted spacing to zero
                HStack {
                    Text("FROC")
                        .font(.custom("Billabong", size: 52)) // Updated font
                        .onTapGesture {
                            print("to the top")
                            if let proxy = scrollViewProxy {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    proxy.scrollTo(postStore.posts.first?.id, anchor: .top) // Smooth scroll to the top
                                }
                            }
                        }

                    Spacer()
                    NavigationLink(destination: PostView()) {
                        Image(systemName: "plus")
                            .foregroundColor(Color.blue)
                            .font(.largeTitle) // Adjust the size if needed
                    }

                    Button(action: {
                        if let userId = sessionStore.currentUser?.id {
                            sessionStore.fetchNotifications(userId: userId)
                        }
                        self.showingNotifications = true
                    }) {
                        Image(systemName: "bell.fill")
                            .font(.title) // Adjust the size if needed
                    }

                    Image(systemName: "message.fill")
                        .font(.title) // Adjust the size if needed
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach($postStore.posts) { $post in
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
                                        Image(systemName: "arrowshape.turn.up.right")
                                    }
                                    .padding(.horizontal)

                                    TabView {
                                        ForEach(post.imageUrls, id: \.self) { imageUrl in
                                            if let url = URL(string: imageUrl) {
                                                AsyncImage(url: url) { phase in
                                                    if let image = phase.image {
                                                        image
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(maxWidth: .infinity)
                                                    } else if phase.error != nil {
                                                        Color.red // Indicates an error
                                                    } else {
                                                        Color.gray // Acts as a placeholder
                                                    }
                                                }
                                            } else {
                                                Color.gray // Acts as a placeholder if URL is invalid
                                            }
                                        }
                                    }
                                    .frame(height: 300)
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
                                            likePost(post: post)
                                        }) {
                                            Image(systemName: post.likedBy.contains(sessionStore.currentUser?.id ?? "") ? "heart.fill" : "heart")
                                                .foregroundColor(post.likedBy.contains(sessionStore.currentUser?.id ?? "") ? .red : .gray)
                                        }
                                        Button(action: {
                                            selectedPost = post
                                            showingComments = true
                                        }) {
                                            Image(systemName: "bubble.left")
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
                                                .background(Color.blue)
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
                            }
                        }
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
            }
            .sheet(isPresented: $showingNotifications) {
                NavigationView {
                    NotificationsView(showingNotifications: $showingNotifications)
                        .environmentObject(sessionStore) // Ensure sessionStore is passed to NotificationsView
                }
            }
            .sheet(isPresented: $showingShippingPayment) {
                if let selectedPost = selectedPost {
                    ShippingPaymentView(post: selectedPost) // Pass the selected post
                }
            }
            .sheet(isPresented: $showingComments) {
                if let selectedPost = selectedPost {
                    CommentsView(post: .constant(selectedPost)) // Show comments for the selected post
                        .environmentObject(postStore)
                        .environmentObject(sessionStore)
                }
            }
        }
    }

    func likePost(post: Post) {
        guard let currentUser = sessionStore.currentUser else { return }
        postStore.toggleLike(post: post, userId: currentUser.id)
    }
}


struct UserClosetView: View {
    @EnvironmentObject var postStore: PostStore
    @EnvironmentObject var sessionStore: SessionStore
    @EnvironmentObject var userStore: UserStore
    @State private var selectedPost: Post? // To track the selected post for detailed view
    @State private var showingPostDetail = false // To show the post detail view
    @State private var isFollowing = false // Track follow status
    @State private var userFollowersCount = 0 // Track the number of followers
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
                    Text("Followers: \(userFollowersCount) • Rented/Bought: \(user.numberOfBuyRents)")
                }
                Spacer()
            }
            .padding([.top, .leading, .trailing])

            // Follow/Unfollow and Message Buttons
            HStack(spacing: 10) { // Reduced space between buttons
                Spacer()
                if sessionStore.currentUser?.id != user.id {
                    Button(action: {
                        isFollowing.toggle() // Optimistically update UI
                        sessionStore.toggleFollow(user: user) { success in
                            if success {
                            } else {
                                isFollowing.toggle() // Revert UI update if the action fails
                            }
                        }
                    }) {
                        Text(isFollowing ? "Following" : "Follow")
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 10)
                            .background(isFollowing ? Color.gray : Color.blue)
                            .cornerRadius(10)
                    }
                }
                Button(action: {
                    // Message action placeholder
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
        }
        .sheet(isPresented: $showingPostDetail) {
            if let selectedPost = selectedPost {
                PostDetailView(post: .constant(selectedPost))
                    .environmentObject(postStore)
                    .environmentObject(sessionStore)
            }
        }
        .onAppear {
            if let currentUser = sessionStore.currentUser {
                isFollowing = currentUser.following.contains(user.id)
                userFollowersCount = user.followers.count
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

class PostStore: ObservableObject {
    @Published var posts: [Post] = []

    private var db = Firestore.firestore()
    private var storageRef = Storage.storage().reference()

    init() {
        refreshData()
        fetchPosts()
    }

    func fetchPosts() {
        db.collection("posts").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching posts: \(error.localizedDescription)")
            } else {
                if let snapshot = snapshot {
                    let documents = snapshot.documents
                    var posts: [Post] = []

                    let group = DispatchGroup()

                    for document in documents {
                        group.enter()
                        let data = document.data()
                        let imageUrls = data["imageUrls"] as? [String] ?? []
                        let likedBy = data["likedBy"] as? [String] ?? []

                        self.fetchComments(for: document.documentID) { comments in
                            let userId = data["userId"] as? String ?? ""
                            self.fetchUser(for: userId) { user in
                                let post = Post(
                                    id: document.documentID,
                                    user: user,
                                    imageUrls: imageUrls,
                                    caption: data["caption"] as? String ?? "",
                                    saleOption: Post.SaleOption(rawValue: data["saleOption"] as? String ?? "Purchase") ?? .purchase,
                                    purchasePrice: data["purchasePrice"] as? String ?? "",
                                    rentPrice: data["rentPrice"] as? String ?? "",
                                    sizes: data["sizes"] as? [String] ?? [],
                                    description: data["description"] as? String ?? "",
                                    numberOfLikes: data["numberOfLikes"] as? Int ?? 0,
                                    likedBy: likedBy,
                                    comments: comments
                                )
                                posts.append(post)
                                group.leave()
                            }
                        }
                    }

                    group.notify(queue: .main) {
                        self.posts = posts
                    }
                }
            }
        }
    }

    func fetchComments(for postId: String, completion: @escaping ([Comment]) -> Void) {
        db.collection("posts").document(postId).collection("comments").order(by: "timestamp", descending: false).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching comments: \(error.localizedDescription)")
                completion([])
            } else {
                if let snapshot = snapshot {
                    let comments = snapshot.documents.map { document in
                        let data = document.data()
                        return Comment(
                            id: document.documentID,
                            userId: data["userId"] as? String ?? "",
                            username: data["username"] as? String ?? "",
                            profilePictureURL: data["profilePictureURL"] as? String ?? "",
                            text: data["text"] as? String ?? "",
                            timestamp: data["timestamp"] as? Timestamp ?? Timestamp()
                        )
                    }
                    completion(comments)
                } else {
                    completion([])
                }
            }
        }
    }

    func fetchUser(for userId: String, completion: @escaping (User) -> Void) {
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists, let data = document.data() {
                let user = User(
                    id: userId,
                    username: data["username"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    firstName: data["firstName"] as? String ?? "",
                    lastName: data["lastName"] as? String ?? "",
                    address: data["address"] as? String ?? "",
                    profilePictureURL: data["profilePictureURL"] as? String ?? "",
                    followers: data["followers"] as? [String] ?? [], // Corrected to be an array of strings
                    numberOfBuyRents: data["numberOfBuyRents"] as? Int ?? 0
                )
                completion(user)
            } else {
                print("Error fetching user: \(error?.localizedDescription ?? "No data")")
                completion(User(id: userId, username: "", email: "", firstName: "", lastName: "", address: ""))
            }
        }
    }

    private func sendNotification(to userId: String, type: NotificationItem.NotificationType, actionText: String, post: Post, actor: User) {
        let notificationData: [String: Any] = [
            "username": actor.username,
            "type": type.rawValue,
            "actionText": actionText,
            "timestamp": FieldValue.serverTimestamp(),
            "productInfo": post.description,
            "price": post.rentPrice.isEmpty ? Double(post.purchasePrice)! : Double(post.rentPrice)!,
            "size": post.sizes.joined(separator: ", "), // Assuming sizes are array of strings
            "duration": "", // Assuming duration is not relevant for likes and comments
            "name": actor.firstName + " " + actor.lastName,
            "address": "", // Assuming address is not relevant for likes and comments
            "imageUrl": post.imageUrls.first ?? "",
            "icon": type == .comment ? "bubble.right" : "heart" // Icon for comments and likes
        ]

        db.collection("users").document(userId).collection("notifications").addDocument(data: notificationData) { error in
            if let error = error {
                print("Error adding notification: \(error.localizedDescription)")
            } else {
                print("Notification sent to user.")
            }
        }
    }

    func addComment(to postId: String, comment: Comment, commenter: User) {
        let commentData: [String: Any] = [
            "userId": comment.userId,
            "username": comment.username,
            "profilePictureURL": comment.profilePictureURL,
            "text": comment.text,
            "timestamp": comment.timestamp
        ]
        db.collection("posts").document(postId).collection("comments").addDocument(data: commentData) { error in
            if let error = error {
                print("Error adding comment: \(error.localizedDescription)")
            } else {
                // Fetch the post to get the post details and the post owner's ID
                self.db.collection("posts").document(postId).getDocument { document, error in
                    if let document = document, document.exists, let data = document.data() {
                        let userId = data["userId"] as? String ?? ""
                        self.fetchUser(for: userId) { user in
                            let post = Post(
                                id: document.documentID,
                                user: user,
                                imageUrls: data["imageUrls"] as? [String] ?? [],
                                caption: data["caption"] as? String ?? "",
                                saleOption: Post.SaleOption(rawValue: data["saleOption"] as? String ?? "Purchase") ?? .purchase,
                                purchasePrice: data["purchasePrice"] as? String ?? "",
                                rentPrice: data["rentPrice"] as? String ?? "",
                                sizes: data["sizes"] as? [String] ?? [],
                                description: data["description"] as? String ?? "",
                                numberOfLikes: data["numberOfLikes"] as? Int ?? 0,
                                likedBy: data["likedBy"] as? [String] ?? [],
                                comments: [] // Comments will be fetched separately
                            )
                            
                            // Send notification to the post owner
                            self.sendNotification(
                                to: userId,
                                type: .comment,
                                actionText: "commented '\(comment.text)'",
                                post: post,
                                actor: commenter
                            )
                        }
                    }
                }
            }
        }
    }

    func toggleLike(post: Post, userId: String) {
        var updatedPost = post
        
        if updatedPost.likedBy.contains(userId) {
            // Unlike the post
            updatedPost.likedBy.removeAll { $0 == userId }
            updatedPost.numberOfLikes -= 1
        } else {
            // Like the post
            updatedPost.likedBy.append(userId)
            updatedPost.numberOfLikes += 1
            
            // Send notification to the post owner
            self.fetchUser(for: userId) { liker in
                self.sendNotification(
                    to: post.user.id,
                    type: .like,
                    actionText: "liked your post",
                    post: post,
                    actor: liker
                )
            }
        }

        // Update Firestore
        let postData: [String: Any] = [
            "numberOfLikes": updatedPost.numberOfLikes,
            "likedBy": updatedPost.likedBy
        ]

        db.collection("posts").document(updatedPost.id).updateData(postData) { error in
            if let error = error {
                print("Error updating post: \(error.localizedDescription)")
            } else {
                if let index = self.posts.firstIndex(where: { $0.id == updatedPost.id }) {
                    self.posts[index] = updatedPost
                }
            }
        }
    }

    func fetchUserProfilePictures() {
        let userIds = posts.map { $0.user.id }
        let uniqueUserIds = Array(Set(userIds))

        uniqueUserIds.forEach { userId in
            fetchUser(for: userId) { user in
                self.posts = self.posts.map { post in
                    var updatedPost = post
                    if post.user.id == userId {
                        updatedPost.user = user
                    }
                    return updatedPost
                }
            }
        }
    }

    func refreshData() {
        fetchPosts()
        fetchUserProfilePictures()
    }

    func addPost(_ post: Post, images: [UIImage]) {
        let imageRefs = images.map { _ in "posts/\(UUID().uuidString).jpg" }
        let uploadGroup = DispatchGroup()

        var uploadedImageUrls: [String] = []

        for (index, image) in images.enumerated() {
            uploadGroup.enter()
            let imageRef = storageRef.child(imageRefs[index])
            guard let imageData = image.jpegData(compressionQuality: 0.75) else { continue }

            imageRef.putData(imageData, metadata: nil) { _, error in
                if let error = error {
                    print("Error uploading image: \(error.localizedDescription)")
                    uploadGroup.leave()
                } else {
                    imageRef.downloadURL { url, error in
                        if let error = error {
                            print("Error getting download URL: \(error.localizedDescription)")
                        } else if let url = url {
                            uploadedImageUrls.append(url.absoluteString)
                        }
                        uploadGroup.leave()
                    }
                }
            }
        }

        uploadGroup.notify(queue: .main) {
            let postData: [String: Any] = [
                "userId": post.user.id,
                "caption": post.caption,
                "saleOption": post.saleOption.rawValue,
                "purchasePrice": post.purchasePrice,
                "rentPrice": post.rentPrice,
                "description": post.description,
                "numberOfLikes": post.numberOfLikes,
                "likedBy": post.likedBy,
                "imageUrls": uploadedImageUrls,
                "sizes": post.sizes
            ]
            self.db.collection("posts").addDocument(data: postData) { error in
                if let error = error {
                    print("Error adding post: \(error.localizedDescription)")
                } else {
                    self.fetchPosts()
                }
            }
        }
    }
}

struct Comment: Identifiable {
    let id: String
    let userId: String
    let username: String
    let profilePictureURL: String
    let text: String
    let timestamp: Timestamp
}

struct Post: Identifiable {
    let id: String
    var user: User
    var imageUrls: [String]
    var caption: String
    var saleOption: SaleOption
    var purchasePrice: String
    var rentPrice: String
    var sizes: [String]
    var description: String
    var numberOfLikes: Int
    var likedBy: [String]
    var comments: [Comment]

    enum SaleOption: String, CaseIterable, Identifiable {
        case purchase = "Purchase"
        case rent = "Rent"
        case purchaseOrRent = "Purchase or Rent"

        var id: String { self.rawValue }
    }

    init(id: String = UUID().uuidString, user: User, imageUrls: [String] = [], caption: String = "", saleOption: SaleOption = .purchase, purchasePrice: String = "", rentPrice: String = "", sizes: [String] = [], description: String = "", numberOfLikes: Int = 0, likedBy: [String] = [], comments: [Comment] = []) {
        self.id = id
        self.user = user
        self.imageUrls = imageUrls
        self.caption = caption
        self.saleOption = saleOption
        self.purchasePrice = purchasePrice
        self.rentPrice = rentPrice
        self.sizes = sizes
        self.description = description
        self.numberOfLikes = numberOfLikes
        self.likedBy = likedBy
        self.comments = comments
    }
}

struct User: Identifiable, Equatable {
    var id: String
    var username: String
    var email: String
    var firstName: String
    var lastName: String
    var address: String
    var profilePicture: UIImage
    var profilePictureURL: String
    var posts: [Post]
    var followers: [String]
    var following: [String]
    var numberOfBuyRents: Int
    var notifications: [NotificationItem]

    init(id: String = UUID().uuidString, username: String, email: String, firstName: String, lastName: String, address: String, profilePicture: UIImage = UIImage(), profilePictureURL: String = "", posts: [Post] = [], followers: [String] = [], following: [String] = [], numberOfBuyRents: Int = 0, notifications: [NotificationItem] = []) {
        self.id = id
        self.username = username
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.address = address
        self.profilePicture = profilePicture
        self.profilePictureURL = profilePictureURL
        self.posts = posts
        self.followers = followers
        self.following = following
        self.numberOfBuyRents = numberOfBuyRents
        self.notifications = notifications
    }

    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
}


struct PostView: View {
    @State private var selectedImages: [UIImage] = []
    @State private var postCaption: String = "Write a caption..."
    @State private var saleOption: Post.SaleOption = .purchase
    @State private var purchasePrice: String = ""
    @State private var rentPrice: String = ""
    @State private var selectedSizes: [String] = []
    @State private var productDescription: String = "Describe the product..."
    @EnvironmentObject var postStore: PostStore
    @EnvironmentObject var sessionStore: SessionStore
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ScrollView {
            VStack {
                ImageSelectionView(selectedImages: $selectedImages)
                
                TextEditor(text: $postCaption)
                    .frame(height: 80)
                    .padding()
                
                Picker("Options", selection: $saleOption) {
                    ForEach(Post.SaleOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .accentColor(.blue)
                .padding()

                HStack {
                    TextField("Purchase Price", text: $purchasePrice)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 140)

                    TextField("Rent Price (per day)", text: $rentPrice)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 140)
                }
                .padding(.horizontal)
                
                SizeSelectionView(selectedSizes: $selectedSizes)
                    .padding(.horizontal)

                TextEditor(text: $productDescription)
                    .frame(height: 80)
                    .padding()
                
                HStack {
                    Button("Save Draft") {
                        print("works")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(10)
                    
                    Button(action: {
                        guard let currentUser = sessionStore.currentUser else { return }
                        let newPost = Post(
                            user: currentUser,
                            imageUrls: [],
                            caption: postCaption,
                            saleOption: saleOption,
                            purchasePrice: purchasePrice,
                            rentPrice: rentPrice,
                            sizes: selectedSizes,
                            description: productDescription,
                            numberOfLikes: 0,
                            likedBy: [],
                            comments: []
                        )
                        postStore.addPost(newPost, images: selectedImages)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Post")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
            }
        }
    }
}

struct MyClosetView: View {
    @EnvironmentObject var postStore: PostStore
    @EnvironmentObject var sessionStore: SessionStore
    @EnvironmentObject var userStore: UserStore
    @State private var showingSettings = false
    @State private var selectedPost: Post? // To track the selected post for detailed view
    @State private var showingPostDetail = false // To show the post detail view

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
                }
                Spacer()
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "ellipsis")
                        .font(.headline)
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
                        .environmentObject(sessionStore)
                }
            }
            .padding([.top, .leading, .trailing])

            // Display the username's closet
            Text("\(sessionStore.currentUser?.firstName ?? "")'s Closet")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 8)

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
        .sheet(isPresented: $showingPostDetail) {
            if let selectedPost = selectedPost {
                PostDetailView(post: .constant(selectedPost))
                    .environmentObject(postStore)
                    .environmentObject(sessionStore)
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


struct PostDetailView: View {
    @EnvironmentObject var postStore: PostStore
    @EnvironmentObject var sessionStore: SessionStore
    @Binding var post: Post
    @State private var showingComments = false
    @State private var showingShippingPayment = false

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
                    }
                    .padding()

                    TabView {
                        ForEach(post.imageUrls, id: \.self) { imageUrl in
                            AsyncImage(url: URL(string: imageUrl)) { phase in
                                if let image = phase.image {
                                    image.resizable().scaledToFit().frame(maxWidth: .infinity)
                                } else if phase.error != nil {
                                    Color.red // Indicates an error
                                } else {
                                    Color.gray // Acts as a placeholder
                                }
                            }
                        }
                    }
                    .frame(height: 300)
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))

                    HStack {
                        Button(action: {
                            likePost(post: post)
                        }) {
                            Image(systemName: post.likedBy.contains(sessionStore.currentUser?.id ?? "") ? "heart.fill" : "heart")
                                .foregroundColor(post.likedBy.contains(sessionStore.currentUser?.id ?? "") ? .red : .red)
                        }
                        Button(action: {
                            showingComments = true
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
                                .background(Color.blue)
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
        .sheet(isPresented: $showingComments) {
            CommentsView(post: $post)
                .environmentObject(postStore)
                .environmentObject(sessionStore)
        }
        .sheet(isPresented: $showingShippingPayment) {
            ShippingPaymentView(post: post) // Pass the selected post
                .environmentObject(sessionStore)
        }
    }

    func likePost(post: Post) {
        guard let currentUser = sessionStore.currentUser else { return }
        postStore.toggleLike(post: post, userId: currentUser.id)
    }
}

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
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
        .padding()
    }
}

struct SettingsView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @EnvironmentObject var userStore: UserStore
    @State private var username: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var address: String = ""
    @State private var errorMessage: String?
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil
    @State private var showingImagePicker = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: HStack {
                    Image(systemName: "gearshape.fill")
                    Text("Profile")
                }) {
                    Button("Change Profile Picture") {
                        showingImagePicker = true
                    }
                    
                    TextField("username", text: $username)
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Address", text: $address)
                }
                
                Section {
                    Button("Save Changes") {
                        saveChanges()
                    }
                    .foregroundColor(.blue)
                }
                
                Section {
                    Button("Sign Out") {
                        sessionStore.signOut()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.red)
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationBarTitle("Settings")
            .onAppear {
                loadUserData()
            }
            .photosPicker(isPresented: $showingImagePicker, selection: $selectedItem, matching: .images, photoLibrary: .shared())
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) {
                        profileImage = uiImage
                    }
                }
            }
            
        }
    }

    func loadUserData() {
        guard let currentUser = sessionStore.currentUser else { return }
        firstName = currentUser.firstName
        lastName = currentUser.lastName
        address = currentUser.address
        profileImage = currentUser.profilePicture
        username = currentUser.username
    }

    func saveChanges() {
        guard var currentUser = sessionStore.currentUser else {
            self.errorMessage = "No current user found."
            return
        }

        currentUser.firstName = firstName
        currentUser.lastName = lastName
        currentUser.address = address
        currentUser.username = username

        print("Attempting to save changes:")  // Debugging
        print("First Name: \(currentUser.firstName)")
        print("Last Name: \(currentUser.lastName)")
        print("Address: \(currentUser.address)")
        print("Username: \(currentUser.username)")

        if let profileImage = profileImage {
            userStore.uploadProfileImage(image: profileImage) { url in
                if let url = url {
                    currentUser.profilePictureURL = url.absoluteString
                    self.updateUserAndDismiss(currentUser)
                } else {
                    self.errorMessage = "Failed to upload profile picture."
                }
            }
        } else {
            self.updateUserAndDismiss(currentUser)
        }
    }

    func updateUserAndDismiss(_ currentUser: User) {
        userStore.updateUser(currentUser) { error in
            if let error = error {
                self.errorMessage = "Failed to update user: \(error.localizedDescription)"
            } else {
                DispatchQueue.main.async {
                    print("User updated successfully")  // Debugging
                    print("Updated First Name: \(currentUser.firstName)")
                    print("Updated Last Name: \(currentUser.lastName)")
                    print("Updated Address: \(currentUser.address)")
                    print("Updated Username: \(currentUser.username)")

                    self.sessionStore.currentUser = currentUser // Update the current user in session store
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

struct SizeSelectionView: View {
    @Binding var selectedSizes: [String]
    let sizes = ["S", "M", "L", "XL", "wS", "wM", "wL", "wXL"]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(sizes, id: \.self) { size in
                    SizeButton(size: size, isSelected: selectedSizes.contains(size)) {
                        if selectedSizes.contains(size) {
                            selectedSizes.removeAll { $0 == size }
                        } else {
                            selectedSizes.append(size)
                        }
                    }
                }
            }
        }
        .frame(height: 44) // Set a fixed height for the ScrollView
    }
}
struct SizeButton: View {
    var size: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(size)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.clear)
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(lineWidth: 1)
                        .stroke(isSelected ? Color.blue : Color.gray)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ImageSelectionView: View {
    @Binding var selectedImages: [UIImage]
    @State private var showingImagePicker = false


    var body: some View {
        // Conditionally show the image picker button or the images
        if selectedImages.isEmpty {
            Button(action: {
                showingImagePicker = true
            }) {
                VStack {
                    Image(systemName: "camera.fill")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("Select Images")
                        .foregroundColor(.gray)
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 200, alignment: .center)
                .background(Color.gray.opacity(0.5))
                .cornerRadius(12)
                .padding()
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImages: $selectedImages)
            }
        } else {
            TabView {
                ForEach(selectedImages.indices, id: \.self) { index in
                    Image(uiImage: selectedImages[index])
                        .resizable()
                        .scaledToFit() // This ensures the whole image is visible and scaled down as needed
                        .frame(width: UIScreen.main.bounds.width, height: 225)
                        .clipped()
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .frame(height: 225)
            .onTapGesture {
                showingImagePicker = true
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImages: $selectedImages)
            }


        }
    }
}


struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> some UIViewController {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 10
        configuration.filter = .images
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            for result in results {
                result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                    if let image = image as? UIImage {
                        DispatchQueue.main.async {
                            self.parent.selectedImages.append(image)
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.parent.presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

struct NotificationItem: Identifiable {
    enum NotificationType: String {
        case comment, purchase, like, rent
    }

    var id: String
    var icon: String
    var type: NotificationType
    var username: String
    var actionText: String
    var timestamp: Date
    var productInfo: String
    var price: Double
    var size: String
    var duration: String
    var name: String
    var address: String
    var imageUrls: [String]
    var shipImageUrl: String? // Change to optional
    var buyer: User
    var expectedArrivalDate: Date?
    var expectedReturnDate: Date?

    init(id: String = UUID().uuidString, icon: String, type: NotificationType, username: String, actionText: String, timestamp: Date = Date(), productInfo: String, price: Double, size: String, duration: String, name: String, address: String, imageUrls: [String], shipImageUrl: String? = nil, buyer: User, expectedArrivalDate: Date? = nil, expectedReturnDate: Date? = nil) {
        self.id = id
        self.icon = icon
        self.type = type
        self.username = username
        self.actionText = actionText
        self.timestamp = timestamp
        self.productInfo = productInfo
        self.price = price
        self.size = size
        self.duration = duration
        self.name = name
        self.address = address
        self.imageUrls = imageUrls
        self.shipImageUrl = shipImageUrl
        self.buyer = buyer
        self.expectedArrivalDate = expectedArrivalDate
        self.expectedReturnDate = expectedReturnDate
    }
}



struct NotificationsView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @Binding var showingNotifications: Bool

    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    self.showingNotifications = false
                }) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Notifications").bold()
                    }
                }
                Spacer()
                Button(action: {
                    if let userId = sessionStore.currentUser?.id {
                        sessionStore.fetchNotifications(userId: userId)
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .padding()

            NotificationList(notifications: sessionStore.currentUser?.notifications ?? [])
        }
    }
}

struct NotificationList: View {
    var notifications: [NotificationItem]

    var body: some View {
        Group {
            if notifications.isEmpty {
                Text("No notifications available")
                    .padding()
            } else {
                List {
                    ForEach(notifications.sorted(by: { $0.timestamp > $1.timestamp })) { item in
                        NotificationCell(notification: item)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
}

struct NotificationCell: View {
    var notification: NotificationItem

    var body: some View {
        HStack {
            Image(systemName: notification.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 20)
            Text("@\(notification.username) \(notification.actionText)")
            Spacer()
            
            if notification.type == .purchase || notification.type == .rent {
                NavigationLink(destination: destinationView(for: notification)) {
                    Text("View")
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private func destinationView(for notification: NotificationItem) -> some View {
        if notification.actionText.contains("wants to rent") || notification.actionText.contains("wants to buy") {
            FulfillmentView(notification: notification)
        } else if notification.actionText.contains("confirmed your order!") {
            BuyerOrRenterNotificationView(notification: notification)
        } else {
            EmptyView()
        }
    }
}

struct FulfillmentView: View {
    @Environment(\.presentationMode) var presentationMode

    @State var notification: NotificationItem // Changed to var to make it mutable
    @State private var images: [UIImage] = []
    @State private var showAlert = false
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage? = nil
    @State private var uploadImageUrl: String = ""
    @State private var shipImageUrl: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "arrow.left")
                            Text("Fulfillment")
                                .bold()
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal)

                // Carousel for multiple images
                TabView {
                    ForEach(images, id: \.self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .frame(height: 250)
                            .clipped()
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .frame(height: 250)
                .onAppear {
                    loadImages()
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(notification.productInfo)
                        .font(.headline)
                    Text("Price: $\(notification.price, specifier: "%.2f")")
                        .font(.subheadline)
                    if notification.type == .rent {
                        Text("Rent Duration: \(notification.duration)")
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 15) {
                    Text("Buyer Information")
                        .font(.title2)
                        .bold()

                    HStack {
                        Text("Username:")
                        Spacer()
                        Text(notification.buyer.username)
                            .bold()
                    }
                    .padding(.horizontal)

                    HStack {
                        Text("Name:")
                        Spacer()
                        Text(notification.buyer.firstName + " " + notification.buyer.lastName)
                            .bold()
                    }
                    .padding(.horizontal)

                    HStack {
                        Text("Address:")
                        Spacer()
                        Text(notification.buyer.address)
                            .bold()
                    }
                    .padding(.horizontal)

                    HStack {
                        Text("Size:")
                        Spacer()
                        Text(notification.size)
                            .bold()
                    }
                    .padding(.horizontal)

                    HStack {
                        Text("Action:")
                        Spacer()
                        Text(notification.actionText)
                            .bold()
                    }
                    .padding(.horizontal)
                }
                .padding(.top)

                Spacer()

                // Upload Image Section
                VStack {
                    Text("Upload Image with Tracking Label")
                        .font(.headline)
                        .padding(.horizontal)

                    ImageSelectionView(selectedImages: $images)
                        .frame(height: 200)
                        .padding()

                    if !images.isEmpty {
                        Image(uiImage: images.first!)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .padding()
                    }
                }

                HStack {
                    Spacer()
                    Button(action: {
                        handleConfirmAndShip()
                    }) {
                        Text("Confirm & Ship")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .simultaneousGesture(
                        LongPressGesture().onEnded { _ in
                            showAlert = true
                        }
                    )
                    .alert(isPresented: $showAlert) {
                        Alert(
                            title: Text("Confirm & Ship"),
                            message: Text("Once you press this button, you will confirm the shipment and send the image to the buyer or renter."),
                            primaryButton: .default(Text("Confirm")) {
                                handleConfirmAndShip()
                            },
                            secondaryButton: .cancel()
                        )
                    }

                    Button("Don't Fulfill") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    Spacer()
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal)
            .padding(.top, 20)
        }
        .navigationBarHidden(true)
    }

    private func loadImages() {
        notification.imageUrls.forEach { urlString in
            guard let url = URL(string: urlString) else { return }

            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.images.append(image)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.images.append(UIImage(systemName: "photo")!)
                    }
                }
            }.resume()
        }

        if let shipImageUrlString = notification.shipImageUrl, let url = URL(string: shipImageUrlString) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.images.append(image)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.images.append(UIImage(systemName: "photo")!)
                    }
                }
            }.resume()
        }
    }


    private func handleImageUpload() {
        guard let selectedImage = images.first else { return }
        // Upload the image to your server or Firebase and get the URL
        // Replace with actual image upload code
        let imageUrl = "https://example.com/uploaded_image.jpg"
        notification.shipImageUrl = imageUrl
    }

    private func handleConfirmAndShip() {
        guard let selectedImage = images.first else { return }
        // Upload the image to your server or Firebase and get the URL
        // Replace with actual image upload code
        let imageUrl = "https://example.com/uploaded_image.jpg"
        notification.shipImageUrl = imageUrl

        let expectedArrivalDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
        let expectedReturnDate: Date?
        if notification.type == .rent {
            if let duration = Int(notification.duration) {
                expectedReturnDate = Calendar.current.date(byAdding: .day, value: 3 + duration, to: Date())
            } else {
                expectedReturnDate = nil
            }
        } else {
            expectedReturnDate = nil
        }

        sendNotificationToBuyerOrRenter(expectedArrivalDate: expectedArrivalDate, expectedReturnDate: expectedReturnDate)
    }

    private func sendNotificationToBuyerOrRenter(expectedArrivalDate: Date?, expectedReturnDate: Date?) {
        let db = Firestore.firestore()
        let buyerId = notification.buyer.id

        let notificationData: [String: Any] = [
            "username": notification.username,
            "type": notification.type.rawValue,
            "actionText": "confirmed your order!",
            "timestamp": FieldValue.serverTimestamp(),
            "productInfo": notification.productInfo,
            "price": notification.price,
            "size": notification.size,
            "duration": notification.duration,
            "name": notification.name,
            "address": notification.address,
            "imageUrls": notification.imageUrls,
            "shipImageUrl": notification.shipImageUrl,
            "expectedArrivalDate": expectedArrivalDate ?? NSNull(),
            "expectedReturnDate": expectedReturnDate ?? NSNull(),
            "icon": "shippingbox",
            "buyer": [
                "id": notification.buyer.id,
                "username": notification.buyer.username,
                "email": notification.buyer.email,
                "firstName": notification.buyer.firstName,
                "lastName": notification.buyer.lastName,
                "address": notification.buyer.address,
                "profilePictureURL": notification.buyer.profilePictureURL,
                "followers": notification.buyer.followers,
                "numberOfBuyRents": notification.buyer.numberOfBuyRents
            ]
        ]

        db.collection("users").document(buyerId).collection("notifications").addDocument(data: notificationData) { error in
            if let error = error {
                print("Error adding notification: \(error.localizedDescription)")
            } else {
                print("Notification sent to buyer/renter.")
            }
        }
    }
}


struct CountdownTimerView: View {
    @State private var timeRemaining: TimeInterval
    let endDate: Date

    init(endDate: Date) {
        self.endDate = endDate
        self._timeRemaining = State(initialValue: endDate.timeIntervalSince(Date()))
    }

    var body: some View {
        VStack {
            Text(timeString(from: timeRemaining))
                .font(.largeTitle)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .onAppear {
                    startTimer()
                }
        }
    }

    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            let now = Date()
            timeRemaining = endDate.timeIntervalSince(now)

            if timeRemaining <= 0 {
                timer.invalidate()
            }
        }
    }

    private func timeString(from time: TimeInterval) -> String {
        let days = Int(time) / 86400
        let hours = (Int(time) % 86400) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d days %02d:%02d:%02d", days, hours, minutes, seconds)
    }
}

struct BuyerOrRenterNotificationView: View {
    let notification: NotificationItem
    @State private var images: [UIImage] = []
    @State private var shipmentImage: UIImage?
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {

                TabView {
                    ForEach(images, id: \.self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .frame(height: 250)
                            .clipped()
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .frame(height: 250)
                .onAppear {
                    loadImages()
                    loadShipmentImage()
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(notification.productInfo)
                        .font(.headline)
                    Text("Price: $\(notification.price, specifier: "%.2f")")
                        .font(.subheadline)
                    if notification.type == .rent {
                        Text("Rent Duration: \(notification.duration)")
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 15) {
                    Text("Buyer Information")
                        .font(.title2)
                        .bold()

                    HStack {
                        Text("Username:")
                        Spacer()
                        Text(notification.username)
                            .bold()
                    }
                    .padding(.horizontal)

                    HStack {
                        Text("Name:")
                        Spacer()
                        Text(notification.name)
                            .bold()
                    }
                    .padding(.horizontal)

                    HStack {
                        Text("Address:")
                        Spacer()
                        Text(notification.address)
                            .bold()
                    }
                    .padding(.horizontal)

                    HStack {
                        Text("Size:")
                        Spacer()
                        Text(notification.size)
                            .bold()
                    }
                    .padding(.horizontal)

                    HStack {
                        Text("Action:")
                        Spacer()
                        Text(notification.actionText)
                            .bold()
                    }
                    .padding(.horizontal)
                }
                .padding(.horizontal)

                // Expected Dates
                VStack(alignment: .leading, spacing: 5) {
                    if let expectedArrivalDate = notification.expectedArrivalDate {
                        Text("Expected Arrival Date: \(formattedDate(expectedArrivalDate))")
                            .font(.subheadline)
                    }
                    if notification.type == .rent, let expectedReturnDate = notification.expectedReturnDate {
                        CountdownTimerView(endDate: expectedReturnDate)
                        Text("Expected Return Date: \(formattedDate(expectedReturnDate))")
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal)

                // Proof of Shipment Image
                if let shipmentImage = shipmentImage {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Proof of Shipment:")
                            .font(.headline)
                        Image(uiImage: shipmentImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .padding()
                    }
                    .padding(.horizontal)
                } else {
                    Text("No shipment proof available yet.")
                        .font(.subheadline)
                        .padding(.horizontal)
                }
            }
        }
    }

    private func loadImages() {
        notification.imageUrls.forEach { urlString in
            guard let url = URL(string: urlString) else { return }

            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.images.append(image)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.images.append(UIImage(systemName: "photo")!)
                    }
                }
            }.resume()
        }
    }

    private func loadShipmentImage() {
        guard let urlString = notification.shipImageUrl, let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.shipmentImage = image
                }
            } else {
                DispatchQueue.main.async {
                    self.shipmentImage = UIImage(systemName: "photo")
                }
            }
        }.resume()
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}


struct ShippingPaymentView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var rentDuration: Int = 1 // Default rent duration
    @State private var isRent: Bool = true // Toggle between rent or buy
    @State private var name: String = ""
    @State private var address: String = ""
    @State private var selectedSize: String = "" // Change to single selected size
    @State private var showPaymentInfo = false
    @State private var imageLoadError = false
    
    @EnvironmentObject var sessionStore: SessionStore
    
    var post: Post // Accept the entire post object
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Spacer(minLength: 4)
                // Navigation Bar
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "arrow.left")
                            Text("Shipping & Payment")
                                .bold()
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                // Product Image and Info
                if imageLoadError {
                    Text("Failed to load images. Please try again later.")
                        .foregroundColor(.red)
                        .padding(.horizontal)
                } else {
                    TabView {
                        ForEach(post.imageUrls, id: \.self) { imageUrl in
                            AsyncImage(url: URL(string: imageUrl)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(height: 300) // Adjusted image size
                                case .success(let image):
                                    image.resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 300) // Adjusted image size
                                case .failure:
                                    Image(systemName: "xmark.circle")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 300) // Adjusted image size
                                        .foregroundColor(.red)
                                        .onAppear {
                                            imageLoadError = true
                                        }
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())
                    .frame(height: 300)
                }
                
                // Product Description
                Text(post.description)
                    .font(.title3)
                    .padding(.horizontal)
                
                HStack {
                    Text("Price: $\(isRent ? (Double(post.rentPrice)! * Double(rentDuration)) : Double(post.purchasePrice)!, specifier: "%.2f") + \(isRent ? (Double(post.rentPrice)! * 0.03 * Double(rentDuration)) : Double(post.purchasePrice)! * 0.06, specifier: "%.2f") tax")
                        .font(.headline)
                    Text("Select Size:")
                        .padding(.leading)
                        .font(.headline)
                }
                .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(post.sizes, id: \.self) { size in
                            Button(action: {
                                selectedSize = size // Ensure only one size is selected
                            }) {
                                Text(size)
                                    .foregroundColor(selectedSize == size ? .white : .blue)
                                    .padding()
                                    .background(selectedSize == size ? Color.blue : Color.clear)
                                    .cornerRadius(5)
                            }
                            .padding(.leading, 10)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 44) // Set a fixed height for the ScrollView
                
                if post.saleOption == .purchaseOrRent {
                    Toggle(isOn: $isRent) {
                        Text(isRent ? "Rent" : "Buy")
                            .font(.headline)
                    }
                    .padding(.horizontal)
                } else {
                    Text(post.saleOption == .purchase ? "Buy" : "Rent")
                        .font(.headline)
                        .padding(.horizontal)
                }
                
                if (isRent && post.saleOption == .purchaseOrRent) || post.saleOption == .rent {
                    Picker("Rent Duration", selection: $rentDuration) {
                        ForEach(1...40, id: \.self) { day in
                            Text("\(day) day\(day > 1 ? "s" : "")")
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 120) // Set the height to limit picker size
                    .clipped() // Clip the overflowing part of the picker
                    .padding(.horizontal)
                }
                
                // Name and Address TextFields
                TextField("Name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                TextField("Address", text: $address)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                // Payment Button
                Button(action: {
                    print("Pay with Venmo button tapped")
                    let venmoUsername = "FROC-Marketplace"
                    let baseAmount = isRent ? Double(post.rentPrice)! * Double(rentDuration) : Double(post.purchasePrice)!
                    let taxAmount = isRent ? baseAmount * 0.03 : baseAmount * 0.06
                    let paymentAmount = baseAmount + taxAmount
                    let paymentNote = """
                    Payment for \(isRent ? "renting" : "buying") the item
                    Size: \(selectedSize)
                    Description: \(post.description)
                    Duration: \(rentDuration) day(s)
                    """
                    
                    // Encode the payment note to ensure it’s URL safe
                    let encodedNote = paymentNote.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                    
                    // Create the Venmo URL string
                    let venmoURLString = "venmo://paycharge?txn=pay&recipients=\(venmoUsername)&amount=\(paymentAmount)&note=\(encodedNote)"
                    
                    // Open the URL to launch Venmo app
                    if let venmoURL = URL(string: venmoURLString), UIApplication.shared.canOpenURL(venmoURL) {
                        UIApplication.shared.open(venmoURL)
                    } else {
                        print("Venmo app is not installed.")
                    }
                }) {
                    HStack {
                        Image(systemName: "creditcard") // Placeholder for Venmo icon
                        Text("Pay with Venmo")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Button(action: {
                    print("Confirm Payment button tapped")
                    sendNotificationToSeller()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Confirm Payment")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .simultaneousGesture(LongPressGesture().onEnded { _ in
                    showPaymentInfo = true
                })
                .alert(isPresented: $showPaymentInfo) {
                    Alert(
                        title: Text("Payment Information"),
                        message: Text("Once the payment is sent, the FROC team will review it and ensure the seller receives the product before the seller receives their money. We take a little bit extra money for insurance if the product is rented out as insurance in case a product is not returned on time or if the product is damaged. If the product is not returned on time, the seller gets their money back."),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            print("ShippingPaymentView appeared")
        }
    }
    
    private func sendNotificationToSeller() {
        print("Sending notification to seller...")
        let db = Firestore.firestore()
        let sellerId = post.user.id

        guard let currentUser = sessionStore.currentUser else {
            print("Current user is not available.")
            return
        }

        // Define the icons for rent and purchase
        let rentIcon = "tag"
        let purchaseIcon = "cart"

        // Determine the icon based on the notification type
        let icon = isRent ? rentIcon : purchaseIcon

        let buyerData: [String: Any] = [
            "id": currentUser.id,
            "username": currentUser.username,
            "email": currentUser.email,
            "firstName": currentUser.firstName,
            "lastName": currentUser.lastName,
            "address": currentUser.address,
            "profilePictureURL": currentUser.profilePictureURL,
            "followers": currentUser.followers,
            "numberOfBuyRents": currentUser.numberOfBuyRents
        ]

        let notificationData: [String: Any] = [
            "username": currentUser.username,
            "type": isRent ? "rent" : "purchase",
            "actionText": isRent ? "wants to rent" : "wants to buy",
            "timestamp": FieldValue.serverTimestamp(),
            "productInfo": post.description,
            "price": isRent ? Double(post.rentPrice)! * Double(rentDuration) : Double(post.purchasePrice)!,
            "size": selectedSize,
            "duration": isRent ? "\(rentDuration) days" : "",
            "name": name,
            "address": address,
            "imageUrls": post.imageUrls, // Add all image URLs of the post
            "icon": icon,  // Add the icon to the notification data
            "buyer": buyerData // Add buyer data to the notification
        ]

        db.collection("users").document(sellerId).collection("notifications").addDocument(data: notificationData) { error in
            if let error = error {
                print("Error adding notification: \(error.localizedDescription)")
            } else {
                print("Notification sent to seller.")
            }
        }
    }

}

//commands: ctrl i for formatting, command option p for preview, and make sure you have the code for it in contentview


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
