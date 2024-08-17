//
//  TermsOfService.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 8/17/24.
//

import Foundation
import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        WebView(htmlFileName: "termsOfService")
            .navigationBarTitle("Terms of Service", displayMode: .inline)
            .padding(.horizontal, 16) // Add padding to increase margins
    }
}
