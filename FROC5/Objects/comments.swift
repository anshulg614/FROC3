//
//  comments.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 8/17/24.
//

import Foundation
import SwiftUI
import Firebase

struct Comment: Identifiable {
    let id: String
    let userId: String
    let username: String
    let profilePictureURL: String
    let text: String
    let timestamp: Timestamp
}
