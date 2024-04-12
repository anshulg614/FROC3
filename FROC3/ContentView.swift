import SwiftUI
import Amplify

struct ContentView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @State private var confirmationCode: String = ""
    @State private var isSignedIn: Bool = true
    
    
    
    var body: some View {
        if isSignedIn {
            SignedInView(email: email)
        } else {
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
                
                Button("Sign Up") {
                    Task {
                        await signUp(email: email, password: password)
                    }
                }
                .padding()
                
                TextField("Verification Code", text: $confirmationCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button("Verify Email") {
                    Task {
                        await confirmSignUp(for: email, with: confirmationCode)
                    }
                }
                .padding()
                
                Button("Sign In") {
                    Task {
                        await signIn(email: email, password: password)
                    }
                }
                .padding()
            }
            .padding()
        }
    }
    
    func signUp(email: String, password: String) async {
        let userAttributes = [AuthUserAttribute(.email, value: email)]
        let options = AuthSignUpRequest.Options(userAttributes: userAttributes)
        do {
            let signUpResult = try await Amplify.Auth.signUp(
                username: email, // Here username is the email
                password: password,
                options: options
            )
            if case let .confirmUser(deliveryDetails, _, _) = signUpResult.nextStep {
                print("Confirmation code sent to \(String(describing: deliveryDetails))")
                // You might want to navigate to a confirmation view
            } else {
                print("Sign up complete")
                // Handle successful sign-up
            }
        } catch let error as AuthError {
            DispatchQueue.main.async {
                self.errorMessage = error.errorDescription
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func signIn(email: String, password: String) async {
        do {
            let signInResult = try await Amplify.Auth.signIn(username: email, password: password)
            if signInResult.isSignedIn {
                print("Sign in succeeded")
                DispatchQueue.main.async {
                    // Update UI state or navigate to another view
                }
            } else {
                print("Sign in needs further action")
                DispatchQueue.main.async {
                    // Show additional steps to the user
                }
            }
        } catch let error as AuthError {
            DispatchQueue.main.async {
                self.errorMessage = error.errorDescription
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    func confirmSignUp(for email: String, with code: String) async {
        do {
            let confirmResult = try await Amplify.Auth.confirmSignUp(for: email, confirmationCode: code)
            switch confirmResult.nextStep {
            case .done:
                print("Email verified successfully")
                DispatchQueue.main.async {
                    self.isSignedIn = true
                }
            default:
                print("Email verification needs further action")
            }
        } catch let error as AuthError {
            DispatchQueue.main.async {
                self.errorMessage = error.errorDescription
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}


struct SignedInView: View {
    var email: String
    
    var body: some View {
        TabView {
            ViewClosetsView()
                .tabItem {
                    Image(systemName: "eye.fill") // Use appropriate SF Symbols
                    Text("View Closets")
                }
            
            MyClosetView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("My Closet")
                }
            
            
        }
    }
}

struct MyClosetView: View {
    let posts = [Post(username: "user1"), Post(username: "user1"), Post(username: "user1"), Post(username: "user1"), Post(username: "user1"), Post(username: "user1")]
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Username")
                        .font(.headline)
                    Text("Followers: 100 • Rented/Bought")
                }
                Spacer()
                Image(systemName: "ellipsis")
                    .font(.headline)
            }
            .padding([.top, .leading, .trailing])
            
            Text("Username's Closet")
                .font(.headline) // Adjust the font size as needed
                .frame(maxWidth: .infinity, alignment: .center) // Changed alignment to .center
                .padding()
            
            ScrollView {
                let columns = [GridItem(.flexible()), GridItem(.flexible())]
                LazyVGrid(columns: columns, spacing: 16) { // Added spacing between rows
                    ForEach(posts) { post in
                        Rectangle() // Placeholder for the post content
                            .foregroundColor(.gray)
                            .aspectRatio(1, contentMode: .fill)
                    }
                }
            }
            .padding(.horizontal)
        }
        .navigationBarTitle("My Closet", displayMode: .inline)
    }
}


//posts for viewcloset and I think also for all posts in general
struct Post: Identifiable {
    let id = UUID()
    let username: String
    // Add other post properties here
}

struct ViewClosetsView: View {
    // Sample posts data
    let posts = [Post(username: "user1"), Post(username: "user2")]
    @State private var showingNotifications = false
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Text("FROC")
                    .font(.custom("CurvyFontName", size: 34))
                Spacer()
                Button(action: {
                    self.showingNotifications = true
                }) {
                    Image(systemName: "bell.fill")
                }
                Image(systemName: "message.fill")
            }
            .padding()


            // Posts List
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(posts) { post in
                        VStack(alignment: .leading) {
                            // Post Header
                            HStack {
                                Image(systemName: "person.crop.circle.fill") // Profile picture placeholder
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                Text(post.username)
                                Spacer()
                                Image(systemName: "arrowshape.turn.up.right") // Share icon
                            }
                            .padding(.horizontal)

                            // Post Content
                            Rectangle() // This represents the post content, replace it with actual content
                                .foregroundColor(.gray)
                                .aspectRatio(contentMode: .fit)

                            // Post Footer
                            HStack {
                                Image(systemName: "heart") // Heart icon placeholder
                                Image(systemName: "bubble.left") // Comment icon placeholder
                                Image(systemName: "bookmark") // Bookmark icon placeholder
                                Spacer()
                                Button("Rent/Buy") {
                                    // Handle Rent/Buy action
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            leading: Text("FROC").font(.custom("CurvyFontName", size: 24)),
            trailing: Button(action: { self.showingNotifications = true }) {
                Image(systemName: "bell.fill")
            }
        )
        .sheet(isPresented: $showingNotifications) {
            NavigationView {
                NotificationsView(showingNotifications: $showingNotifications)
            }
        }
        
    }
}

//Notification views + Item object data
struct NotificationItem: Identifiable {
    enum NotificationType {
        case comment, purchase, like, rent
    }
    
    var id = UUID()
    var type: NotificationType
    var username: String
    var actionText: String
    var icon: String
}

//struct NotificationCell: View {
//    var notification: NotificationItem
//    
//    var body: some View {
//        HStack {
//            Image(systemName: notification.icon)
//                .resizable()
//                .scaledToFit()
//                .frame(width: 20, height: 20)
//            Text("\(notification.username) \(notification.actionText)")
//            Spacer()
//            
//            // Only show the NavigationLink for rent and purchase notifications
//            if notification.type == .purchase || notification.type == .rent {
//                NavigationLink(destination: FulfillmentView()) {
//                    Spacer() // Push the text to the left side, closer to the arrow
//                    Text("Fulfill")
//                        .foregroundColor(.blue)
//                        .padding(.trailing) // Adjust the trailing padding to move closer to the arrow
//                }
//                .buttonStyle(BorderlessButtonStyle()) // To remove any default styling that may affect layout
//            }
//        }
//    }
//}

struct NotificationCell: View {
    var notification: NotificationItem
    
    var body: some View {
        HStack {
            Image(systemName: notification.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 20)
            Text("\(notification.username) \(notification.actionText)")
            Spacer() // Use Spacer to push all content to the left

            // Conditionally show the NavigationLink for rent and purchase notifications
            if notification.type == .purchase || notification.type == .rent {
                NavigationLink(destination: FulfillmentView()) {
                    Text("Fulfill")
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, alignment: .trailing) // Align text to the trailing edge of the available space
                }
            } else {
                // For other notification types, you might want to keep the space without the button.
                // If you want nothing there, just remove this else clause.
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity) // Ensure the HStack takes the full width of the parent view
    }
}


// Define your NotificationsView with a list of notifications
struct NotificationsView: View {
    @Binding var showingNotifications: Bool
    // Mock data for the notifications list
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
            
            List {
                ForEach(notifications) { item in
                    NotificationCell(notification: item)
                }
            }
            .listStyle(PlainListStyle())
        }
    }
}

// Define the FulfillmentView for the details of the fulfillment process
struct FulfillmentView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            // Fulfillment Header
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
            .padding()
            
            // Your fulfillment content here...
            
            Spacer()
            
            // Buttons at the bottom
            HStack {
                Button("Confirm & Ship") {
                    // Confirm and ship the product
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
            }
        }
        .navigationBarHidden(true)
    }
}

//let notifications = [
//     NotificationItem(type: .comment, username: "Mark", actionText: "commented 'cool'", icon: "bubble.right"),
//     NotificationItem(type: .purchase, username: "Katy", actionText: "wants to buy 'red shorts'", icon: "cart"),
//     NotificationItem(type: .like, username: "@Andrea67", actionText: "liked your post", icon: "heart"),
//     NotificationItem(type: .rent, username: "Jacob", actionText: "wants to rent 'wedding set'", icon: "tag")
// ]
//commands: ctrl i for formatting, command option p for preview, and make sure you have the code for it in contentview

struct ContentView_Previews: PreviewProvider {
     static var previews: some View {
         ContentView()
     }
 }
