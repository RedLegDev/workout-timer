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
        
        timer?.invalidate()
        timer = nil
        
        isExercising = false
        isResting = true
        restTime = 0
        hasPlayedRestCue = false
        
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
        VStack(spacing: 8) {
            // Action Buttons - Top for easy access
            VStack(spacing: 6) {
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
                
                // Secondary buttons - New Exercise only
                if workoutTimer.currentSet > 0 {
                    Button("New Exercise") {
                        workoutTimer.resetExercise()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.red)
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
                    if workoutTimer.isExercising {
                        Text("EXERCISE")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Text(formatTime(workoutTimer.exerciseTime))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    } else if workoutTimer.isResting {
                        Text("REST")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text(formatTime(workoutTimer.restTime))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    } else {
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
            if workoutTimer.isExercising || workoutTimer.isResting {
                Button("Stop") {
                    workoutTimer.stopCurrentActivity()
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
