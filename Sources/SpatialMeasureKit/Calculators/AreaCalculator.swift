import simd

/// A circle that fits inside an outline, in the outline's plane.
public struct InscribedCircle: Equatable, Sendable {
    public let center: SIMD3<Float>
    /// The distance from `center` to the nearest line of the outline, in meters.
    public let radius: Float
}

/// Measures flat shapes outlined by points: area, center, plane and how much room a spot has.
///
/// Points are in meters and should lie roughly on one surface. An outline may cross itself;
/// every region it encloses then counts once (the nonzero winding rule).
public struct AreaCalculator: Sendable {
    public init() {}

    /// The largest circle that fits inside the outline, found with the polylabel algorithm to
    /// within `precision` meters.
    ///
    /// Its center is a good place for a label: unlike `centroid(of:)`, it stays inside concave
    /// shapes. When many spots are equally roomy, the one nearest the centroid wins, so the center
    /// doesn't jump around. Returns `nil` for fewer than three points, points on one line, or a
    /// sliver thinner than `precision`.
    public func largestInscribedCircle(of points: [SIMD3<Float>], precision: Float = 0.001) -> InscribedCircle? {
        searchCircle(in: points, nearest: nil, minimumRoom: nil, precision: precision)
    }

    /// The spot nearest `target` that has room for a circle of `radius`, found to within
    /// `precision` meters.
    ///
    /// Useful for keeping a label near the middle of a shape: with no `target`, it stays at the
    /// centroid while the label fits there, and moves only as far as it has to. The returned
    /// radius is the real room at that spot, so it can be larger than `radius`.
    ///
    /// Returns `nil` when no spot has that much room, or for the outlines where
    /// `largestInscribedCircle(of:precision:)` returns `nil`.
    public func inscribedCircle(
        of points: [SIMD3<Float>],
        radius: Float,
        nearest target: SIMD3<Float>? = nil,
        precision: Float = 0.001
    ) -> InscribedCircle? {
        searchCircle(in: points, nearest: target, minimumRoom: max(radius, 0), precision: precision)
    }

    /// How much room `point` has: its distance to the nearest line of the outline, in meters.
    ///
    /// Positive inside the shape, negative outside, measured in the outline's plane. Returns `nil`
    /// for fewer than three points or points on one line.
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

    /// The area the outline encloses, in square meters.
    ///
    /// A bow-tie counts both of its loops, so its area is their sum, not their difference.
    /// Returns 0 for fewer than three points.
    public func area(of points: [SIMD3<Float>]) -> Float {
        guard points.count >= 3 else { return 0 }
        if let arrangement = PolygonArrangement(crossingOutline: points) {
            return arrangement.area
        }
        return simd_length(newellNormal(from: points)) / 2
    }

    /// A unit vector perpendicular to the outline's plane.
    ///
    /// For an outline that crosses itself, only the plane matters, not which side the vector
    /// points to. Returns `nil` for fewer than three points or points on one line.
    public func normal(of points: [SIMD3<Float>]) -> SIMD3<Float>? {
        guard points.count >= 3 else { return nil }
        return planeNormal(of: points)
    }

    /// The center of the enclosed area, weighted by area.
    ///
    /// For an outline with no area (fewer than three points, or all on one line) this is the
    /// average of the points. Returns `nil` only for an empty array.
    public func centroid(of points: [SIMD3<Float>]) -> SIMD3<Float>? {
        guard !points.isEmpty else { return nil }
        let vertexAverage = points.reduce(SIMD3<Float>.zero, +) / Float(points.count)

        if let arrangement = PolygonArrangement(crossingOutline: points) {
            return weightedCentroid(of: arrangement.triangles, vertices: arrangement.vertices) ?? vertexAverage
        }
        let triangles = PolygonTriangulator().triangulate(points)
        return weightedCentroid(of: triangles, vertices: points) ?? vertexAverage
    }

    /// How far, in meters, the farthest point is from the outline's plane.
    ///
    /// 0 means all points lie on one surface. A large value usually means the outline went around
    /// a corner, or the tracking was noisy.
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
