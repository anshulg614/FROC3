//
//  NotificationManager.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 8/16/24.
//

import Foundation
import Firebase
import WebKit
import Foundation
import JWTKit

struct JWTPayloadStruct: JWTPayload {
    let iss: String
    let scope: String
    let aud: String
    let iat: Int
    let exp: Int

    // Function to verify the payload
    func verify(using signer: JWTSigner) throws {
        // Implement any additional payload verification here if needed
    }
}

class NotificationManager {
    private let db = Firestore.firestore()
    private let projectId = "froc5-cc696" // Replace with your Firebase project ID
    private let serviceAccountFilePath = Bundle.main.path(forResource: "froc5-cc696-firebase-adminsdk-yu5v0-29ca05333c", ofType: "json")! // Adjust the path as needed

    func sendPushNotification(to userId: String, message: String) {
        print("Sending push notification to user: \(userId)")
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists, let data = document.data() {
                if let token = data["fcmToken"] as? String {
                    print("FCM token found: \(token)")
                    self.fetchAccessToken { accessToken in
                        guard let accessToken = accessToken else {
                            print("Error fetching access token")
                            return
                        }
                        self.sendPushNotificationToToken(token: token, message: message, accessToken: accessToken)
                    }
                } else {
                    print("FCM token not found for user: \(userId)")
                }
            } else {
                print("User document does not exist for userId: \(userId)")
            }
        }
    }

    private func fetchAccessToken(completion: @escaping (String?) -> Void) {
        print("Fetching access token")
        guard let url = URL(string: "https://oauth2.googleapis.com/token") else {
            completion(nil)
            return
        }

        guard let serviceAccountData = try? Data(contentsOf: URL(fileURLWithPath: serviceAccountFilePath)),
              let serviceAccountJSON = try? JSONSerialization.jsonObject(with: serviceAccountData, options: []) as? [String: Any] else {
            completion(nil)
            return
        }

        guard let clientEmail = serviceAccountJSON["client_email"] as? String,
              let privateKey = serviceAccountJSON["private_key"] as? String else {
            completion(nil)
            return
        }

        let now = Int(Date().timeIntervalSince1970)
        let payload = JWTPayloadStruct(
            iss: clientEmail,
            scope: "https://www.googleapis.com/auth/firebase.messaging",
            aud: "https://oauth2.googleapis.com/token",
            iat: now,
            exp: now + 3600
        )

        guard let jwt = createJWT(payload: payload, privateKey: privateKey) else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=\(jwt)".data(using: .utf8)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil,
                  let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let accessToken = json["access_token"] as? String else {
                completion(nil)
                return
            }
            print("Access token fetched successfully")
            completion(accessToken)
        }
        task.resume()
    }

    private func createJWT(payload: JWTPayloadStruct, privateKey: String) -> String? {
        guard let privateKeyData = privateKey.data(using: .utf8) else {
            print("Error converting private key to Data")
            return nil
        }

        do {
            let rsaKey = try RSAKey.private(pem: privateKeyData)
            let signer = JWTSigner.rs256(key: rsaKey)
            let jwt = try signer.sign(payload)
            return jwt
        } catch {
            print("Error creating JWT: \(error)")
            return nil
        }
    }

    private func sendPushNotificationToToken(token: String, message: String, accessToken: String) {
        guard let url = URL(string: "https://fcm.googleapis.com/v1/projects/\(projectId)/messages:send") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let payload: [String: Any] = [
            "message": [
                "token": token,
                "notification": [
                    "title": "FROC",
                    "body": message
                ]
            ]
        ]

        let jsonData = try! JSONSerialization.data(withJSONObject: payload, options: [])
        request.httpBody = jsonData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending push notification: \(error)")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("Unexpected response sending push notification: \(String(describing: response))")
                return
            }
            print("Push notification sent successfully.")
        }
        task.resume()
    }
}

