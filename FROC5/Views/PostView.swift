//
//  PostView.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 8/17/24.
//

import Foundation
import SwiftUI
import Firebase

struct PostView: View {
    @State var colord: Color = .gray
    @State var colorc: Color = .gray
    @State private var selectedImages: [UIImage] = []
    @State private var postCaption: String = "Enter caption here..."
    @State private var saleOption: Post.SaleOption = .purchase
    @State private var purchasePrice: String = ""
    @State private var rentPrice: String = ""
    @State private var selectedSizes: [String] = []
    @State private var selectedClothingCategories: [String] = []
    @State private var selectedSeasonalCollections: [String] = []
    @State private var selectedOccasions: [String] = []
    @State private var productDescription: String = "Describe the product..."
    @State private var color: String = ""
    @State private var title: String = ""
    @State private var gender: String = "unisex"
    @State private var showColorPicker: Bool = false
    @EnvironmentObject var postStore: PostStore
    @EnvironmentObject var sessionStore: SessionStore
    @Environment(\.presentationMode) var presentationMode

    let colors = ["Red", "Blue", "Green", "Yellow", "Black", "White", "Pink", "Purple", "Orange", "Gray", "Brown"]

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }

            ScrollView {
                VStack {
                    ImageSelectionView(selectedImages: $selectedImages)

                    TextEditor(text: $postCaption)
                        .frame(height: 65)
                        .cornerRadius(8)
                        .foregroundColor(colorc)
                        .onTapGesture {
                            if postCaption == "Enter caption here..." {
                                postCaption = ""
                            }
                            colorc = .primary
                        }
                        .padding()

                    Picker("Options", selection: $saleOption) {
                        ForEach(Post.SaleOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .accentColor(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))
                    .padding()
                    .onTapGesture {
                        // Force a tap to change the value
                        if let index = Post.SaleOption.allCases.firstIndex(of: saleOption) {
                            saleOption = Post.SaleOption.allCases[(index + 1) % Post.SaleOption.allCases.count]
                        }
                    }

                    if saleOption == .purchaseOrRent || saleOption == .purchase {
                        TextField("Purchase Price", text: $purchasePrice)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                    }

                    if saleOption == .purchaseOrRent || saleOption == .rent {
                        TextField("Rent Price (per day)", text: $rentPrice)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                    }

                    TextField("Product Title", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    TextEditor(text: $productDescription)
                        .frame(height: 65)
                        .cornerRadius(8)
                        .foregroundColor(colord)
                        .onTapGesture {
                            if productDescription == "Describe the product..." {
                                productDescription = ""
                            }
                            colord = .primary
                        }
                        .padding()
                    
                    HStack {
                        if !color.isEmpty {
                            Circle()
                                .fill(colorFromName(color))
                                .frame(width: 20, height: 20)
                                .padding(.horizontal)
                        }
                        Text(color.isEmpty ? "Select Color" : color)
                            .padding(.horizontal)
                        Spacer()
                        Button(action: {
                            showColorPicker.toggle()
                        }) {
                            Image(systemName: "chevron.down")
                                .padding(.horizontal)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
                    .sheet(isPresented: $showColorPicker) {
                        ColorPickerView(selectedColor: $color, colors: colors)
                            .presentationDetents([.medium]) // This line makes the sheet half the screen height
                    }
                    .padding(.horizontal)

                    HStack {
                        Button(action: { gender = "Man" }) {
                            HStack {
                                Circle()
                                    .fill(gender == "Man" ? Color.primary : Color.clear)
                                    .frame(width: 12, height: 12)
                                    .overlay(Circle().stroke(Color.primary, lineWidth: 1))
                                Text("Man")
                            }
                        }

                        Button(action: { gender = "Woman" }) {
                            HStack {
                                Circle()
                                    .fill(gender == "Woman" ? Color.primary : Color.clear)
                                    .frame(width: 12, height: 12)
                                    .overlay(Circle().stroke(Color.primary, lineWidth: 1))
                                Text("Woman")
                            }
                        }

                        Button(action: { gender = "unisex" }) {
                            HStack {
                                Circle()
                                    .fill(gender == "unisex" ? Color.primary : Color.clear)
                                    .frame(width: 12, height: 12)
                                    .overlay(Circle().stroke(Color.primary, lineWidth: 1))
                                Text("unisex")
                            }
                        }
                    }
                    .padding(.horizontal)

                    Divider()
                        .background(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))
                        .padding(.horizontal)

                    SizeSelectionView(selectedSizes: $selectedSizes)
                        .padding(.horizontal, 10) // Added small horizontal padding

                    Divider()
                        .background(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))
                        .padding(.horizontal)

                    CategorySelectionView(title: "Fun Occasions", categories: ["Casual", "Going Out", "Work", "Cocktail", "Lounge", "Formal Wear"], selectedCategories: $selectedOccasions)
                        .padding(.horizontal, 10) // Added small horizontal padding

                    Divider()
                        .background(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))
                        .padding(.horizontal)

                    CategorySelectionView(title: "Clothing Categories", categories: ["Dresses", "Tops", "Full Outfits", "Skirts", "Shorts", "Pants", "Sweatshirts", "Jackets", "Jumpsuits", "Jeans", "Shoes"], selectedCategories: $selectedClothingCategories)
                        .padding(.horizontal, 10) // Added small horizontal padding

                    Divider()
                        .background(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))
                        .padding(.horizontal)

                    CategorySelectionView(title: "Seasonal Collections", categories: ["Fall", "Winter", "Summer", "Spring"], selectedCategories: $selectedSeasonalCollections)
                        .padding(.horizontal, 10) // Added small horizontal padding

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
                            let finalPostCaption = postCaption.isEmpty ? "Default caption" : postCaption
                            let finalProductDescription = productDescription.isEmpty ? "Default product description" : productDescription
                            let finalPurchasePrice = purchasePrice.isEmpty ? "0" : purchasePrice
                            let finalRentPrice = rentPrice.isEmpty ? "0" : rentPrice

                            let newPost = Post(
                                user: currentUser,
                                imageUrls: [],
                                caption: finalPostCaption,
                                saleOption: saleOption,
                                purchasePrice: finalPurchasePrice,
                                rentPrice: finalRentPrice,
                                sizes: selectedSizes,
                                description: finalProductDescription,
                                numberOfLikes: 0,
                                likedBy: [],
                                comments: [],
                                clothingCategories: selectedClothingCategories,
                                seasonalCollections: selectedSeasonalCollections,
                                occasions: selectedOccasions,
                                color: color,
                                title: title,
                                gender: gender
                            )
                            postStore.addPost(newPost, images: selectedImages)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Post")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(selectedImages.isEmpty ? Color.gray : Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))
                        .cornerRadius(10)
                        .disabled(selectedImages.isEmpty)
                    }
                }
                .background(Color.clear)
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
    }
}

