import Foundation
import simd

/// Smooths a shaky 3D position, such as an AR aim point, without making it lag when it moves.
///
/// It smooths a lot while the input is still and little while it moves fast. This is the 1€
/// filter by Casiez, Roussel and Vogel (CHI 2012). You pass the time in, so it works at any
/// frame rate and is easy to test.
public struct OneEuroFilter: Sendable {
    /// How much a still input is smoothed, in hertz. Lower is smoother but slower to follow.
    public let minCutoff: Float
    /// How fast smoothing fades as the input speeds up. Higher means less lag while moving.
    public let beta: Float
    /// How much the speed estimate itself is smoothed, in hertz. 1 suits most uses.
    public let velocityCutoff: Float

    private var value: SIMD3<Float>?
    private var velocity: SIMD3<Float> = .zero
    private var lastTime: TimeInterval?

    /// Creates a filter.
    ///
    /// For an aim point in meters, `minCutoff: 1` and `beta: 4` are a good start. `minCutoff` and
    /// `velocityCutoff` must be positive, `beta` must not be negative, and all must be finite.
    public init(minCutoff: Float, beta: Float, velocityCutoff: Float = 1) {
        precondition(minCutoff > 0 && minCutoff.isFinite, "minCutoff must be positive and finite, got \(minCutoff)")
        precondition(beta >= 0 && beta.isFinite, "beta must be finite and not negative, got \(beta)")
        precondition(
            velocityCutoff > 0 && velocityCutoff.isFinite,
            "velocityCutoff must be positive and finite, got \(velocityCutoff)"
        )
        self.minCutoff = minCutoff
        self.beta = beta
        self.velocityCutoff = velocityCutoff
    }

    /// Adds a sample taken at `time`, in seconds, and returns the smoothed position.
    ///
    /// The first sample, and any sample whose time doesn't move forward, starts over and comes
    /// back unchanged. A sample with a NaN or infinite value or time is skipped: you get the last
    /// output back, and the filter carries on as if the sample never came.
    public mutating func filter(_ newValue: SIMD3<Float>, at time: TimeInterval) -> SIMD3<Float> {
        guard newValue.isFinite, time.isFinite else { return value ?? newValue }
        guard let value, let lastTime, time > lastTime else {
            reset(to: newValue, at: time)
            return newValue
        }
        let elapsed = Float(time - lastTime)
        let rawVelocity = (newValue - value) / elapsed
        velocity += (rawVelocity - velocity) * smoothingFactor(cutoff: velocityCutoff, elapsed: elapsed)
        let cutoff = minCutoff + beta * simd_length(velocity)
        let filtered = value + (newValue - value) * smoothingFactor(cutoff: cutoff, elapsed: elapsed)
        self.value = filtered
        self.lastTime = time
        return filtered
    }

    /// Forgets the history.
    ///
    /// To continue smoothing from a known position, for example after snapping to a point, pass
    /// that position and its time. Otherwise the next sample comes back unchanged.
    public mutating func reset(to newValue: SIMD3<Float>? = nil, at time: TimeInterval? = nil) {
        value = newValue?.isFinite == true ? newValue : nil
        lastTime = time?.isFinite == true ? time : nil
        velocity = .zero
    }

    private func smoothingFactor(cutoff: Float, elapsed: Float) -> Float {
        let r = 2 * .pi * cutoff * elapsed
        return r / (r + 1)
    }
}

private extension SIMD3 where Scalar == Float {
    var isFinite: Bool { x.isFinite && y.isFinite && z.isFinite }
}
