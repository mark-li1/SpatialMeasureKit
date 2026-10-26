import simd

/// The largest circle that fits inside a polygon, lying in the polygon's best-fit plane.
public struct InscribedCircle: Equatable, Sendable {
    /// The pole of inaccessibility: the inside point farthest from the outline.
    public let center: SIMD3<Float>
    /// The distance from `center` to the nearest point of the outline, in the points' unit.
    public let radius: Float
}

public struct AreaCalculator: Sendable {
    public init() {}

    /// The largest circle that fits inside the region the outline `points` encloses, found with
    /// the polylabel algorithm (Agafonkin, 2016) to within `precision`, in the points' unit. Its
    /// centre is the inside point farthest from the outline — unlike `centroid(of:)`, it stays
    /// inside concave shapes and away from the edges. Among circles within `precision` of the
    /// largest, the one centred nearest `centroid(of:)` wins, so a shape with many equally roomy
    /// points (a rectangle's whole middle line) gives one stable centre that moves only a little
    /// when the outline does. For an outline that crosses itself, the circle stays inside the
    /// enclosed regions (nonzero winding rule) and clear of every line of the outline. `nil` for
    /// fewer than three points, degenerate (collinear) input, or a sliver too thin to search at
    /// `precision`.
    public func largestInscribedCircle(of points: [SIMD3<Float>], precision: Float = 0.001) -> InscribedCircle? {
        searchCircle(in: points, nearest: nil, minimumRoom: nil, precision: precision)
    }

    public func inscribedCircle(
        of points: [SIMD3<Float>],
        radius: Float,
        nearest target: SIMD3<Float>? = nil,
        precision: Float = 0.001
    ) -> InscribedCircle? {
        searchCircle(in: points, nearest: target, minimumRoom: max(radius, 0), precision: precision)
    }

    /// How far `point` is from the nearest line of the outline `points`, measured in the outline's
    /// best-fit plane: positive inside the enclosed regions (nonzero winding rule), negative
    /// outside. Compare it with `largestInscribedCircle(of:precision:)`'s radius to tell whether a
    /// spot still has most of the room the outline offers. `nil` for fewer than three points or
    /// degenerate (collinear) input.
    public func clearance(at point: SIMD3<Float>, in points: [SIMD3<Float>]) -> Float? {
        let ring = deduplicatedIndices(of: points)
        guard ring.count >= 3 else { return nil }
        let outline = ring.map { points[$0] }
        let normal = unsignedNormal(from: outline)
        guard let flat = projectOntoPlane(outline, normal: normal),
              let flatPoint = projectOntoPlane(point, of: outline, normal: normal)
        else { return nil }
        return signedDistance(from: flatPoint, to: flat)
    }

    /// Area enclosed by the outline `points`, in the square of their unit. An outline that crosses
    /// or touches itself counts every enclosed region once (nonzero winding rule), so a bow-tie
    /// measures the sum of its two loops rather than their difference.
    public func area(of points: [SIMD3<Float>]) -> Float {
        guard points.count >= 3 else { return 0 }
        if let arrangement = PolygonArrangement(crossingOutline: points) {
            return arrangement.area
        }
        return simd_length(newellNormal(from: points)) / 2
    }

    /// Unit vector perpendicular to the polygon's best-fit plane, via Newell's method.
    /// `nil` for fewer than three points or degenerate (collinear) input. An outline that crosses
    /// itself has loops turning both ways, so there only the plane is meaningful, not the sign —
    /// the same normal `PolygonTriangulator.triangulation(of:)` returns.
    public func normal(of points: [SIMD3<Float>]) -> SIMD3<Float>? {
        guard points.count >= 3 else { return nil }
        return planeNormal(of: points)
    }

    /// Area-weighted centroid of the polygon. `nil` for empty input. For an outline that crosses
    /// itself, every enclosed region is weighted once, matching `area(of:)`.
    ///
    /// Falls back to the plain vertex average for fewer than three points, or for degenerate
    /// (collinear) input the triangulator can't decompose — the area-weighted result is
    /// undefined there since there's no area to weight by.
    public func centroid(of points: [SIMD3<Float>]) -> SIMD3<Float>? {
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
    public func planarityError(of points: [SIMD3<Float>]) -> Float {
        guard points.count >= 3, let normal = planeNormal(of: points) else { return 0 }

        let centroid = points.reduce(SIMD3<Float>.zero, +) / Float(points.count)
        return points.reduce(into: Float(0)) { worst, point in
            let distance = abs(simd_dot(point - centroid, normal))
            worst = max(worst, distance)
        }
    }

    private func searchCircle(
        in points: [SIMD3<Float>],
        nearest target: SIMD3<Float>?,
        minimumRoom: Float?,
        precision: Float
    ) -> InscribedCircle? {
        let ring = deduplicatedIndices(of: points)
        guard ring.count >= 3 else { return nil }
        let outline = ring.map { points[$0] }
        let normal = unsignedNormal(from: outline)
        guard let flat = projectOntoPlane(outline, normal: normal),
              let goal = target ?? centroid(of: points),
              let preferred = projectOntoPlane(goal, of: outline, normal: normal),
              let pole = poleOfInaccessibility(
                of: flat,
                precision: max(precision, 1e-6),
                preferring: preferred,
                minimumRoom: minimumRoom
              ),
              let center = liftFromPlane(pole.center, of: outline, normal: normal)
        else { return nil }
        return InscribedCircle(center: center, radius: pole.distance)
    }

    private func planeNormal(of points: [SIMD3<Float>]) -> SIMD3<Float>? {
        if let arrangement = PolygonArrangement(crossingOutline: points) {
            return arrangement.normal
        }
        let normal = newellNormal(from: points)
        let length = simd_length(normal)
        guard length > .ulpOfOne else { return nil }
        return normal / length
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
