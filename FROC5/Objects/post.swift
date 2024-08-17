//
//  post.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 8/17/24.
//

import Foundation
import Firebase
import SwiftUI

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
    var timestamp: Timestamp
    var clothingCategories: [String]
    var seasonalCollections: [String]
    var occasions: [String]
    var color: String
    var brand: String
    var title: String
    var gender: String

    enum SaleOption: String, CaseIterable, Identifiable {
        case purchase = "Purchase"
        case rent = "Rent"
        case purchaseOrRent = "Purchase or Rent"
        
        var id: String { self.rawValue }
    }

    init(id: String = UUID().uuidString, user: User, imageUrls: [String] = [], caption: String = "", saleOption: SaleOption = .purchase, purchasePrice: String = "", rentPrice: String = "", sizes: [String] = [], description: String = "", numberOfLikes: Int = 0, likedBy: [String] = [], comments: [Comment] = [], timestamp: Timestamp = Timestamp(), clothingCategories: [String] = [], seasonalCollections: [String] = [], occasions: [String] = [], color: String = "", brand: String = "", title: String = "", gender: String = "") {
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
        self.timestamp = timestamp
        self.clothingCategories = clothingCategories
        self.seasonalCollections = seasonalCollections
        self.occasions = occasions
        self.color = color
        self.brand = brand
        self.title = title
        self.gender = gender
    }
}
