import AVFoundation

import AVFoundation

class AudioManager {
    static let shared = AudioManager()
    private var players: [String: AVAudioPlayer] = [:]
    private var loops: [String: AVAudioPlayer] = [:]
    
    init() {
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio Session Error: \(error)")
        }
    }
    
    func playSound(named name: String, volume: Float = 0.5) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { return }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.prepareToPlay()
            player.play()
            
            // Limit concurrent impact sounds
            let key = "impact_\(Date().timeIntervalSince1970)"
            players[key] = player
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.players.removeValue(forKey: key)
            }
        } catch {
            print("Audio Error: \(error)")
        }
    }
    
    func updateLoop(named name: String, intensity: Float) {
        if let loop = loops[name] {
            if intensity > 0.01 {
                if !loop.isPlaying { loop.play() }
                loop.volume = min(intensity * 1.5, 0.45) // Cap volume for ASMR feel
                loop.pan = Float.random(in: -0.2...0.2) // Subtle panning for depth
            } else {
                loop.setVolume(0, fadeDuration: 1.0)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                    if loop.volume == 0 { loop.pause() }
                }
            }
            return
        }
        
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 0
            player.prepareToPlay()
            loops[name] = player
        } catch {
            print("Loop Error: \(error)")
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
