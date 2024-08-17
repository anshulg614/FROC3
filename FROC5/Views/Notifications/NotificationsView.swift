//
//  NotificationsView.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 8/17/24.
//

import Foundation
import SwiftUI
import Firebase
import PhotosUI

struct NotificationsView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @Binding var showingNotifications: Bool
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    self.showingNotifications = false
                }) {
                    HStack {
                        Image(systemName: "arrow.left")
                            .foregroundColor(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))

                        Text("Notifications").bold()
                            .foregroundColor(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))
                    }
                }
                Spacer()
                Button(action: {
                    if let userId = sessionStore.currentUser?.id {
                        sessionStore.fetchNotifications(userId: userId)
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))
                }
            }
            .padding()
            
            NotificationList(notifications: sessionStore.currentUser?.notifications ?? [])
        }
    }
}

struct NotificationList: View {
    var notifications: [NotificationItem]
    
    var body: some View {
        Group {
            if notifications.isEmpty {
                Text("No notifications available")
                    .padding()
            } else {
                List {
                    ForEach(notifications.sorted(by: { $0.timestamp > $1.timestamp })) { item in
                        NotificationCell(notification: item)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
}

struct NotificationCell: View {
    var notification: NotificationItem
    
    var body: some View {
        HStack {
            Image(systemName: notification.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 20)
            Text("@\(notification.username) \(notification.actionText)")
            Spacer()
            
            if notification.type == .purchase || notification.type == .rent || notification.type == .return {
                NavigationLink(destination: destinationView(for: notification)) {
                    Text("View")
                        .foregroundColor(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 1.0))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private func destinationView(for notification: NotificationItem) -> some View {
        if notification.actionText.contains("admin") {
            AdminApprovalView(notification: notification)
        } else if notification.actionText.contains("confirmed your order!") {
            BuyerOrRenterNotificationView(notification: notification)
        } else if notification.actionText.contains("wants") {
            FulfillmentView(notification: notification)
        } else if notification.type == .return {
            ReturnItemView(notification: notification)
        } else {
            EmptyView()
        }
    }
}

