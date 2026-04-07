import AVFoundation

import AVFoundation

class AudioManager {
    static let shared = AudioManager()
    private var players: [AVAudioPlayer] = []
    
    func playSound(named name: String, volume: Float = 0.5) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") ?? 
                        Bundle.main.url(forResource: name, withExtension: "wav") else {
            print("Audio Error: Could not find resource \(name)")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.prepareToPlay()
            player.play()
            
            // Basic cleanup of finished players
            players.append(player)
            if players.count > 15 { players.removeFirst() }
            
        } catch {
            print("Audio Error: \(error.localizedDescription)")
        }
    }
}
