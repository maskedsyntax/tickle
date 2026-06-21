import Foundation
import AVFoundation
import Combine

final class SoundService: ObservableObject {
    static let shared = SoundService()
    
    @Published var isSoundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSoundEnabled, forKey: "sound_enabled")
        }
    }
    
    private var audioEngine: AVAudioEngine
    
    private init() {
        self.isSoundEnabled = UserDefaults.standard.object(forKey: "sound_enabled") as? Bool ?? true
        self.audioEngine = AVAudioEngine()
        
        // Setup session for ambient sound (won't interrupt user's music unless played)
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
    }
    
    func playClick() {
        guard isSoundEnabled else { return }
        playTone(frequency: 800.0, duration: 0.05, amplitude: 0.3)
    }
    
    func playPop() {
        guard isSoundEnabled else { return }
        playTone(frequency: 450.0, duration: 0.08, amplitude: 0.4)
    }
    
    func playThud() {
        guard isSoundEnabled else { return }
        playTone(frequency: 180.0, duration: 0.12, amplitude: 0.5)
    }
    
    private func playTone(frequency: Double, duration: Double, amplitude: Float) {
        let sampleRate = 44100.0
        let totalSamples = Int(sampleRate * duration)
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(totalSamples)) else {
            return
        }
        
        buffer.frameLength = AVAudioFrameCount(totalSamples)
        
        guard let floatChannelData = buffer.floatChannelData else { return }
        let data = floatChannelData[0]
        
        for sample in 0..<totalSamples {
            let t = Double(sample) / sampleRate
            // Exponential decay envelope for a satisfying fade
            let envelope = exp(-Double(sample) / (Double(totalSamples) * 0.25))
            let val = sin(2.0 * .pi * frequency * t) * envelope * Double(amplitude)
            data[sample] = Float(val)
        }
        
        let playerNode = AVAudioPlayerNode()
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: format)
        
        if !audioEngine.isRunning {
            do {
                try audioEngine.start()
            } catch {
                print("Failed to start audio engine: \(error)")
                return
            }
        }
        
        playerNode.play()
        playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: { [weak self] in
            guard let self = self else { return }
            // Detach node once finished to free resources
            DispatchQueue.main.async {
                self.audioEngine.disconnectNodeOutput(playerNode)
                self.audioEngine.detach(playerNode)
            }
        })
    }
}
