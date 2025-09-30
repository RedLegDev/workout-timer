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
    private var stateStartTime: Date?
    var timer: Timer?
    private var hasPlayedRestCue = false
    private var hapticTimer: Timer?
    private var audioTimer: Timer?
    var audioEnabled = true
    
    // Computed properties for current elapsed time
    var exerciseTime: TimeInterval {
        guard isExercising, let startTime = stateStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    var restTime: TimeInterval {
        guard isResting, let startTime = stateStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    func startExercise() {
        guard !isExercising else { return }
        
        isExercising = true
        isResting = false
        currentSet += 1
        
        // Record start time for this state
        stateStartTime = Date()
        
        // Haptic feedback for starting exercise
        WKInterfaceDevice.current().play(.start)
        
        // Start main timer for UI updates (just to trigger view refreshes)
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // Timer just needs to trigger view updates - time calculation is computed
        }
        
        // Start periodic haptic feedback every 30 seconds
        startPeriodicHapticFeedback()
        
        // Start audio cues every minute
        startAudioCues()
    }
    
    func completeSet() {
        guard isExercising else { return }
        
        // Stop all current timers first
        stopPeriodicHapticFeedback()
        stopAudioCues()
        timer?.invalidate()
        timer = nil
        
        // Update state
        isExercising = false
        hasPlayedRestCue = false
        
        // Record rest start time
        stateStartTime = Date()
        
        // Set resting state after everything is configured
        isResting = true
        
        // Haptic feedback for completing set
        WKInterfaceDevice.current().play(.success)
        
        // Start rest timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // Check for rest cue at 1:30
            if self.restTime >= 90 && !self.hasPlayedRestCue {
                self.hasPlayedRestCue = true
                self.playRestCue()
            }
        }
        
        // Start periodic haptic feedback for rest period
        startPeriodicHapticFeedback()
        
        // Start audio cues for rest period
        startAudioCues()
    }
    
    func startNextSet() {
        guard isResting else { return }
        
        stopPeriodicHapticFeedback()
        stopAudioCues()
        timer?.invalidate()
        
        // Haptic feedback for starting next set
        WKInterfaceDevice.current().play(.start)
        
        startExercise()
    }
    
    func resetExercise() {
        stopPeriodicHapticFeedback()
        stopAudioCues()
        timer?.invalidate()
        currentSet = 0
        isResting = false
        isExercising = false
        hasPlayedRestCue = false
        
        // Clear timestamp
        stateStartTime = nil
        
        // Haptic feedback for reset
        WKInterfaceDevice.current().play(.click)
    }
    
    func stopCurrentActivity() {
        stopPeriodicHapticFeedback()
        stopAudioCues()
        timer?.invalidate()
        isResting = false
        isExercising = false
        
        // Clear timestamp
        stateStartTime = nil
        
        // Haptic feedback for stopping
        WKInterfaceDevice.current().play(.stop)
    }
    
    private func playRestCue() {
        // Play system sound for rest cue
        WKInterfaceDevice.current().play(.notification)
        
        // Also provide haptic feedback
        WKInterfaceDevice.current().play(.directionUp)
    }
    
    private func startPeriodicHapticFeedback() {
        // Provide gentle haptic feedback every 30 seconds to indicate timer is running
        hapticTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            if self.isExercising || self.isResting {
                // Gentle tap to indicate timer is still running
                WKInterfaceDevice.current().play(.click)
            }
        }
    }
    
    private func stopPeriodicHapticFeedback() {
        hapticTimer?.invalidate()
        hapticTimer = nil
    }
    
    
    private func startAudioCues() {
        guard audioEnabled else { return }
        
        // Play audio cue every minute to indicate timer is running
        audioTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            if self.isExercising || self.isResting {
                // Gentle audio cue to indicate timer is still running
                WKInterfaceDevice.current().play(.click)
            }
        }
    }
    
    private func stopAudioCues() {
        audioTimer?.invalidate()
        audioTimer = nil
    }
    

    
    
    func toggleAudio() {
        audioEnabled.toggle()
        if audioEnabled && (isExercising || isResting) {
            startAudioCues()
        } else {
            stopAudioCues()
        }
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
                
                // Secondary buttons
                HStack(spacing: 8) {
                    if workoutTimer.currentSet > 0 {
                        Button("New Exercise") {
                            workoutTimer.resetExercise()
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
                    if workoutTimer.isExercising {
                        HStack(spacing: 4) {
                            Text("EXERCISE")
                                .font(.caption2)
                                .foregroundColor(.green)
                            // Active indicator dot
                            Circle()
                                .fill(.green)
                                .frame(width: 6, height: 6)
                                .scaleEffect(workoutTimer.isExercising ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: workoutTimer.isExercising)
                        }
                        Text(formatTime(workoutTimer.exerciseTime))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    } else if workoutTimer.isResting {
                        HStack(spacing: 4) {
                            Text("REST")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            // Active indicator dot
                            Circle()
                                .fill(.orange)
                                .frame(width: 6, height: 6)
                                .scaleEffect(workoutTimer.isResting ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: workoutTimer.isResting)
                        }
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
