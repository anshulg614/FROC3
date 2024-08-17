//
//  InfoRow.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 8/17/24.
//

//Used in the Fulfillment Pipeline view
import Foundation
import SwiftUI

struct InfoRow: View {
    var label: String
    var value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .bold()
        }
        .padding(.horizontal)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}
