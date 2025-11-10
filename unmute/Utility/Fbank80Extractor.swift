//
//  Fbank80Extractor.swift
//  unmute
//
//  Created by Wentao Guo on 27/10/25.
//

import AVFoundation
import Accelerate

/// Extracts 80-dimensional Mel-filterbank (Fbank) features from audio
/// Compatible with SpeechBrain's feature extraction pipeline
final class Fbank80Extractor {

    /// Feature extraction parameters
    struct Params {
        let sr: Double   = 16_000        // Sample rate in Hz
        let winMs: Double = 25.0         // Window size: 25 ms -> 400 samples
        let hopMs: Double = 10.0         // Hop size: 10 ms -> 160 samples
        let nFft: Int     = 512          // FFT size (closest power of 2 to 400)
        let nMels: Int    = 80           // Number of Mel filterbanks
        let fMin: Float   = 0            // Min frequency: 0 Hz (SpeechBrain standard)
        let fMax: Float   = 8000         // Max frequency: 8000 Hz (half of sample rate)
        let eps:  Float   = 1e-10        // Small epsilon for numerical stability
        
        // Note: SpeechBrain uses n_fft=400, but vDSP_FFT requires power of 2
        // We use 512 (closest power of 2) with 400-sample window (zero-padded)
        // Frequency resolution difference: 512->31.25Hz vs 400->40Hz (minimal impact)
    }

    private let p = Params()
    private let window: [Float]                // 400-sample Hamming window
    private let melFilters: [[Float]]          // [80][257] Mel filters (512/2+1 for half spectrum)
    private let fftSetup: FFTSetup             // vDSP FFT setup
    private let log2n: vDSP_Length = 9         // log2(512)

    init?() {
        // Create Hamming window
        let nWin = Int(p.winMs * p.sr / 1000.0) // 400
        var win = [Float](repeating: 0, count: nWin)
        vDSP_hamm_window(&win, vDSP_Length(nWin), 0)
        self.window = win

        // Setup FFT
        guard let setup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else {
            return nil
        }
        self.fftSetup = setup

        // Build Mel filters
        self.melFilters = Fbank80Extractor.buildMelFilters(
            nFft: p.nFft, sampleRate: Float(p.sr),
            nMels: p.nMels, fMin: p.fMin, fMax: p.fMax
        )
    }

    deinit {
        vDSP_destroy_fftsetup(fftSetup)
    }

