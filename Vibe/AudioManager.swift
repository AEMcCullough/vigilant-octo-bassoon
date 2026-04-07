import AVFoundation

class AudioManager {
    static let shared = AudioManager()
    private var players: [String: AVAudioPlayer] = [:]
    
    func playSound(named name: String, volume: Float = 0.5) {
        if let player = players[name] {
            player.volume = volume
            player.play()
            return
        }
        
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") ?? 
                        Bundle.main.url(forResource: name, withExtension: "wav") else { return }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.volume = volume
            player.play()
            players[name] = player
        } catch {
            print("Audio Error: \(error.localizedDescription)")
        }
    }
}
