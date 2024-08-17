//
//  Categories.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 8/17/24.
//

import Foundation
import SwiftUI

struct CategoryPostsView: View {
    let selectedCategories: [String]
    let selectedSeasons: [String]
    let selectedOccasions: [String]
    let selectedSizes: [String]
    let selectedGenders: [String]
    var onBack: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var postStore: PostStore
    @EnvironmentObject var sessionStore: SessionStore

    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(postsFilteredByCategory(), id: \.id) { post in
                    PostDataView(post: post)
                        .environmentObject(postStore)
                        .environmentObject(sessionStore)
                }
            }
        }
        .navigationTitle("Explore")
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            onBack()
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.primary)
        })
    }

    private func postsFilteredByCategory() -> [Post] {
        return postStore.posts.filter { post in
            let matchesCategories = selectedCategories.isEmpty || !post.clothingCategories.isDisjoint(with: selectedCategories)
            let matchesSeasons = selectedSeasons.isEmpty || !post.seasonalCollections.isDisjoint(with: selectedSeasons)
            let matchesOccasions = selectedOccasions.isEmpty || !post.occasions.isDisjoint(with: selectedOccasions)
            let matchesSizes = selectedSizes.isEmpty || !post.sizes.isDisjoint(with: selectedSizes)
            let matchesGenders = selectedGenders.isEmpty || selectedGenders.contains(post.gender)
            
            return matchesCategories && matchesSeasons && matchesOccasions && matchesSizes && matchesGenders
        }
    }
}

// Helper extension to check if two sets have at least one common element
extension Array where Element: Hashable {
    func isDisjoint(with other: [Element]) -> Bool {
        return Set(self).isDisjoint(with: Set(other))
    }
}

struct MultipleSelectionRow: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                if isSelected {
                    Spacer()
                    Image(systemName: "checkmark")
                }
            }
            .foregroundColor(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))
        }
    }
}

struct CategoryButton: View {
    var category: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(emojiForCategory(category))
                    .font(.largeTitle)
                    .frame(width: 60, height: 60)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
                Text(category)
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))
            .cornerRadius(10)
        }
    }

    private func emojiForCategory(_ category: String) -> String {
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
            return "👕"
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
