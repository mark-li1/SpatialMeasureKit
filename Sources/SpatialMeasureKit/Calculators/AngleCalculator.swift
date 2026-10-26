import simd

public struct AngleCalculator: Sendable {
    public init() {}

    public func computeAngle(from a: SIMD3<Float>, vertex b: SIMD3<Float>, to c: SIMD3<Float>) -> Float? {
        guard simd_length(a - b) > 0.0001, simd_length(c - b) > 0.0001 else { return nil }
        let v1 = simd_normalize(a - b)
        let v2 = simd_normalize(c - b)
        let cosAngle = simd_dot(v1, v2)
        let clamped = max(-1, min(1, cosAngle))
        let radians = acos(clamped)
        return radians * 180 / .pi
    }
}
