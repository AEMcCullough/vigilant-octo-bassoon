import AVFoundation

class AudioManager {
    static let shared = AudioManager()
    private var players: [String: AVAudioPlayer] = [:]
    private var loops: [String: AVAudioPlayer] = [:]
    
    // Performance: track active sound count to prevent clipping
    private var activeImpacts = 0
    private let maxImpacts = 8
    
    init() {
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio Session Error: \(error)")
        }
    }
    
    func playSound(named name: String, volume: Float = 0.5) {
        guard activeImpacts < maxImpacts else { return }
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { return }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume * 0.8 // Premium padding
            player.prepareToPlay()
            player.play()
            
            activeImpacts += 1
            
            let key = "impact_\(UUID().uuidString)"
            players[key] = player
            
            // Cleanup player after it finished
            DispatchQueue.main.asyncAfter(deadline: .now() + player.duration + 0.1) {
                self.players.removeValue(forKey: key)
                self.activeImpacts -= 1
            }
        } catch {
            print("Audio Impact Error: \(error)")
        }
    }
    
    func updateLoop(named name: String, intensity: Float) {
        if let loop = loops[name] {
            if intensity > 0.005 {
                if !loop.isPlaying { 
                    loop.play()
                    loop.volume = 0
                }
                
                // ASMR Polish: Smooth volume ramping
                let targetVolume = min(intensity * 1.8, 0.4)
                loop.setVolume(targetVolume, fadeDuration: 0.15)
                
                // Dynamic Panning based on intensity (simulating spread)
                loop.pan = Float.random(in: -0.1...0.1)
            } else {
                loop.setVolume(0, fadeDuration: 0.8)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    if loop.volume == 0 { loop.pause() }
                }
            }
            return
        }
        
        // Lazy load loops
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 0
            player.prepareToPlay()
            loops[name] = player
            if intensity > 0 { updateLoop(named: name, intensity: intensity) }
        } catch {
            print("Audio Loop Error: \(error)")
        }
    }
    
    func stopAllLoops() {
        for loop in loops.values {
            loop.setVolume(0, fadeDuration: 0.5)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                loop.stop()
            }
        }
    }
}
