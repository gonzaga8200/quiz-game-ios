import AVFoundation
import Foundation

/// Game sounds synthesised in code, the same notes as the web's Web Audio synth
/// (`app/utils/audio.ts`): no audio files, no licences.
nonisolated enum SoundName: CaseIterable, Sendable {
    case correct, wrong, skip, streak, end
}

nonisolated enum Wave: Sendable {
    case sine, triangle, sawtooth
}

nonisolated struct Note: Equatable, Sendable {
    let freq: Double
    /// Seconds after the sound starts.
    let at: Double
    let length: Double
    let wave: Wave
    let volume: Double
    /// Pitch glide target (Hz) reached at the end of the note.
    let glideTo: Double?
}

nonisolated let soundNotes: [SoundName: [Note]] = [
    // Two rising notes: a friendly "ding-ding".
    .correct: [
        Note(freq: 659.25, at: 0, length: 0.14, wave: .triangle, volume: 0.32, glideTo: nil),
        Note(freq: 880, at: 0.1, length: 0.22, wave: .triangle, volume: 0.32, glideTo: nil),
    ],
    // Low falling buzz.
    .wrong: [Note(freq: 196, at: 0, length: 0.3, wave: .sawtooth, volume: 0.2, glideTo: 110)],
    // Short soft blip.
    .skip: [Note(freq: 440, at: 0, length: 0.09, wave: .sine, volume: 0.18, glideTo: 330)],
    // Bright, quick climb for a combo bonus.
    .streak: [
        Note(freq: 783.99, at: 0, length: 0.1, wave: .triangle, volume: 0.26, glideTo: nil),
        Note(freq: 987.77, at: 0.07, length: 0.1, wave: .triangle, volume: 0.26, glideTo: nil),
        Note(freq: 1174.66, at: 0.14, length: 0.1, wave: .triangle, volume: 0.26, glideTo: nil),
        Note(freq: 1567.98, at: 0.21, length: 0.3, wave: .triangle, volume: 0.28, glideTo: nil),
    ],
    // Rising arpeggio for the final whistle.
    .end: [
        Note(freq: 523.25, at: 0, length: 0.16, wave: .triangle, volume: 0.3, glideTo: nil),
        Note(freq: 659.25, at: 0.14, length: 0.16, wave: .triangle, volume: 0.3, glideTo: nil),
        Note(freq: 783.99, at: 0.28, length: 0.16, wave: .triangle, volume: 0.3, glideTo: nil),
        Note(freq: 1046.5, at: 0.42, length: 0.45, wave: .triangle, volume: 0.3, glideTo: nil),
    ],
]

/// Renders notes to mono samples with the web's envelope: a 12 ms linear attack from silence,
/// an exponential decay to silence at the end of the note, and an exponential pitch glide.
nonisolated func synthesize(_ notes: [Note], sampleRate: Double) -> [Float] {
    let tail = 0.03
    let total = notes.map { $0.at + $0.length + tail }.max() ?? 0
    var out = [Float](repeating: 0, count: Int((total * sampleRate).rounded(.up)))
    let floor = 0.0001
    for note in notes {
        let start = Int((note.at * sampleRate).rounded())
        let end = min(out.count, Int(((note.at + note.length + tail) * sampleRate).rounded(.up)))
        var phase = 0.0
        for i in start..<end {
            let t = Double(i) / sampleRate - note.at
            let progress = min(1, max(0, t / note.length))
            let freq = note.glideTo.map { note.freq * pow($0 / note.freq, progress) } ?? note.freq
            let gain: Double
            if t < 0.012 {
                gain = floor + (note.volume - floor) * max(0, t) / 0.012
            } else if t < note.length {
                gain = note.volume * pow(floor / note.volume, (t - 0.012) / (note.length - 0.012))
            } else {
                gain = floor
            }
            let sample: Double
            switch note.wave {
            case .sine: sample = sin(2 * .pi * phase)
            case .triangle: sample = 1 - 4 * abs((phase + 0.25).truncatingRemainder(dividingBy: 1) - 0.5)
            case .sawtooth: sample = 2 * (phase - (phase + 0.5).rounded(.down))
            }
            out[i] += Float(sample * gain)
            phase = (phase + freq / sampleRate).truncatingRemainder(dividingBy: 1)
        }
    }
    return out.map { min(1, max(-1, $0)) }
}

/// Where synthesised sounds are played (AVAudioEngine in the app, a recorder in tests).
protocol SoundOutput: AnyObject {
    func play(_ sound: SoundName, samples: [Float], sampleRate: Double)
}

protocol SoundPlayer: AnyObject {
    func play(_ sound: SoundName)
}

/// Plays the game sounds unless the player muted them.
final class SynthPlayer: SoundPlayer {
    static let sampleRate = 44_100.0
    private let preference: SoundPreference
    private let output: any SoundOutput
    private var cache: [SoundName: [Float]] = [:]

    init(preference: SoundPreference, output: any SoundOutput = AudioEngineOutput()) {
        self.preference = preference
        self.output = output
    }

    func play(_ sound: SoundName) {
        guard !preference.isMuted else { return }
        let samples = cache[sound] ?? synthesize(soundNotes[sound] ?? [], sampleRate: Self.sampleRate)
        cache[sound] = samples
        output.play(sound, samples: samples, sampleRate: Self.sampleRate)
    }
}

/// AVAudioEngine with a few player nodes, so a streak jingle can overlap the answer sound. The
/// session is `.ambient`: it respects the silent switch and mixes with the player's music.
final class AudioEngineOutput: SoundOutput {
    private let engine = AVAudioEngine()
    private var nodes: [AVAudioPlayerNode] = []
    private var buffers: [SoundName: AVAudioPCMBuffer] = [:]
    private var next = 0
    private var format: AVAudioFormat?

    func play(_ sound: SoundName, samples: [Float], sampleRate: Double) {
        guard prepare(sampleRate: sampleRate), let format else { return }
        let buffer = buffers[sound] ?? makeBuffer(samples, format: format)
        buffers[sound] = buffer
        guard let buffer else { return }
        let node = nodes[next]
        next = (next + 1) % nodes.count
        node.stop()
        node.scheduleBuffer(buffer, at: nil)
        node.play()
    }

    private func prepare(sampleRate: Double) -> Bool {
        if engine.isRunning { return true }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient)
            try AVAudioSession.sharedInstance().setActive(true)
            if nodes.isEmpty {
                guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return false }
                self.format = format
                for _ in 0..<4 {
                    let node = AVAudioPlayerNode()
                    engine.attach(node)
                    engine.connect(node, to: engine.mainMixerNode, format: format)
                    nodes.append(node)
                }
            }
            try engine.start()
            return true
        } catch {
            return false // no audio is never a reason to break the game
        }
    }

    private func makeBuffer(_ samples: [Float], format: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)),
              let channel = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { channel.update(from: $0.baseAddress!, count: samples.count) }
        return buffer
    }
}
