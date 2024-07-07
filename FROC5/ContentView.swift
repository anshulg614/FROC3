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
    @StateObject private var sessionStore = SessionStore()
    @State private var showingSignUp = false
    @State private var showingSignIn = false
    @State private var errorMessage: String?

    var body: some View {
        if sessionStore.isSignedIn {
            SignedInView()
                .environmentObject(postStore)
                .environmentObject(sessionStore)
        } else {
            VStack {
                Button("Sign Up") {
                    showingSignUp = true
                }
                .padding()
                .sheet(isPresented: $showingSignUp) {
                    SignUpView()
                        .environmentObject(sessionStore)
                }

                Button("Sign In") {
                    showingSignIn = true
                }
                .padding()
                .sheet(isPresented: $showingSignIn) {
                    SignInView()
                        .environmentObject(sessionStore)
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

    var body: some View {
        TabView {
            ViewClosetsView()
                .tabItem {
                    Image(systemName: "eye.fill")
                    Text("View Closets")
                }
                .environmentObject(postStore)
                .environmentObject(sessionStore)

            MyClosetView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("My Closet")
                }
                .environmentObject(postStore)
                .environmentObject(sessionStore)
        }
    }
}

class SessionStore: ObservableObject {
    @Published var isSignedIn: Bool = false
    @Published var currentUser: User?

    private var db = Firestore.firestore()
    private var storageRef = Storage.storage().reference()

    init() {
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
                self.currentUser = User(
                    id: document.documentID,
                    username: data["username"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    firstName: data["firstName"] as? String ?? "",
                    lastName: data["lastName"] as? String ?? "",
                    address: data["address"] as? String ?? "",
                    profilePicture: UIImage(systemName: "person.crop.circle.fill")!,
                    profilePictureURL: profilePictureURL
                )
                self.fetchProfileImage(profilePictureURL: profilePictureURL)
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

    func updateUserInfo(user: User) {
        let userData: [String: Any] = [
            "username": user.username,
            "email": user.email,
            "firstName": user.firstName,
            "lastName": user.lastName,
            "address": user.address,
            "profilePictureURL": user.profilePictureURL
        ]
        db.collection("users").document(user.id).setData(userData) { error in
            if let error = error {
                print("Error updating user data: \(error.localizedDescription)")
            } else {
                self.fetchUserInfo(userId: user.id)
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
    @State private var showingNotifications = false
    @State private var showingShippingPayment = false
    @State private var selectedPost: Post? // Track the selected post
    @EnvironmentObject var sessionStore: SessionStore // To access the current user

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text("FROC")
                        .font(.custom("CurvyFontName", size: 34))
                    Spacer()
                    NavigationLink(destination: PostView()) {
                        Image(systemName: "plus")
                            .foregroundColor(Color.blue)
                    }
                    Button(action: {
                        self.showingNotifications = true
                    }) {
                        Image(systemName: "bell.fill")
                    }
                    Image(systemName: "message.fill")
                }
                .padding()

                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(postStore.posts) { post in
                            VStack(alignment: .leading) {
                                HStack {
                                    if let profilePictureURL = post.profilePictureURL, let url = URL(string: profilePictureURL) {
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
                                    Text(post.username)
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

                                HStack {
                                    Button(action: {
                                        likePost(post: post)
                                    }) {
                                        Image(systemName: post.likedBy.contains(sessionStore.currentUser?.id ?? "") ? "heart.fill" : "heart")
                                            .foregroundColor(post.likedBy.contains(sessionStore.currentUser?.id ?? "") ? .red : .gray)
                                    }
                                    Image(systemName: "bubble.left")
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
                        }
                    }
                    .refreshable {
                        print("refreshing")
                        postStore.refreshData()
                    }
                }
            }
            .sheet(isPresented: $showingNotifications) {
                NavigationView {
                    NotificationsView(showingNotifications: $showingNotifications)
                }
            }
            .sheet(isPresented: $showingShippingPayment) {
                if let selectedPost = selectedPost {
                    ShippingPaymentView(post: selectedPost) // Pass the selected post
                }
            }
        }
    }

    func likePost(post: Post) {
        guard let currentUser = sessionStore.currentUser else { return }
        postStore.toggleLike(post: post, userId: currentUser.id)
    }
}

class PostStore: ObservableObject {
    @Published var posts: [Post] = []

    private var db = Firestore.firestore()
    private var storageRef = Storage.storage().reference()

    init() {
        fetchPosts()
    }

    func fetchPosts() {
        db.collection("posts").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching posts: \(error.localizedDescription)")
            } else {
                if let snapshot = snapshot {
                    self.posts = snapshot.documents.map { document in
                        let data = document.data()
                        let imageUrls = data["imageUrls"] as? [String] ?? []
                        let profilePictureURL = data["profilePictureURL"] as? String
                        let likedBy = data["likedBy"] as? [String] ?? [] // Add this line
                        return Post(
                            id: document.documentID,
                            username: data["username"] as? String ?? "",
                            profilePictureURL: profilePictureURL,
                            imageUrls: imageUrls,
                            caption: data["caption"] as? String ?? "",
                            saleOption: Post.SaleOption(rawValue: data["saleOption"] as? String ?? "Purchase") ?? .purchase,
                            price: data["price"] as? String ?? "",
                            sizes: data["sizes"] as? [String] ?? [],
                            description: data["description"] as? String ?? "",
                            numberOfLikes: data["numberOfLikes"] as? Int ?? 0,
                            likedBy: likedBy // Add this line
                        )
                    }
                }
            }
        }
    }

    func fetchUserProfilePictures() {
        let userIds = posts.map { $0.username }
        let uniqueUserIds = Array(Set(userIds))

        uniqueUserIds.forEach { userId in
            db.collection("users").document(userId).getDocument { document, error in
                if let document = document, document.exists {
                    if let profilePictureURL = document.data()?["profilePictureURL"] as? String {
                        self.posts = self.posts.map { post in
                            var updatedPost = post
                            if post.username == userId {
                                updatedPost.profilePictureURL = profilePictureURL
                            }
                            return updatedPost
                        }
                    }
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
                "username": post.username,
                "profilePictureURL": post.profilePictureURL ?? "",
                "caption": post.caption,
                "saleOption": post.saleOption.rawValue,
                "price": post.price,
                "sizes": post.sizes,
                "description": post.description,
                "numberOfLikes": post.numberOfLikes,
                "likedBy": post.likedBy, // Add this line
                "imageUrls": uploadedImageUrls
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

    func toggleLike(post: Post, userId: String) {
        var updatedPost = post

        if post.likedBy.contains(userId) {
            // Unlike the post
            updatedPost.likedBy.removeAll { $0 == userId }
            updatedPost.numberOfLikes -= 1
        } else {
            // Like the post
            updatedPost.likedBy.append(userId)
            updatedPost.numberOfLikes += 1
        }

        // Update Firestore
        let postData: [String: Any] = [
            "numberOfLikes": updatedPost.numberOfLikes,
            "likedBy": updatedPost.likedBy
        ]

        db.collection("posts").document(post.id).updateData(postData) { error in
            if let error = error {
                print("Error updating post: \(error.localizedDescription)")
            } else {
                if let index = self.posts.firstIndex(where: { $0.id == post.id }) {
                    self.posts[index] = updatedPost
                }
            }
        }
    }
}

struct Post: Identifiable {
    let id: String
    let username: String
    var profilePictureURL: String?
    var imageUrls: [String]
    var caption: String
    var saleOption: SaleOption
    var price: String
    var sizes: [String]
    var description: String
    var numberOfLikes: Int
    var likedBy: [String] // Add this line to track users who liked the post

    enum SaleOption: String, CaseIterable, Identifiable {
        case purchase = "Purchase"
        case rent = "Rent"
        case purchaseOrRent = "Purchase or Rent"

        var id: String { self.rawValue }
    }

    init(id: String = UUID().uuidString, username: String, profilePictureURL: String? = nil, imageUrls: [String] = [], caption: String = "", saleOption: SaleOption = .purchase, price: String = "", sizes: [String] = [], description: String = "", numberOfLikes: Int = 0, likedBy: [String] = []) {
        self.id = id
        self.username = username
        self.profilePictureURL = profilePictureURL
        self.imageUrls = imageUrls
        self.caption = caption
        self.saleOption = saleOption
        self.price = price
        self.sizes = sizes
        self.description = description
        self.numberOfLikes = numberOfLikes
        self.likedBy = likedBy
    }
}


struct User: Identifiable {
    var id: String
    var username: String
    var email: String
    var firstName: String
    var lastName: String
    var address: String
    var profilePicture: UIImage
    var profilePictureURL: String
    var posts: [Post]
    var followers: Int
    var numberOfBuyRents: Int

    init(id: String = UUID().uuidString, username: String, email: String, firstName: String, lastName: String, address: String, profilePicture: UIImage = UIImage(), profilePictureURL: String = "", posts: [Post] = [], followers: Int = 0, numberOfBuyRents: Int = 0) {
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
        self.numberOfBuyRents = numberOfBuyRents
    }
}

struct PostView: View {
    @State private var selectedImages: [UIImage] = []
    @State private var postCaption: String = "Write a caption..."
    @State private var saleOption: Post.SaleOption = .purchase
    @State private var price: String = ""
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
                    TextField("Price", text: $price)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 140)
                    
                    SizeSelectionView(selectedSizes: $selectedSizes)
                }
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
                            username: currentUser.username,
                            profilePictureURL: currentUser.profilePictureURL,
                            imageUrls: [],
                            caption: postCaption,
                            saleOption: saleOption,
                            price: price,
                            sizes: selectedSizes,
                            description: productDescription,
                            numberOfLikes: 0
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
    @State private var showingSettings = false
    @State private var selectedPost: Post? // To track the selected post for detailed view
    @State private var showingPostDetail = false // To show the post detail view

    var body: some View {
        VStack {
            HStack {
                if let profilePictureURL = sessionStore.currentUser?.profilePictureURL,
                   let url = URL(string: profilePictureURL) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } placeholder: {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                    }
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(sessionStore.currentUser?.username ?? "") ")
                        .font(.headline)
                    Text("Followers: \(sessionStore.currentUser?.followers ?? 0) • Rented/Bought: \(sessionStore.currentUser?.numberOfBuyRents ?? 0)")
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
                .padding()
            
            ScrollView {
                let columns = [GridItem(.flexible()), GridItem(.flexible())]
                LazyVGrid(columns: columns, spacing: 16) {
                    // Filter posts to show only those by the current user
                    ForEach(postStore.posts.filter { $0.username == sessionStore.currentUser?.username }) { post in
                        // Use Button to handle post click
                        Button(action: {
                            selectedPost = post
                            showingPostDetail = true
                        }) {
                            Rectangle()
                                .foregroundColor(.gray)
                                .aspectRatio(1, contentMode: .fit)
                                .overlay(
                                    AsyncImage(url: URL(string: post.imageUrls.first ?? "")) { image in
                                        image.resizable().scaledToFill().clipped()
                                    } placeholder: {
                                        Image(systemName: "photo")
                                            .resizable()
                                            .scaledToFill()
                                            .clipped()
                                    }
                                )
                        }
                        .clipped()
                    }
                }
            }
            .padding(.horizontal)
        }
        .navigationBarTitle("My Closet", displayMode: .inline)
        .sheet(isPresented: $showingPostDetail) {
            if let selectedPost = selectedPost {
                PostDetailView(post: selectedPost)
            }
        }
    }
}

struct PostDetailView: View {
    @EnvironmentObject var postStore: PostStore
    @EnvironmentObject var sessionStore: SessionStore
    var post: Post

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading) {
                    HStack {
                        if let profilePictureURL = post.profilePictureURL, let url = URL(string: profilePictureURL) {
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
                        Text(post.username)
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
                            if let currentUser = sessionStore.currentUser {
                                postStore.toggleLike(post: post, userId: currentUser.id)
                            }
                        }) {
                            Image(systemName: post.likedBy.contains(sessionStore.currentUser?.id ?? "") ? "heart.fill" : "heart")
                        }
                        Image(systemName: "bubble.left")
                        Image(systemName: "bookmark")
                        Spacer()
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
                    if let currentUser = sessionStore.currentUser {
                        postStore.toggleLike(post: post, userId: currentUser.id)
                    }
                }
            }
        }
    }
}


struct SettingsView: View {
    @EnvironmentObject var sessionStore: SessionStore
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
                    .padding()
                    
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
    }

    func saveChanges() {
        guard var currentUser = sessionStore.currentUser else { return }
        currentUser.firstName = firstName
        currentUser.lastName = lastName
        currentUser.address = address
        
        if let profileImage = profileImage {
            sessionStore.uploadProfileImage(image: profileImage) { url in
                if let url = url {
                    currentUser.profilePictureURL = url.absoluteString
                    sessionStore.updateUserInfo(user: currentUser)
                } else {
                    self.errorMessage = "Failed to upload profile picture."
                }
            }
        } else {
            sessionStore.updateUserInfo(user: currentUser)
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
// test
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
    enum NotificationType {
        case comment, purchase, like, rent
    }
    
    var id = UUID()
    var type: NotificationType
    var username: String
    var actionText: String
    var icon: String
    // You might want to include product details here as well if they are specific to each notification
}


struct NotificationCell: View {
    var notification: NotificationItem
    // Dummy data for the sake of example
    let productImage = UIImage(systemName: "tshirt")!
    let price = "$49.99"
    let productInfo = "Red shorts - Size M"
    let rentDuration = "1 week"
    
    var body: some View {
        HStack {
            Image(systemName: notification.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 20)
            Text("\(notification.username) \(notification.actionText)")
            Spacer()
            
            if notification.type == .purchase || notification.type == .rent {
                NavigationLink(destination: FulfillmentView(
                    notificationType: notification.type,
                    productImage: productImage,
                    price: price,
                    productInfo: productInfo,
                    rentDuration: rentDuration,
                    shippingLabel: "UPS Ground", // Replace with actual shipping label
                    shippingAddress: "123 Apple Lane, Cupertino, CA" // Replace with actual address
                )) {
                    Text("Fulfill")
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}


struct NotificationsView: View {
    @Binding var showingNotifications: Bool
    let notifications = [
        NotificationItem(type: .comment, username: "Mark", actionText: "commented 'cool'", icon: "bubble.right"),
        NotificationItem(type: .purchase, username: "Katy", actionText: "wants to buy 'red shorts'", icon: "cart"),
        NotificationItem(type: .like, username: "@Andrea67", actionText: "liked your post", icon: "heart"),
        NotificationItem(type: .rent, username: "Jacob", actionText: "wants to rent 'wedding set'", icon: "tag"),
        NotificationItem(type: .comment, username: "@Jack", actionText: "commented 'cool'", icon: "bubble.right"),
        NotificationItem(type: .rent, username: "@Sam", actionText: "wants to buy 'red shorts'", icon: "cart"),
        NotificationItem(type: .like, username: "@Francis23", actionText: "liked your post", icon: "heart"),
        NotificationItem(type: .purchase, username: "@Jordyboy6199", actionText: "wants to rent 'wedding set'", icon: "tag")
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
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
            }
            .padding()
            
            List(notifications) { item in
                NotificationCell(notification: item)
            }
            .listStyle(PlainListStyle())
        }
    }
}




struct FulfillmentView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // These properties should be passed to this view when it's initialized
    let notificationType: NotificationItem.NotificationType
    let productImage: UIImage
    let price: String
    let productInfo: String
    let rentDuration: String
    let shippingLabel: String
    let shippingAddress: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
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
                
                HStack {
                    Image(uiImage: productImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .padding(.vertical) // for top and bottom padding
                    
                    VStack(alignment: .leading, spacing: 5) { // added spacing between text elements
                        Text(price)
                            .font(.headline)
                        Text(productInfo)
                            .font(.subheadline)
                    }
                    Spacer()
                }
                .padding(.horizontal) // Add padding to this HStack
                
                if notificationType == .rent {
                    Text("Rent Duration: \(rentDuration)")
                        .padding(.horizontal) // Apply padding to this Text view
                } else {
                    Text("Sell to Buyer")
                        .padding(.horizontal) // Apply padding to this Text view
                }
                
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Shipping Label: \(shippingLabel)")
                    Text("Shipping Address: \(shippingAddress)")
                }
                .padding(.horizontal) // Add padding to this VStack
                
                Spacer()
                HStack {
                    Spacer() // This Spacer will push the buttons to the center
                    Button("Confirm & Ship") {
                        // action to confirm and ship the product
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Button("Don't Fulfill") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    Spacer() // This Spacer will ensure the buttons stay in the center
                }
                .padding(.bottom, 20) // This adds space at the bottom inside the ScrollView
            }
            .padding(.horizontal) // Apply horizontal padding once, to the entire VStack
            .padding(.top, 20) // Add more padding at the top to push the content down from the navigation bar
        }
        .navigationBarHidden(true)
    }
}


struct ShippingPaymentView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var rentDuration: Int = 1 // Default rent duration
    @State private var isRent: Bool = true // Toggle between rent or buy
    @State private var name: String = ""
    @State private var address: String = ""
    @State private var selectedSizes: [String] = []

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
                HStack(alignment: .top, spacing: 10) {
                    AsyncImage(url: URL(string: post.imageUrls.first ?? "")) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 150, height: 150) // Adjusted image size
                    } placeholder: {
                        Image(systemName: "tshirt.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 150, height: 150) // Adjusted image size
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text(post.description)
                            .font(.subheadline)
                    }
                    Spacer()
                }
                .padding(.horizontal)

                HStack {
                    Text("$\(post.price)")
                        .font(.headline)
                    Text("Sizes: \(post.sizes.joined(separator: ", "))")
                        .padding(.leading)
                }
                .padding(.horizontal)

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
                    let venmoUsername = "FROC-Marketplace"
                    let paymentAmount = post.price  // Example amount
                    let paymentNote = "Payment for services"

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
            }
        }
        .navigationBarHidden(true)
    }
}


//commands: ctrl i for formatting, command option p for preview, and make sure you have the code for it in contentview


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
