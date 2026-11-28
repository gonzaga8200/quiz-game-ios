import Foundation
import Testing
@testable import Contrarreloj

private final class RecordingEngine: SoundOutput {
    var played: [SoundName] = []
    var prepared = 0
    func prepare(sampleRate: Double) { prepared += 1 }
    func play(_ sound: SoundName, samples: [Float], sampleRate: Double) { played.append(sound) }
}

struct SynthTests {
    @Test func soundNotesMatchWeb() {
        #expect(soundNotes[.correct] == [
            Note(freq: 659.25, at: 0, length: 0.14, wave: .triangle, volume: 0.32, glideTo: nil),
            Note(freq: 880, at: 0.1, length: 0.22, wave: .triangle, volume: 0.32, glideTo: nil),
        ])
        #expect(soundNotes[.wrong] == [Note(freq: 196, at: 0, length: 0.3, wave: .sawtooth, volume: 0.2, glideTo: 110)])
        #expect(soundNotes[.skip] == [Note(freq: 440, at: 0, length: 0.09, wave: .sine, volume: 0.18, glideTo: 330)])
        #expect(soundNotes[.streak]?.map(\.freq) == [783.99, 987.77, 1174.66, 1567.98])
        #expect(soundNotes[.streak]?.last == Note(freq: 1567.98, at: 0.21, length: 0.3, wave: .triangle, volume: 0.28, glideTo: nil))
        #expect(soundNotes[.end]?.map(\.freq) == [523.25, 659.25, 783.99, 1046.5])
        #expect(soundNotes[.end]?.map(\.at) == [0, 0.14, 0.28, 0.42])
        #expect(Set(soundNotes.keys) == Set(SoundName.allCases))
    }

    @Test func synthesisFadesInAndOutWithoutClicks() {
        let rate = 44_100.0
        let samples = synthesize(soundNotes[.correct]!, sampleRate: rate)
        #expect(samples.count == Int(((0.1 + 0.22 + 0.03) * rate).rounded(.up)))
        #expect(abs(samples.first!) < 0.001)
        #expect(abs(samples.last!) < 0.001)
        #expect(samples.map(abs).max()! > 0.2)
        #expect(samples.map(abs).max()! <= 1)
    }

    @Test func mutedPlayerPlaysNothing() {
        let defaults = UserDefaults(suiteName: "synth-\(UUID().uuidString)")!
        let preference = SoundPreference(defaults: defaults)
        let engine = RecordingEngine()
        let player = SynthPlayer(preference: preference, output: engine)
        player.play(.correct)
        preference.isMuted = true
        player.play(.wrong)
        #expect(engine.played == [.correct])
    }

    @Test func preparingWarmsUpTheOutputUnlessMuted() {
        let defaults = UserDefaults(suiteName: "SynthTests.\(UUID().uuidString)")!
        let preference = SoundPreference(defaults: defaults)
        let output = RecordingEngine()
        let player = SynthPlayer(preference: preference, output: output)
        player.prepare()
        #expect(output.prepared == 1)
        preference.isMuted = true
        player.prepare()
        #expect(output.prepared == 1)
    }

    /// Starting the audio session and engine can take tens of milliseconds: never on the main thread.
    @Test func audioEngineWorkRunsOffTheMainThread() {
        let onMain = ThreadRecorder()
        let output = AudioEngineOutput(activate: { onMain.record(Thread.isMainThread) })
        output.prepare(sampleRate: SynthPlayer.sampleRate)
        output.waitUntilIdle()
        #expect(onMain.values == [false])
    }
}

nonisolated final class ThreadRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var _values: [Bool] = []
    var values: [Bool] { lock.withLock { _values } }
    func record(_ value: Bool) { lock.withLock { _values.append(value) } }
}