struct ColorPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedColor: String
    let colors: [String]

    var body: some View {
        NavigationView {
            List {
                ForEach(colors, id: \.self) { color in
                    Button(action: {
                        selectedColor = color
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Circle()
                                .fill(colorFromName(color))
                                .frame(width: 20, height: 20)
                            Text(color)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
        }
    }
}

func colorFromName(_ colorName: String) -> Color {
    switch colorName {
    case "Red":
        return .red
    case "Blue":
        return .blue
    case "Green":
        return .green
    case "Yellow":
        return .yellow
    case "Black":
        return .black
    case "White":
        return .white
    case "Pink":
        return .pink
    case "Purple":
        return .purple
    case "Orange":
        return .orange
    case "Gray":
        return .gray
    case "Brown":
        return .brown
    default:
        return .clear
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
                .background(isSelected ? Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0) : Color.clear)
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(lineWidth: 1)
                        .stroke(isSelected ? Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0) : Color.gray)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CategorySelectionView: View {
    var title: String
    var categories: [String]
    @Binding var selectedCategories: [String]
    
    var body: some View {
        VStack(alignment: .leading) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(categories, id: \.self) { category in
                        CategoryButtons(category: category, isSelected: selectedCategories.contains(category)) {
                            if selectedCategories.contains(category) {
                                selectedCategories.removeAll { $0 == category }
                            } else {
                                selectedCategories.append(category)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity) // Make the VStack take full width
    }
}

struct CategoryButtons: View {
    var category: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) { // Reduce spacing between image and text
                Text(iconForCategory(category))
                    .font(.system(size: 20)) // Adjust the size of the emoji
                    .frame(width: 30, height: 20) // Adjust the size of the image
                    .foregroundColor(isSelected ? .white : .primary) // Change image color based on selection
                Text(category)
                    .font(.caption2) // Use a smaller font
                    .lineLimit(1) // Ensure the text doesn't wrap
                    .foregroundColor(isSelected ? .white : .primary) // Change text color based on selection
            }
            .padding(.horizontal, 8) // Reduce horizontal padding
            .padding(.vertical, 4) // Reduce vertical padding
            .background(isSelected ? Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0) : Color(UIColor.systemBackground)) // Change background color based on selection
            .cornerRadius(10)
        }
    }

    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Pants":
            return "👖"
        case "Shirts":
            return "👕"
        case "Shoes":
            return "👟"
        case "Dresses":
            return "👗"
        case "Tops":
            return "👚"
        case "Skirts":
            return "👯‍♀️"
        case "Shorts":
            return "🩳"
        case "Sweatshirts":
            return "👚"
        case "Jackets":
            return "🧥"
        case "Jumpsuits":
            return "🕺"
        case "Jeans":
            return "👖"
        case "Full Outfits":
            return "🧍"
        case "Fall":
            return "🍂"
        case "Winter":
            return "❄️"
        case "Summer":
            return "☀️"
        case "Spring":
            return "🌸"
        case "Casual":
            return "😎"
        case "Going Out":
            return "🌃"
        case "Work":
            return "💼"
        case "Cocktail":
            return "🍸"
        case "Lounge":
            return "☁️"
        case "Formal Wear":
            return "👔"
        default:
            return "❓"
        }
    }
}

