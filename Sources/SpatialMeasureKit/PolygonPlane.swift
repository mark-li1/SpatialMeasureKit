import simd

/// Newell's method, computed about the centroid for float stability far from world origin.
/// Shared by `AreaCalculator` (magnitude only) and `PolygonTriangulator` (direction, to project
/// points onto the polygon's plane).
func newellNormal(from points: [SIMD3<Float>]) -> SIMD3<Float> {
    let centroid = points.reduce(SIMD3<Float>.zero, +) / Float(points.count)
    var normal = SIMD3<Float>.zero
    for i in points.indices {
        let current = points[i] - centroid
        let next = points[(i + 1) % points.count] - centroid
        normal += simd_cross(current, next)
    }
    return normal
}

/// An orthonormal basis spanning the plane perpendicular to `normal`.
/// Returns `nil` for a degenerate (near-zero-length) normal, e.g. collinear input.
func planeBasis(normal: SIMD3<Float>) -> (u: SIMD3<Float>, v: SIMD3<Float>)? {
    let normalLength = simd_length(normal)
    guard normalLength > .ulpOfOne else { return nil }
    let unitNormal = normal / normalLength

    // Seed from whichever world axis is least aligned with the normal, so the cross product
    // below never collapses toward zero.
    let worldAxes: [SIMD3<Float>] = [.init(1, 0, 0), .init(0, 1, 0), .init(0, 0, 1)]
    let seed = worldAxes.min { abs(simd_dot($0, unitNormal)) < abs(simd_dot($1, unitNormal)) }!

    let u = simd_normalize(simd_cross(seed, unitNormal))
    let v = simd_cross(unitNormal, u)
    return (u, v)
}