    /// Extract 80-dimensional Fbank features from 16kHz mono audio
    /// - Parameter buf: Audio buffer (must be 16kHz, mono, Float32 PCM)
    /// - Returns: 2D array [nMels][nFrames] of Fbank features, or nil if extraction fails
    func makeFbank(from16kMono buf: AVAudioPCMBuffer) -> [[Float]]? {
        guard Int(buf.format.sampleRate) == 16000,
              buf.format.channelCount == 1,
              buf.format.commonFormat == .pcmFormatFloat32
        else { return nil }

        let nWin = Int(p.winMs * p.sr / 1000.0)   // 400
        let nHop = Int(p.hopMs * p.sr / 1000.0)   // 160
        let nFft = p.nFft                         // 512
        let half  = nFft / 2                      // 256
  
        // Extract audio data
        let x = Array(UnsafeBufferPointer(start: buf.floatChannelData![0],
                                          count: Int(buf.frameLength)))
        guard x.count >= nWin else { return nil }

        let nFrames = 1 + (x.count - nWin) / nHop
        var feats = Array(repeating: [Float](repeating: 0, count: nFrames), count: p.nMels)

        // FFT buffers
        var frame      = [Float](repeating: 0, count: nFft)
        var realp      = [Float](repeating: 0, count: half)
        var imagp      = [Float](repeating: 0, count: half)
        var powerSpec  = [Float](repeating: 0, count: half)

        for i in 0..<nFrames {
            let start = i * nHop

            // 1. Extract frame and zero-pad to nFft
            frame.replaceSubrange(0..<nWin, with: x[start ..< start + nWin])
            if nFft > nWin {
                frame.replaceSubrange(nWin..<nFft, with: repeatElement(0, count: nFft - nWin))
            }

            // 2. Apply Hamming window
            vDSP_vmul(frame, 1, window, 1, &frame, 1, vDSP_Length(nWin))

            // 3. Prepare FFT split-complex format
            for k in 0..<half {
                realp[k] = frame[2*k]
                imagp[k] = frame[2*k + 1]
            }

            // 4. Perform FFT
            realp.withUnsafeMutableBufferPointer { rBP in
                imagp.withUnsafeMutableBufferPointer { iBP in
                    var split = DSPSplitComplex(realp: rBP.baseAddress!, imagp: iBP.baseAddress!)
                    vDSP_fft_zrip(fftSetup, &split, 1, log2n, FFTDirection(FFT_FORWARD))

                    // 5. Normalize by FFT size
                    var scale: Float = 1.0 / Float(nFft)
                    vDSP_vsmul(split.realp, 1, &scale, split.realp, 1, vDSP_Length(half))
                    vDSP_vsmul(split.imagp, 1, &scale, split.imagp, 1, vDSP_Length(half))

                    // 6. Compute power spectrum: |X[k]|² = real² + imag²
                    vDSP_zvmags(&split, 1, &powerSpec, 1, vDSP_Length(half))
                }
            }

            // 7. Apply Mel filters and take log
            for m in 0..<p.nMels {
                var e: Float = 0
                vDSP_dotpr(powerSpec, 1, melFilters[m], 1, &e, vDSP_Length(half))
                e = logf(max(e, p.eps))
                feats[m][i] = e
            }
        }

        // Mean normalization (SpeechBrain standard: std_norm=False)
        // Important: SpeechBrain's InputNormalization is configured with std_norm=False
        // This means only mean centering is performed, no variance normalization or clipping
        for c in 0..<p.nMels {
            // 1. Compute mean
            var mean: Float = 0
            vDSP_meanv(feats[c], 1, &mean, vDSP_Length(nFrames))

            // 2. Subtract mean (only this step!)
            var negMean = -mean
            vDSP_vsadd(feats[c], 1, &negMean, &feats[c], 1, vDSP_Length(nFrames))

            // Do NOT divide by standard deviation (std_norm=False)
            // Do NOT clip values
            // Expected result: mean≈0, std≈3-11, range≈[-60, 40]
        }

        return feats
    }

    /// Build triangular Mel filterbank
    /// - Parameters:
    ///   - nFft: FFT size
    ///   - sampleRate: Audio sample rate
    ///   - nMels: Number of Mel filters
    ///   - fMin: Minimum frequency
    ///   - fMax: Maximum frequency
    /// - Returns: 2D array [nMels][nFft/2] of filter weights
    static func buildMelFilters(nFft: Int, sampleRate: Float, nMels: Int, fMin: Float, fMax: Float) -> [[Float]] {
        func hz2mel(_ f: Float) -> Float { 2595 * log10(1 + f/700) }
        func mel2hz(_ m: Float) -> Float { 700 * (pow(10, m/2595) - 1) }

        let melMin = hz2mel(fMin), melMax = hz2mel(fMax)
        let pointsHz: [Float] = (0..<(nMels+2)).map { i in
            mel2hz(melMin + (Float(i)/Float(nMels+1)) * (melMax - melMin))
        }

        let half = nFft/2
        let freqs: [Float] = (0..<half).map { k in Float(k) * sampleRate / Float(nFft) }

        var filters = Array(repeating: [Float](repeating: 0, count: half), count: nMels)
        for m in 1...nMels {
            let f0 = pointsHz[m-1], f1 = pointsHz[m], f2 = pointsHz[m+1]
            for (k, fk) in freqs.enumerated() {
                if fk >= f0 && fk <= f1 {
                    filters[m-1][k] = (fk - f0) / (f1 - f0)
                } else if fk > f1 && fk <= f2 {
                    filters[m-1][k] = (f2 - fk) / (f2 - f1)
                }
            }
        }
        return filters
    }
}
