//
//  SearchView.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 8/17/24.
//

import Foundation
import SwiftUI

struct SearchView: View {
    @State private var searchText: String = ""
    @State private var showFilters: Bool = false
    @State private var selectedClothingCategories: Set<String> = []
    @State private var selectedSeasonalCollections: Set<String> = []
    @State private var selectedOccasions: Set<String> = []
    @State private var selectedSizes: Set<String> = []
    @State private var selectedColors: Set<String> = []
    @State private var selectedBrands: Set<String> = []
    @State private var selectedGenders: Set<String> = []
    @State private var searchResults: [User] = []
    @State private var isSearching: Bool = false
    @State private var selectedUser: User? = nil
    @State private var navigateToFilteredPosts: Bool = false
    
    @EnvironmentObject var userStore: UserStore
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    HStack {
                        Text("Browse")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.leading)
                            .onTapGesture {
                                self.isSearching = false
                                self.searchText = ""
                            }
                        Spacer()
                    }
                    
                    Divider()
                        .background(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))
                        .frame(height: 5)
                        .padding(.vertical, 5)
                    
                    HStack {
                        TextField("Search...", text: $searchText, onCommit: {
                            performSearch()
                        })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        Button(action: {
                            showFilters.toggle()
                        }) {
                            Image(systemName: "slider.horizontal.3")
                                .padding()
                                .foregroundColor(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))
                        }
                    }
                    
                    if isSearching {
                        List(searchResults, id: \.id) { user in
                            ZStack {
                                // NavigationLink for the user closet view
                                NavigationLink(destination: UserClosetView(user: user)
                                    .environmentObject(userStore)) {
                                        HStack {
                                            if let url = URL(string: user.profilePictureURL) {
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
                                            VStack(alignment: .leading) {
                                                Text(user.username)
                                                    .font(.headline)
                                                Text(user.firstName + " " + user.lastName)
                                                    .font(.subheadline)
                                            }
                                            Spacer()
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle()) // Avoids the default button style
                            }
                        }
                    } else {
                        ScrollView {
                            VStack(alignment: .leading) {
                                Text("Fun Occasions")
                                    .font(.headline)
                                    .padding(.horizontal)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(["Casual", "Going Out", "Work", "Cocktail", "Lounge", "Formal Wear"], id: \.self) { occasion in
                                            CategoryButton(category: occasion, isSelected: false) {
                                                navigateToFilteredPosts = true
                                                selectedOccasions = [occasion]
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 15)
                                }

                                Text("Clothing Categories")
                                    .font(.headline)
                                    .padding(.horizontal)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(["Dresses", "Tops", "Skirts", "Shoes", "Shorts", "Pants", "Sweatshirts", "Jackets", "Jumpsuits", "Jeans", "Full Outfits"], id: \.self) { category in
                                            CategoryButton(category: category, isSelected: false) {
                                                navigateToFilteredPosts = true
                                                selectedClothingCategories = [category]
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 15)
                                }
                                
                                Text("Seasonal Collections")
                                    .font(.headline)
                                    .padding(.horizontal)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(["Fall", "Winter", "Summer", "Spring"], id: \.self) { season in
                                            CategoryButton(category: season, isSelected: false) {
                                                navigateToFilteredPosts = true
                                                selectedSeasonalCollections = [season]
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 15)
                                }
                            }
                        }
                        .sheet(isPresented: $showFilters) {
                            FilterView(
                                selectedClothingCategories: $selectedClothingCategories,
                                selectedSeasonalCollections: $selectedSeasonalCollections,
                                selectedOccasions: $selectedOccasions,
                                selectedSizes: $selectedSizes,
                                selectedColors: $selectedColors,
                                selectedBrands: $selectedBrands,
                                selectedGenders: $selectedGenders,
                                onApply: {
                                    applyFilters()
                                    navigateToFilteredPosts = true
                                }
                            )
                        }
                    }
                }
                NavigationLink(destination: CategoryPostsView(
                    selectedCategories: Array(selectedClothingCategories),
                    selectedSeasons: Array(selectedSeasonalCollections),
                    selectedOccasions: Array(selectedOccasions),
                    selectedSizes: Array(selectedSizes),
                    selectedGenders: Array(selectedGenders),
                    onBack: resetFilters
                )
                .environmentObject(userStore), isActive: $navigateToFilteredPosts) {
                    EmptyView()
                }
            }
            .navigationBarTitle("")
            .navigationBarHidden(true)
        }
    }

    private func resetFilters() {
        selectedClothingCategories.removeAll()
        selectedSeasonalCollections.removeAll()
        selectedOccasions.removeAll()
        selectedSizes.removeAll()
        selectedColors.removeAll()
        selectedBrands.removeAll()
        selectedGenders.removeAll()
    }
    
    private func applyFilters() {
        // Additional logic can be added here if needed
    }
    
    private func performSearch() {
        if searchText.isEmpty {
            self.isSearching = false
            self.searchText = ""
            return
        }

        self.isSearching = true
        self.searchResults = userStore.users.filter {
            $0.username.lowercased().contains(searchText.lowercased()) ||
            $0.firstName.lowercased().contains(searchText.lowercased())
        }
    }
}
