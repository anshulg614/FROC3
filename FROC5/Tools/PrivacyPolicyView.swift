//
//  PrivacyPolicyView.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 8/17/24.
//

import Foundation
import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        WebView(htmlFileName: "privacyPolicy")
            .navigationBarTitle("Privacy Policy", displayMode: .inline)
            .padding(.horizontal, 16) // Add padding to increase margins
    }
}
