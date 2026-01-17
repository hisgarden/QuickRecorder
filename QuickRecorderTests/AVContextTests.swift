import AVFoundation
import Testing

@testable import QuickRecorder

@MainActor
struct AVContextTests {

    // Note: AVContext class does not exist in the codebase
    // Tests for AVContext have been removed

    @Test func testAudioFormatEnum() {
        // Test all audio format cases exist
        #expect(AudioFormat.aac != AudioFormat.alac)
        #expect(AudioFormat.alac != AudioFormat.flac)
        #expect(AudioFormat.opus != AudioFormat.aac)

        // Test raw values
        #expect(AudioFormat.aac.rawValue == "aac")
        #expect(AudioFormat.alac.rawValue == "alac")
        #expect(AudioFormat.flac.rawValue == "flac")
        #expect(AudioFormat.opus.rawValue == "opus")
    }

    @Test func testVideoFormatEnum() {
        // Test all video format cases exist
        #expect(VideoFormat.mp4 != VideoFormat.mov)

        // Test raw values
        #expect(VideoFormat.mp4.rawValue == "mp4")
        #expect(VideoFormat.mov.rawValue == "mov")
    }

    @Test func testEncoderEnum() {
        // Test all encoder cases exist
        #expect(Encoder.h264 != Encoder.h265)

        // Test raw values
        #expect(Encoder.h264.rawValue == "h264")
        #expect(Encoder.h265.rawValue == "h265")
    }

    @Test func testAudioQualityEnum() {
        // Test all audio quality cases exist
        #expect(AudioQuality.normal != AudioQuality.good)
        #expect(AudioQuality.high != AudioQuality.extreme)

        // Test raw values (Int enum: normal=128, good=192, high=256, extreme=320)
        #expect(AudioQuality.normal.rawValue == 128)
        #expect(AudioQuality.good.rawValue == 192)
        #expect(AudioQuality.high.rawValue == 256)
        #expect(AudioQuality.extreme.rawValue == 320)
    }

    @Test func testStreamTypeEnum() {
        // Test all stream type cases exist
        #expect(StreamType.screen != StreamType.window)
        #expect(StreamType.systemaudio != StreamType.window)

        // Test raw values (Int enum: screen=0, window=1, systemaudio=5)
        #expect(StreamType.screen.rawValue == 0)
        #expect(StreamType.window.rawValue == 1)
        #expect(StreamType.systemaudio.rawValue == 5)
    }

    @Test func testBackgroundTypeEnum() {
        // Test all background type cases exist
        #expect(BackgroundType.black != BackgroundType.white)
        #expect(BackgroundType.custom != BackgroundType.white)

        // Test raw values
        #expect(BackgroundType.black.rawValue == "black")
        #expect(BackgroundType.white.rawValue == "white")
        #expect(BackgroundType.custom.rawValue == "custom")
    }

    // Note: AVContext class does not exist, so default settings test removed
}
