import simd

/// The largest circle that fits inside a polygon, lying in the polygon's best-fit plane.
public struct InscribedCircle: Equatable, Sendable {
    /// The pole of inaccessibility: the inside point farthest from the outline.
    public let center: SIMD3<Float>
    /// The distance from `center` to the nearest point of the outline, in the points' unit.
    public let radius: Float
}

public struct AreaCalculator {
    public init() {}

    /// The largest circle that fits inside the region the outline `points` encloses, found with
    /// the polylabel algorithm (Agafonkin, 2016) to within `precision`, in the points' unit. Its
    /// centre is the inside point farthest from the outline — unlike `centroid(from:)`, it stays
    /// inside concave shapes and away from the edges. Among circles within `precision` of the
    /// largest, the one centred nearest `centroid(from:)` wins, so a shape with many equally roomy
    /// points (a rectangle's whole middle line) gives one stable centre that moves only a little
    /// when the outline does. For an outline that crosses itself, the circle stays inside the
    /// enclosed regions (nonzero winding rule) and clear of every line of the outline. `nil` for
    /// fewer than three points or degenerate (collinear) input.
    public func largestInscribedCircle(from points: [SIMD3<Float>], precision: Float = 0.001) -> InscribedCircle? {
        let ring = deduplicatedIndices(of: points)
        guard ring.count >= 3 else { return nil }
        let outline = ring.map { points[$0] }
        let normal = unsignedNormal(from: outline)
        guard let flat = projectOntoPlane(outline, normal: normal),
              let regionCentroid = self.centroid(from: points),
              let preferred = projectOntoPlane(regionCentroid, of: outline, normal: normal),
              let pole = poleOfInaccessibility(of: flat, precision: max(precision, 1e-6), preferring: preferred),
              let center = liftFromPlane(pole.center, of: outline, normal: normal)
        else { return nil }
        return InscribedCircle(center: center, radius: pole.distance)
    }

    /// Area enclosed by the outline `points`, in the square of their unit. An outline that crosses
    /// or touches itself counts every enclosed region once (nonzero winding rule), so a bow-tie
    /// measures the sum of its two loops rather than their difference.
    public func computeArea(from points: [SIMD3<Float>]) -> Float {
        guard points.count >= 3 else { return 0 }
        if let arrangement = PolygonArrangement(crossingOutline: points) {
            return arrangement.area
        }
        return simd_length(newellNormal(from: points)) / 2
    }

    /// Unit vector perpendicular to the polygon's best-fit plane, via Newell's method.
    /// `nil` for fewer than three points or degenerate (collinear) input. Loops of a
    /// self-crossing outline that turn in opposite directions cancel here; use
    /// `PolygonTriangulator.triangulation(of:)` for a normal that matches its triangles.
    public func normal(from points: [SIMD3<Float>]) -> SIMD3<Float>? {
        guard points.count >= 3 else { return nil }
        let normal = newellNormal(from: points)
        let length = simd_length(normal)
        guard length > .ulpOfOne else { return nil }
        return normal / length
    }

    /// Area-weighted centroid of the polygon. `nil` for empty input. For an outline that crosses
    /// itself, every enclosed region is weighted once, matching `computeArea(from:)`.
    ///
    /// Falls back to the plain vertex average for fewer than three points, or for degenerate
    /// (collinear) input the triangulator can't decompose — the area-weighted result is
    /// undefined there since there's no area to weight by.
    public func centroid(from points: [SIMD3<Float>]) -> SIMD3<Float>? {
        guard !points.isEmpty else { return nil }
        let vertexAverage = points.reduce(SIMD3<Float>.zero, +) / Float(points.count)

        if let arrangement = PolygonArrangement(crossingOutline: points) {
            return weightedCentroid(of: arrangement.triangles, vertices: arrangement.vertices) ?? vertexAverage
        }
        let triangles = PolygonTriangulator().triangulate(points)
        return weightedCentroid(of: triangles, vertices: points) ?? vertexAverage
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

    private func weightedCentroid(
        of triangles: [PolygonTriangulator.Triangle],
        vertices: [SIMD3<Float>]
    ) -> SIMD3<Float>? {
        var weightedSum = SIMD3<Float>.zero
        var totalWeight: Float = 0
        for triangle in triangles {
            let a = vertices[triangle.a]
            let b = vertices[triangle.b]
            let c = vertices[triangle.c]
            let weight = simd_length(simd_cross(b - a, c - a)) / 2
            weightedSum += (a + b + c) / 3 * weight
            totalWeight += weight
        }
        guard totalWeight > .ulpOfOne else { return nil }
        return weightedSum / totalWeight
    }
}
