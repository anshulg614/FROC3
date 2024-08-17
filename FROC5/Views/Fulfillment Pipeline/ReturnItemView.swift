//
//  ReturnItemView.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 8/17/24.
//

import Foundation
import SwiftUI

struct ReturnItemView: View {
    @Environment(\.presentationMode) var presentationMode
    let notification: NotificationItem
    @EnvironmentObject var sessionStore: SessionStore
    private let imageHeight: CGFloat = 200 // Consistent height for all images
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 8) {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "arrow.left")
                                .foregroundColor(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))

                            Text("Return Item")
                                .bold()
                                .foregroundColor(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))

                        }
                    }
                    Spacer()
                }
                
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .frame(width: 85, height: 85)
                    .foregroundColor(.green)
                
                Text("Your product is being shipped back to \(sessionStore.currentUser?.address ?? "")!")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if let shipImageUrl = notification.shipImageUrl {
                    VStack(alignment: .center, spacing: 0) {
                        infoBox(label: "Proof of Shipment:", value: "")
                            .font(.headline)
                        ZoomableImageView(url: URL(string: shipImageUrl), frameHeight: imageHeight)
                            .frame(height: imageHeight)
                            .padding()
                    }
                } else {
                    Text("No shipment proof available yet.")
                        .font(.subheadline)
                        .padding(.horizontal)
                }
                
                infoBox(label: "Product Info:", value: notification.productInfo)
                infoBox(label: "Price:", value: String(format: "$%.2f", notification.price))
                infoBox(label: "Size:", value: notification.size)
                infoBox(label: "Duration:", value: notification.duration)
                
                let currentDate = Date()
                let expectedArrivalDate = Calendar.current.date(byAdding: .day, value: 3, to: currentDate)!
                
                infoBox(label: "Expected Arrival Date:", value: formattedDate(expectedArrivalDate))
                
                TabView {
                    ForEach(notification.imageUrls, id: \.self) { imageUrl in
                        ZoomableImageView(url: URL(string: imageUrl), frameHeight: imageHeight)
                            .frame(height: imageHeight)
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .frame(height: imageHeight)
                
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    @ViewBuilder
    private func infoBox(label: String, value: String) -> some View {
        VStack {
            HStack {
                Text(label)
                    .font(.headline)
                Spacer()
                Text(value)
                    .font(.headline)
            }
            .padding(.horizontal)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

