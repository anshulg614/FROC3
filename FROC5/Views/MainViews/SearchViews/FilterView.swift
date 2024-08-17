//
//  FilterView.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 8/17/24.
//

import Foundation
import SwiftUI

struct FilterView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedClothingCategories: Set<String>
    @Binding var selectedSeasonalCollections: Set<String>
    @Binding var selectedOccasions: Set<String>
    @Binding var selectedSizes: Set<String>
    @Binding var selectedColors: Set<String>
    @Binding var selectedBrands: Set<String>
    @Binding var selectedGenders: Set<String>
    var onApply: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Clothing Categories")) {
                    ForEach(["Dresses", "Tops", "Skirts", "Shoes", "Shorts", "Pants", "Sweatshirts", "Jackets", "Jumpsuits", "Jeans", "Full Outfits"], id: \.self) { category in
                        MultipleSelectionRow(title: category, isSelected: selectedClothingCategories.contains(category)) {
                            toggleSelection(item: category, selection: &selectedClothingCategories)
                        }
                    }
                }
                Section(header: Text("Seasonal Collections")) {
                    ForEach(["Fall", "Winter", "Summer", "Spring"], id: \.self) { collection in
                        MultipleSelectionRow(title: collection, isSelected: selectedSeasonalCollections.contains(collection)) {
                            toggleSelection(item: collection, selection: &selectedSeasonalCollections)
                        }
                    }
                }
                Section(header: Text("Fun Occasions")) {
                    ForEach(["Casual", "Going Out", "Work", "Cocktail", "Lounge", "Formal Wear"], id: \.self) { occasion in
                        MultipleSelectionRow(title: occasion, isSelected: selectedOccasions.contains(occasion)) {
                            toggleSelection(item: occasion, selection: &selectedOccasions)
                        }
                    }
                }
                Section(header: Text("Sizes")) {
                    ForEach(["S", "M", "L", "XL", "wS", "wM", "wL", "wXL"], id: \.self) { size in
                        MultipleSelectionRow(title: size, isSelected: selectedSizes.contains(size)) {
                            toggleSelection(item: size, selection: &selectedSizes)
                        }
                    }
                }
                Section(header: Text("Colors")) {
                    ForEach(["Red", "Blue", "Green", "Yellow", "Black", "White", "Pink", "Purple", "Orange", "Gray", "Brown"], id: \.self) { color in
                        MultipleSelectionRow(title: color, isSelected: selectedColors.contains(color)) {
                            toggleSelection(item: color, selection: &selectedColors)
                        }
                    }
                }
                Section(header: Text("Gender")) {
                    ForEach(["Man", "Woman"], id: \.self) { gender in
                        MultipleSelectionRow(title: gender, isSelected: selectedGenders.contains(gender)) {
                            toggleSelection(item: gender, selection: &selectedGenders)
                        }
                    }
                }
            }
            .navigationBarTitle("Filters", displayMode: .inline)
            .navigationBarItems(trailing: Button("Apply") {
                onApply()
                presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0)))
        }
    }

    private func toggleSelection(item: String, selection: inout Set<String>) {
        if selection.contains(item) {
            selection.remove(item)
        } else {
            selection.insert(item)
        }
    }
}
