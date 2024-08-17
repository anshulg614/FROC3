//
//  CountdownTimerView.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 8/17/24.
//

import Foundation
import SwiftUI

struct CountdownTimerView: View {
    @State private var timeRemaining: TimeInterval
    let endDate: Date
    
    init(endDate: Date) {
        self.endDate = endDate
        self._timeRemaining = State(initialValue: endDate.timeIntervalSince(Date()))
    }
    
    var body: some View {
        VStack {
            Text(timeString(from: timeRemaining))
                .font(.largeTitle)
                .padding()
                .background(Color(hue: 0.9, saturation: 0.4, brightness: 0.9, opacity: 0.5))
                .cornerRadius(10)
                .onAppear {
                    startTimer()
                }
        }
    }
    
    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            let now = Date()
            timeRemaining = endDate.timeIntervalSince(now)
            
            if timeRemaining <= 0 {
                timer.invalidate()
            }
        }
    }
    
    private func timeString(from time: TimeInterval) -> String {
        let days = Int(time) / 86400
        let hours = (Int(time) % 86400) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d : %02d : %02d : %02d", days, hours, minutes, seconds)
    }
}
