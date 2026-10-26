import simd

public struct AngleCalculator: Sendable {
    public init() {}

    public func computeAngle(from a: SIMD3<Float>, vertex b: SIMD3<Float>, to c: SIMD3<Float>) -> Float? {
        guard simd_length(a - b) > 0.0001, simd_length(c - b) > 0.0001 else { return nil }
        let v1 = a - b
        let v2 = c - b
        let radians = atan2(simd_length(simd_cross(v1, v2)), simd_dot(v1, v2))
        return radians * 180 / .pi
    }
}
