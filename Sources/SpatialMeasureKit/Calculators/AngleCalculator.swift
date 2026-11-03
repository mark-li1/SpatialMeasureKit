import simd

/// Measures the angle between two lines that meet at a point.
public struct AngleCalculator: Sendable {
    public init() {}

    /// The angle at `vertex` between the lines to the other two points, in degrees from 0 to 180.
    ///
    /// Stays precise near 0° and 180°. Returns `nil` when a point is closer than 0.1 mm to the
    /// vertex, or when a coordinate isn't finite.
    public func angle(from a: SIMD3<Float>, vertex b: SIMD3<Float>, to c: SIMD3<Float>) -> Float? {
        guard simd_length(a - b) > 0.0001, simd_length(c - b) > 0.0001 else { return nil }
        let v1 = a - b
        let v2 = c - b
        let radians = atan2(simd_length(simd_cross(v1, v2)), simd_dot(v1, v2))
        let degrees = radians * 180 / .pi
        return degrees.isFinite ? degrees : nil
    }
}
