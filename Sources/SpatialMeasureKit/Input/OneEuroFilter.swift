import Foundation
import simd

public struct OneEuroFilter: Sendable {
    public let minCutoff: Float
    public let beta: Float
    public let velocityCutoff: Float

    private var value: SIMD3<Float>?
    private var velocity: SIMD3<Float> = .zero
    private var lastTime: TimeInterval?

    public init(minCutoff: Float, beta: Float, velocityCutoff: Float = 1) {
        self.minCutoff = minCutoff
        self.beta = beta
        self.velocityCutoff = velocityCutoff
    }

    public mutating func filter(_ newValue: SIMD3<Float>, at time: TimeInterval) -> SIMD3<Float> {
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

    public mutating func reset(to newValue: SIMD3<Float>? = nil, at time: TimeInterval? = nil) {
        value = newValue
        lastTime = time
        velocity = .zero
    }

    private func smoothingFactor(cutoff: Float, elapsed: Float) -> Float {
        let r = 2 * .pi * cutoff * elapsed
        return r / (r + 1)
    }
}
