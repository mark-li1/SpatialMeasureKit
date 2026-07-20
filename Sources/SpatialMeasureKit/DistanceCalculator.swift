import simd

public struct DistanceCalculator {
    public init() {}

    public func compute(from: SIMD3<Float>, to: SIMD3<Float>) -> Float {
        simd_distance(from, to)
    }
}

