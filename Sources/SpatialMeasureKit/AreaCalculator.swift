import simd

public struct AreaCalculator {
    public init() {}

    public func computeArea(from points: [SIMD3<Float>]) -> Float {
        guard points.count >= 3 else { return 0 }
        return simd_length(newellNormal(from: points)) / 2
    }

    /// Worst-case distance, in meters, of any point from the polygon's best-fit plane.
    /// `0` means the points are perfectly planar. A larger value means they don't all lie on
    /// one surface — e.g. the trace wandered across a corner, or raycast noise is unusually high.
    public func planarityError(from points: [SIMD3<Float>]) -> Float {
        guard points.count >= 3 else { return 0 }

        let centroid = points.reduce(SIMD3<Float>.zero, +) / Float(points.count)
        let normal = newellNormal(from: points)
        let normalLength = simd_length(normal)
        guard normalLength > .ulpOfOne else { return 0 }

        let unitNormal = normal / normalLength
        return points.reduce(into: Float(0)) { worst, point in
            let distance = abs(simd_dot(point - centroid, unitNormal))
            worst = max(worst, distance)
        }
    }

    /// Newell's method, computed about the centroid for float stability far from world origin.
    private func newellNormal(from points: [SIMD3<Float>]) -> SIMD3<Float> {
        let centroid = points.reduce(SIMD3<Float>.zero, +) / Float(points.count)
        var normal = SIMD3<Float>.zero
        for i in points.indices {
            let current = points[i] - centroid
            let next = points[(i + 1) % points.count] - centroid
            normal += simd_cross(current, next)
        }
        return normal
    }
}
