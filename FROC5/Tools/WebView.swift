//
//  WebView.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 8/17/24.
//

import WebKit
import Foundation
import JWTKit
import SwiftUI

struct WebView: UIViewRepresentable {
    let htmlFileName: String

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = Bundle.main.url(forResource: htmlFileName, withExtension: "html") {
            let request = URLRequest(url: url)
            uiView.load(request)
        }
    }
}
