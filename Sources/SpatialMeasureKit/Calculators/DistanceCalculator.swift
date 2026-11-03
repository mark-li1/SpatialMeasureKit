import simd

/// Measures straight lines and paths between points.
public struct DistanceCalculator: Sendable {
    public init() {}

    /// The straight-line distance between two points, in meters.
    public func distance(from: SIMD3<Float>, to: SIMD3<Float>) -> Float {
        simd_distance(from, to)
    }

    /// The length of the path through `points`, in meters, without a segment back to the start.
    ///
    /// Returns 0 for fewer than two points.
    public func length(of points: [SIMD3<Float>]) -> Float {
        guard points.count >= 2 else { return 0 }
        return zip(points, points.dropFirst()).reduce(into: Float(0)) { total, pair in
            total += distance(from: pair.0, to: pair.1)
        }
    }

    /// The length of the closed path through `points`, in meters, including the segment from the
    /// last point back to the first.
    ///
    /// With fewer than three points there is nothing to close, so this equals `length(of:)`.
    public func perimeter(of points: [SIMD3<Float>]) -> Float {
        guard points.count >= 3, let first = points.first, let last = points.last else {
            return length(of: points)
        }
        return length(of: points) + distance(from: last, to: first)
    }
}

