import CoreHaptics
import Foundation

class HapticsManager: ObservableObject {
    private var engine: CHHapticEngine?
    private var continuousPlayer: CHHapticAdvancedPatternPlayer?
    
    func prepare() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            engine?.playsHapticsOnly = true
            
            // Restart handler
            engine?.stoppedHandler = { reason in
                print("Haptic Engine Stopped: \(reason.rawValue)")
            }
            engine?.resetHandler = { [weak self] in
                print("Haptic Engine Reset")
                try? self?.engine?.start()
            }
            
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
            try player?.start(atTime: CHHapticTimeImmediate)
        } catch { }
    }
    
    /// Logic for playing the premium custom patterns (.ahap)
    func playPattern(named name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "ahap") else { return }
        try? engine?.playPattern(from: url)
    }
    
    func updateContinuous(intensity: Float, sharpness: Float = 0.5) {
        if continuousPlayer == nil {
            startContinuous(intensity: intensity, sharpness: sharpness)
        } else {
            let intensityParam = CHHapticDynamicParameter(parameterID: .hapticIntensityControl, value: intensity, relativeTime: 0)
            let sharpnessParam = CHHapticDynamicParameter(parameterID: .hapticSharpnessControl, value: sharpness, relativeTime: 0)
            try? continuousPlayer?.sendParameters([intensityParam, sharpnessParam], atTime: CHHapticTimeImmediate)
        }
    }
    
    func startContinuous(intensity: Float, sharpness: Float) {
        let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
        let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [intensityParam, sharpnessParam], relativeTime: 0, duration: 100)
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            continuousPlayer = try engine?.makeAdvancedPlayer(with: pattern)
            try continuousPlayer?.start(atTime: CHHapticTimeImmediate)
        } catch { }
    }
    
    func stopContinuous() {
        try? continuousPlayer?.stop(atTime: CHHapticTimeImmediate)
        continuousPlayer = nil
    }
}
