class HapticsManager: ObservableObject {
    private var engine: CHHapticEngine?
    private var continuousPlayer: CHHapticAdvancedPatternPlayer?
    
    func prepare() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Haptic Engine Error: \(error.localizedDescription)")
        }
    }
    
    func playImpact(intensity: Float, sharpness: Float) {
        let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensityParam, sharpnessParam], relativeTime: 0)
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch { }
    }
    
    func startContinuous(intensity: Float, sharpness: Float) {
        let intensityParam = CHHapticDynamicParameter(parameterID: .hapticIntensityControl, value: intensity, relativeTime: 0)
        let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [], relativeTime: 0, duration: 100)
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            continuousPlayer = try engine?.makeAdvancedPlayer(with: pattern)
            try continuousPlayer?.start(atTime: 0)
            try continuousPlayer?.sendParameters([intensityParam], atTime: 0)
        } catch { }
    }
    
    func updateContinuous(intensity: Float) {
        let intensityParam = CHHapticDynamicParameter(parameterID: .hapticIntensityControl, value: intensity, relativeTime: 0)
        try? continuousPlayer?.sendParameters([intensityParam], atTime: 0)
    }
    
    func stopContinuous() {
        try? continuousPlayer?.stop(atTime: 0)
    }
}
