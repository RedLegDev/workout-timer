//
//  WorkoutTimerView.swift
//  Workout Timer Watch App
//
//  Created by Matt Wagner on 9/24/25.
//

import SwiftUI
import WatchKit
import AVFoundation

@Observable
class WorkoutTimer {
    var currentSet = 0
    var isResting = false
    var isExercising = false
    var exerciseTime: TimeInterval = 0
    var restTime: TimeInterval = 0
    var timer: Timer?
    private var hasPlayedRestCue = false
    
    func startExercise() {
        guard !isExercising else { return }
        
        isExercising = true
        isResting = false
        currentSet += 1
        exerciseTime = 0
        
        // Haptic feedback for starting exercise
        WKInterfaceDevice.current().play(.start)
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.exerciseTime += 1
        }
    }
    
    func completeSet() {
        guard isExercising else { return }
        
        isExercising = false
        isResting = true
        restTime = 0
        hasPlayedRestCue = false
        timer?.invalidate()
        
        // Haptic feedback for completing set
        WKInterfaceDevice.current().play(.success)
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.restTime += 1
            
            // Audio cue at 1:30 rest time
            if self.restTime == 90 && !self.hasPlayedRestCue {
                self.hasPlayedRestCue = true
                self.playRestCue()
            }
        }
    }
    
    func startNextSet() {
        guard isResting else { return }
        
        timer?.invalidate()
        
        // Haptic feedback for starting next set
        WKInterfaceDevice.current().play(.start)
        
        startExercise()
    }
    
    func resetExercise() {
        timer?.invalidate()
        currentSet = 0
        isResting = false
        isExercising = false
        exerciseTime = 0
        restTime = 0
        hasPlayedRestCue = false
        
        // Haptic feedback for reset
        WKInterfaceDevice.current().play(.click)
    }
    
    func stopCurrentActivity() {
        timer?.invalidate()
        isResting = false
        isExercising = false
        
        // Haptic feedback for stopping
        WKInterfaceDevice.current().play(.stop)
    }
    
    private func playRestCue() {
        // Play system sound for rest cue
        WKInterfaceDevice.current().play(.notification)
        
        // Also provide haptic feedback
        WKInterfaceDevice.current().play(.directionUp)
    }
}

struct WorkoutTimerView: View {
    @State private var workoutTimer = WorkoutTimer()
    
    var body: some View {
        VStack(spacing: 12) {
            // Action Buttons - Top for easy access
            VStack(spacing: 8) {
                if !workoutTimer.isExercising && !workoutTimer.isResting {
                    // Start Exercise Button
                    Button("Start Set") {
                        workoutTimer.startExercise()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else if workoutTimer.isExercising {
                    // Complete Set Button
                    Button("Complete Set") {
                        workoutTimer.completeSet()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.orange)
                } else if workoutTimer.isResting {
                    // Start Next Set Button
                    Button("Start Next Set") {
                        workoutTimer.startNextSet()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.green)
                }
                
                // Secondary buttons in a row
                HStack(spacing: 12) {
                    // Reset Exercise Button
                    if workoutTimer.currentSet > 0 {
                        Button("New Exercise") {
                            workoutTimer.resetExercise()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.red)
                    }
                    
                    // Stop Current Activity Button (if active)
                    if workoutTimer.isExercising || workoutTimer.isResting {
                        Button("Stop") {
                            workoutTimer.stopCurrentActivity()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.gray)
                    }
                }
            }
            .padding(.horizontal)
            
            Divider()
            
            // Set Counter and Timer Display - Side by Side
            HStack(spacing: 16) {
                // Set Counter
                VStack(spacing: 4) {
                    Text("SET")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(workoutTimer.currentSet)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                
                // Status and Timer Display
                VStack(spacing: 4) {
                    if workoutTimer.isExercising {
                        Text("EXERCISE")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text(formatTime(workoutTimer.exerciseTime))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    } else if workoutTimer.isResting {
                        Text("REST")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text(formatTime(workoutTimer.restTime))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    } else {
                        Text("READY")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("--:--")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            
            Spacer()
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
