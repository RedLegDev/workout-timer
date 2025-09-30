//
//  WorkoutTimerView.swift
//  Workout Timer Watch App
//
//  Created by Matt Wagner on 9/24/25.
//

import SwiftUI
import WatchKit
import AVFoundation

enum WorkoutState {
    case ready
    case exercising
    case resting
}

@Observable
class WorkoutTimer {
    var currentSet = 0
    var state: WorkoutState = .ready
    private var stateStartTime: Date?
    private var timer: Timer?
    var audioEnabled = true
    private var _updateTrigger = 0 // Private trigger for UI updates
    
    // Computed properties for current elapsed time
    var currentTime: TimeInterval {
        _ = _updateTrigger // Access the trigger to make this observable
        guard let startTime = stateStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    func startExercise() {
        state = .exercising
        currentSet += 1
        stateStartTime = Date()
        
        WKInterfaceDevice.current().play(.start)
        startTimer()
    }
    
    func completeSet() {
        state = .resting
        stateStartTime = Date()
        
        WKInterfaceDevice.current().play(.success)
        // Timer continues running for rest period - no need to restart
    }
    
    func startNextSet() {
        state = .exercising
        currentSet += 1
        stateStartTime = Date()
        
        WKInterfaceDevice.current().play(.start)
        // Timer continues running - no need to restart
    }
    
    func reset() {
        stopTimer()
        currentSet = 0
        state = .ready
        stateStartTime = nil
        
        WKInterfaceDevice.current().play(.click)
    }
    
    func stop() {
        stopTimer()
        state = .ready
        stateStartTime = nil
        
        WKInterfaceDevice.current().play(.stop)
    }
    
    func toggleAudio() {
        audioEnabled.toggle()
    }
    
    private func startTimer() {
        // Stop any existing timer first
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // Trigger UI updates by changing an observable property
            self._updateTrigger += 1
            
            let time = self.currentTime
            
            // Rest cue at 90 seconds during rest
            if self.state == .resting && Int(time) == 90 {
                WKInterfaceDevice.current().play(.notification)
            }
            
            // Gentle haptic every 30 seconds
            if Int(time) % 30 == 0 && time > 0 {
                WKInterfaceDevice.current().play(.click)
            }
            
            // Audio cue every minute if enabled
            if self.audioEnabled && Int(time) % 60 == 0 && time > 0 {
                WKInterfaceDevice.current().play(.click)
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

struct WorkoutTimerView: View {
    @State private var workoutTimer = WorkoutTimer()
    
    var body: some View {
        VStack(spacing: 8) {
            // Action Buttons - Top for easy access
            VStack(spacing: 6) {
                switch workoutTimer.state {
                case .ready:
                    Button("Start Set") {
                        workoutTimer.startExercise()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                case .exercising:
                    Button("Complete Set") {
                        workoutTimer.completeSet()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.orange)
                    
                case .resting:
                    Button("Start Next Set") {
                        workoutTimer.startNextSet()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.green)
                }
                
                // Secondary buttons
                HStack(spacing: 8) {
                    if workoutTimer.currentSet > 0 {
                        Button("New Exercise") {
                            workoutTimer.reset()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.red)
                    }
                    
                    // Audio toggle button
                    Button(workoutTimer.audioEnabled ? "🔊" : "🔇") {
                        workoutTimer.toggleAudio()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.blue)
                }
            }
            .padding(.horizontal)
            
            Divider()
            
            // Set Counter and Timer Display - Side by Side
            HStack(spacing: 16) {
                // Set Counter
                VStack(spacing: 2) {
                    Text("SET")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(workoutTimer.currentSet)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                
                // Status and Timer Display
                VStack(spacing: 2) {
                    switch workoutTimer.state {
                    case .exercising:
                        HStack(spacing: 4) {
                            Text("EXERCISE")
                                .font(.caption2)
                                .foregroundColor(.green)
                            // Active indicator dot
                            Circle()
                                .fill(.green)
                                .frame(width: 6, height: 6)
                                .scaleEffect(1.2)
                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: workoutTimer.state)
                        }
                        Text(formatTime(workoutTimer.currentTime))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        
                    case .resting:
                        HStack(spacing: 4) {
                            Text("REST")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            // Active indicator dot
                            Circle()
                                .fill(.orange)
                                .frame(width: 6, height: 6)
                                .scaleEffect(1.2)
                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: workoutTimer.state)
                        }
                        Text(formatTime(workoutTimer.currentTime))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                        
                    case .ready:
                        Text("READY")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("--:--")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            
            // Stop button - Below timer when active
            if workoutTimer.state != .ready {
                Button("Stop") {
                    workoutTimer.stop()
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .tint(.gray)
                .padding(.horizontal)
            }
        }
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    NavigationStack {
        WorkoutTimerView()
    }
}
