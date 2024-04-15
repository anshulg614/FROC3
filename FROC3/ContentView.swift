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

//struct ViewClosetsView: View {
//    // Sample posts data
//    let posts = [Post(username: "user1"), Post(username: "user2")]
//    @State private var showingNotifications = false
//    
//    var body: some View {
//        VStack {
//            // Header
//            HStack {
//                Text("FROC")
//                    .font(.custom("CurvyFontName", size: 34))
//                Spacer()
//                Button(action: {
//                    self.showingNotifications = true
//                }) {
//                    Image(systemName: "bell.fill")
//                }
//                Image(systemName: "message.fill")
//            }
//            .padding()
//
//
//            // Posts List
//            ScrollView {
//                VStack(spacing: 20) {
//                    ForEach(posts) { post in
//                        VStack(alignment: .leading) {
//                            // Post Header
//                            HStack {
//                                Image(systemName: "person.crop.circle.fill") // Profile picture placeholder
//                                    .resizable()
//                                    .frame(width: 50, height: 50)
//                                Text(post.username)
//                                Spacer()
//                                Image(systemName: "arrowshape.turn.up.right") // Share icon
//                            }
//                            .padding(.horizontal)
//
//                            // Post Content
//                            Rectangle() // This represents the post content, replace it with actual content
//                                .foregroundColor(.gray)
//                                .aspectRatio(contentMode: .fit)
//
//                            // Post Footer
//                            HStack {
//                                Image(systemName: "heart") // Heart icon placeholder
//                                Image(systemName: "bubble.left") // Comment icon placeholder
//                                Image(systemName: "bookmark") // Bookmark icon placeholder
//                                Spacer()
//                                Button("Rent/Buy") {
//                                    // Handle Rent/Buy action
//                                }
//                            }
//                            .padding(.horizontal)
//                        }
//                        .padding(.bottom)
//                    }
//                }
//            }
//        }
//        .navigationBarTitleDisplayMode(.inline)
//        .navigationBarItems(
//            leading: Text("FROC").font(.custom("CurvyFontName", size: 24)),
//            trailing: Button(action: { self.showingNotifications = true }) {
//                Image(systemName: "bell.fill")
//            }
//        )
//        .sheet(isPresented: $showingNotifications) {
//            NavigationView {
//                NotificationsView(showingNotifications: $showingNotifications)
//            }
//        }
//        
//    }
//}


struct ViewClosetsView: View {
    // Sample posts data
    let posts = [Post(username: "user1"), Post(username: "user2")]
    @State private var showingNotifications = false
    @State private var showingShippingPayment = false // State to present the ShippingPaymentView
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Text("FROC")
                    .font(.custom("CurvyFontName", size: 34)) // Replace "CurvyFontName" with your actual font name
                Spacer()
                Button(action: {
                    self.showingNotifications = true
                }) {
                    Image(systemName: "bell.fill") // Notification bell icon
                }
                Image(systemName: "message.fill") // Messages icon
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
                                    showingShippingPayment = true // Trigger the presentation of ShippingPaymentView
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
        .sheet(isPresented: $showingShippingPayment) {
            // Pass actual product image, price, and description
            ShippingPaymentView(
                productImage: UIImage(systemName: "tshirt.fill")!, // Placeholder for actual product image
                price: "$49.99",
                productInfo: "Red shorts - Size M"
                // Pass other necessary data here
            )
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
                // Add more space at the top if necessary
                Spacer(minLength: 20) // This adds space at the top inside the ScrollView

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

    var productImage: UIImage // Placeholder for actual image
    var price: String
    var productInfo: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) { // Adjust
                Spacer(minLength: 10) // This adds space at the top inside the ScrollViewspacing as needed
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
                HStack {
                    Image(uiImage: productImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                    VStack(alignment: .leading) {
                        Text(price)
                            .font(.headline)
                        Text(productInfo)
                            .font(.subheadline)
                    }
                    Spacer()
                }
                .padding(.horizontal)

                // Rent or Buy Toggle
                Toggle(isOn: $isRent) {
                    Text(isRent ? "Rent" : "Buy")
                        .font(.headline)
                }
                .padding(.horizontal)

                // Rent Duration Picker
                if isRent {
                    Picker("Rent Duration", selection: $rentDuration) {
                        ForEach(1...10, id: \.self) { week in
                            Text("\(week) week\(week > 1 ? "s" : "")")
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
                    let username = "venmo-username" // Replace with the actual Venmo username
                    let amount = "1.00" // The amount to pay
                    let note = "Payment for goods" // A note for the payment

                    // Create the URL string for Venmo
                    let urlString = "venmo://paycharge?txn=pay&recipients=\(username)&amount=\(amount)&note=\(note)"

                    // Encode the URL string
                    let encodedUrlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)

                    // Check if the URL can be opened
                    if let url = URL(string: encodedUrlString!), UIApplication.shared.canOpenURL(url) {
                        // Open the URL
                        UIApplication.shared.open(url)
                    } else {
                        // Handle the error, such as showing an alert to the user
                        print("Cannot open Venmo")
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
