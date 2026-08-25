import simd

public struct AreaCalculator {
    public init() {}

    public func computeArea(from points: [SIMD3<Float>]) -> Float {
        guard points.count >= 3 else { return 0 }
        return simd_length(newellNormal(from: points)) / 2
    }

    /// Unit vector perpendicular to the polygon's best-fit plane, via Newell's method.
    /// `nil` for fewer than three points or degenerate (collinear) input.
    public func normal(from points: [SIMD3<Float>]) -> SIMD3<Float>? {
        guard points.count >= 3 else { return nil }
        let normal = newellNormal(from: points)
        let length = simd_length(normal)
        guard length > .ulpOfOne else { return nil }
        return normal / length
    }

    /// Area-weighted centroid of the polygon. `nil` for empty input.
    ///
    /// Falls back to the plain vertex average for fewer than three points, or for degenerate
    /// (collinear) input the triangulator can't decompose — the area-weighted result is
    /// undefined there since there's no area to weight by.
    public func centroid(from points: [SIMD3<Float>]) -> SIMD3<Float>? {
        guard !points.isEmpty else { return nil }

        let triangles = PolygonTriangulator().triangulate(points)
        guard !triangles.isEmpty else {
            return points.reduce(SIMD3<Float>.zero, +) / Float(points.count)
        }

        var weightedSum = SIMD3<Float>.zero
        var totalWeight: Float = 0
        for triangle in triangles {
            let a = points[triangle.a]
            let b = points[triangle.b]
            let c = points[triangle.c]
            let weight = simd_length(simd_cross(b - a, c - a)) / 2
            weightedSum += (a + b + c) / 3 * weight
            totalWeight += weight
        }

        guard totalWeight > .ulpOfOne else {
            return points.reduce(SIMD3<Float>.zero, +) / Float(points.count)
        }

        return weightedSum / totalWeight
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
}
