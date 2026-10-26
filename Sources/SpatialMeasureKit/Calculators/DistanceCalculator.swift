import simd

public struct DistanceCalculator: Sendable {
    public init() {}

    /// Straight-line distance between two points, in meters.
    public func computeDistance(from: SIMD3<Float>, to: SIMD3<Float>) -> Float {
        simd_distance(from, to)
    }

    /// Total length of the polyline through `points`, in meters.
    /// The path is treated as open — no segment is added from the last point back to the first.
    /// Returns 0 for fewer than two points.
    public func computeLength(from points: [SIMD3<Float>]) -> Float {
        guard points.count >= 2 else { return 0 }
        return zip(points, points.dropFirst()).reduce(into: Float(0)) { total, pair in
            total += computeDistance(from: pair.0, to: pair.1)
        }
    }

    /// Total length of the closed path through `points`, in meters, including the segment from the
    /// last point back to the first.
    /// Paths of fewer than three points have no closing segment and fall back to `computeLength(from:)`.
    public func computePerimeter(from points: [SIMD3<Float>]) -> Float {
        guard points.count >= 3, let first = points.first, let last = points.last else {
            return computeLength(from: points)
        }
        return computeLength(from: points) + computeDistance(from: last, to: first)
    }
}

