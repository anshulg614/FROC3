//
//  SettingsView.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 8/17/24.
//

import Foundation
import SwiftUI
import PhotosUI

struct SettingsView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @EnvironmentObject var userStore: UserStore
    @State private var username: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var address: String = ""
    @State private var venmo: String = ""
    @State private var errorMessage: String?
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil
    @State private var showingImagePicker = false
    @State private var showConfirmation = false
    @State private var showDeleteAccountConfirmation = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ZStack {
                DismissingKeyboardView()
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
                        TextField("Venmo Username", text: $venmo)
                    }

                    Section {
                        Button("Save Changes") {
                            saveChanges()
                        }
                        .foregroundColor(.blue)

                        Button("Sign Out") {
                            sessionStore.signOut()
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(.red)
                    }

                    Section(header: Text("Support Information")) {
                        Text("FROC Team's Email: frocapp@gmail.com")
                        Text("For support on your order, not receiving a package, or payment issues, please reach out to us via email. We are glad to help you handle all of it.")
                            .foregroundColor(.gray)
                        
                        Button("Privacy Policy") {
                            showingPrivacyPolicy = true
                        }
                        .foregroundColor(.blue)
                        
                        Button("Terms of Service") {
                            showingTermsOfService = true
                        }
                        .foregroundColor(.blue)

                    }
                        
                    Button("Delete Account") {
                        showDeleteAccountConfirmation = true
                    }
                    .foregroundColor(.red)

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
                .alert(isPresented: $showDeleteAccountConfirmation) {
                    Alert(
                        title: Text("Delete Account"),
                        message: Text("Are you sure you want to delete your account? This action cannot be undone."),
                        primaryButton: .destructive(Text("Delete")) {
                            sessionStore.deleteAccount { success in
                                if success {
                                    presentationMode.wrappedValue.dismiss()
                                } else {
                                    errorMessage = "Failed to delete account."
                                }
                            }
                        },
                        secondaryButton: .cancel()
                    )
                }
                .sheet(isPresented: $showingPrivacyPolicy) {
                    PrivacyPolicyView()
                }

                .sheet(isPresented: $showingTermsOfService) {
                    TermsOfServiceView()
                }


                if showConfirmation {
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.green)
                        Text("Changes saved!")
                            .font(.title)
                            .bold()
                            .foregroundColor(.black)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white.opacity(0.3))
                    .transition(.opacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation {
                                self.showConfirmation = false
                                self.presentationMode.wrappedValue.dismiss()
                            }
                        }
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
        venmo = currentUser.venmo
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
        currentUser.venmo = venmo
        
        print("Attempting to save changes:")  // Debugging
        print("First Name: \(currentUser.firstName)")
        print("Last Name: \(currentUser.lastName)")
        print("Address: \(currentUser.address)")
        print("Username: \(currentUser.username)")
        print("Venmo: \(currentUser.venmo)")
        
        if let profileImage = profileImage {
            userStore.uploadProfileImage(image: profileImage) { url in
                if let url = url {
                    currentUser.profilePictureURL = url.absoluteString
                    self.updateUserAndDismiss(currentUser)
                } else {
                    self.errorMessage = "Failed to upload profile picture."
                }
            }
        }
        self.updateUserAndDismiss(currentUser)
    }
    
    func updateUserAndDismiss(_ currentUser: User) {
        userStore.updateUser(currentUser) { error in
            if let error = error {
                self.errorMessage = "Failed to update user: \(error.localizedDescription)"
            } else {
                DispatchQueue.main.async {
                    print("User updated!")  // Debugging
                    print("Updated First Name: \(currentUser.firstName)")
                    print("Updated Last Name: \(currentUser.lastName)")
                    print("Updated Address: \(currentUser.address)")
                    print("Updated Username: \(currentUser.username)")
                    print("Updated Venmo: \(currentUser.venmo)")
                    
                    self.sessionStore.currentUser = currentUser // Update the current user in session store
                    withAnimation {
                        self.showConfirmation = true
                    }
                }
            }
        }
    }
}

