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
    private var hapticTimer: Timer?
    private var audioTimer: Timer?
    var audioEnabled = true
    
    // Time tracking properties
    private var exerciseStartTime: Date?
    private var restStartTime: Date?
    private var lastUpdateTime: Date?
    
    func startExercise() {
        guard !isExercising else { return }
        
        isExercising = true
        isResting = false
        currentSet += 1
        exerciseTime = 0
        
        // Record start time for accurate elapsed time calculation
        exerciseStartTime = Date()
        lastUpdateTime = Date()
        
        // Haptic feedback for starting exercise
        WKInterfaceDevice.current().play(.start)
        
        // Start main timer for UI updates
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateExerciseTime()
        }
        
        // Start periodic haptic feedback every 30 seconds
        startPeriodicHapticFeedback()
        
        // Start audio cues every minute
        startAudioCues()
        
    }
    
    func completeSet() {
        guard isExercising else { return }
        
        stopPeriodicHapticFeedback()
        stopAudioCues()
        timer?.invalidate()
        timer = nil
        
        isExercising = false
        isResting = true
        restTime = 0
        hasPlayedRestCue = false
        
        // Record rest start time for accurate elapsed time calculation
        restStartTime = Date()
        lastUpdateTime = Date()
        
        // Haptic feedback for completing set
        WKInterfaceDevice.current().play(.success)
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateRestTime()
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
        exerciseTime = 0
        restTime = 0
        hasPlayedRestCue = false
        
        // Clear timestamps
        exerciseStartTime = nil
        restStartTime = nil
        lastUpdateTime = nil
        
        // Haptic feedback for reset
        WKInterfaceDevice.current().play(.click)
        
    }
    
    func stopCurrentActivity() {
        stopPeriodicHapticFeedback()
        stopAudioCues()
        timer?.invalidate()
        isResting = false
        isExercising = false
        
        // Clear timestamps
        exerciseStartTime = nil
        restStartTime = nil
        lastUpdateTime = nil
        
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
    
    private func updateExerciseTime() {
        guard let startTime = exerciseStartTime else { return }
        let now = Date()
        exerciseTime = now.timeIntervalSince(startTime)
        lastUpdateTime = now
    }
    
    private func updateRestTime() {
        guard let startTime = restStartTime else { return }
        let now = Date()
        restTime = now.timeIntervalSince(startTime)
        lastUpdateTime = now
        
        // Audio cue at 1:30 rest time
        if restTime >= 90 && !hasPlayedRestCue {
            hasPlayedRestCue = true
            playRestCue()
        }
    }
    
    // Method to get current accurate time when app becomes active
    func refreshCurrentTime() {
        if isExercising {
            updateExerciseTime()
        } else if isResting {
            updateRestTime()
        }
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
    
    // Computed property for the pulsing background style
    private var pulsingBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(workoutTimer.isExercising ? Color.green.opacity(0.1) : 
                  workoutTimer.isResting ? Color.orange.opacity(0.1) : Color.clear)
            .scaleEffect(workoutTimer.isExercising || workoutTimer.isResting ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), 
                     value: workoutTimer.isExercising || workoutTimer.isResting)
    }
    
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
                .background(pulsingBackground)
                
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
                .background(pulsingBackground)
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
        .onAppear {
            // Refresh time when view appears to ensure accuracy
            workoutTimer.refreshCurrentTime()
        }
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
