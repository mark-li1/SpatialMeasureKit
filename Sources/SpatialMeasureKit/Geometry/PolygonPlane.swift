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

/// A plane normal that ignores which way each part of the outline turns, so loops that wind in
/// opposite directions (a bow-tie) reinforce each other instead of cancelling like Newell's.
/// Its sign is arbitrary; only the plane it describes is meaningful.
func unsignedNormal(from points: [SIMD3<Float>]) -> SIMD3<Float> {
    let centroid = points.reduce(SIMD3<Float>.zero, +) / Float(points.count)
    let fan = points.indices.map { i in
        simd_cross(points[i] - centroid, points[(i + 1) % points.count] - centroid)
    }
    guard let reference = fan.max(by: { simd_length_squared($0) < simd_length_squared($1) }) else {
        return .zero
    }
    return fan.reduce(SIMD3<Float>.zero) { sum, piece in
        sum + (simd_dot(piece, reference) < 0 ? -piece : piece)
    }
}

/// `points` in 2D coordinates on the plane perpendicular to `normal`, centred on their centroid.
/// Counter-clockwise in these coordinates means counter-clockwise around `normal`.
/// `nil` for a degenerate normal.
func projectOntoPlane(_ points: [SIMD3<Float>], normal: SIMD3<Float>) -> [SIMD2<Float>]? {
    guard let (u, v) = planeBasis(normal: normal) else { return nil }
    let centroid = points.reduce(SIMD3<Float>.zero, +) / Float(points.count)
    return points.map { point in
        let offset = point - centroid
        return SIMD2(simd_dot(offset, u), simd_dot(offset, v))
    }
}

/// `point` in the same 2D coordinates `projectOntoPlane(_:normal:)` gives `points`. `nil` for a
/// degenerate normal.
func projectOntoPlane(_ point: SIMD3<Float>, of points: [SIMD3<Float>], normal: SIMD3<Float>) -> SIMD2<Float>? {
    guard let (u, v) = planeBasis(normal: normal) else { return nil }
    let centroid = points.reduce(SIMD3<Float>.zero, +) / Float(points.count)
    let offset = point - centroid
    return SIMD2(simd_dot(offset, u), simd_dot(offset, v))
}

/// The inverse of `projectOntoPlane(_:normal:)` for the same `points` and `normal`: a point in
/// the plane's 2D coordinates, back in 3D. `nil` for a degenerate normal.
func liftFromPlane(_ point: SIMD2<Float>, of points: [SIMD3<Float>], normal: SIMD3<Float>) -> SIMD3<Float>? {
    guard let (u, v) = planeBasis(normal: normal) else { return nil }
    let centroid = points.reduce(SIMD3<Float>.zero, +) / Float(points.count)
    return centroid + u * point.x + v * point.y
}

/// Shortest distance from `point` to the segment from `a` to `b`.
func distance(from point: SIMD2<Float>, toSegmentFrom a: SIMD2<Float>, to b: SIMD2<Float>) -> Float {
    let ab = b - a
    let t = min(max(simd_dot(point - a, ab) / max(simd_length_squared(ab), .ulpOfOne), 0), 1)
    return simd_distance(point, a + t * ab)
}

/// Indices into `points` with consecutive duplicates collapsed. The polygon is a closed ring,
/// so a last point repeating the first counts as consecutive too.
func deduplicatedIndices(of points: [SIMD3<Float>]) -> [Int] {
    let epsilon: Float = 1e-6

    var kept: [Int] = []
    for index in points.indices {
        if let last = kept.last, simd_distance(points[last], points[index]) <= epsilon { continue }
        kept.append(index)
    }

    if kept.count >= 2, let first = kept.first, let last = kept.last,
       simd_distance(points[first], points[last]) <= epsilon {
        kept.removeLast()
    }

    return kept
}

/// Shoelace area of the ring `ring` (indices into `points`): positive when counter-clockwise.
func signedArea(of ring: [Int], points: [SIMD2<Float>]) -> Float {
    var sum: Float = 0
    for i in ring.indices {
        let p = points[ring[i]]
        let q = points[ring[(i + 1) % ring.count]]
        sum += p.x * q.y - q.x * p.y
    }
    return sum / 2
}

/// How many times the closed outline `polygon` winds around `point`: 0 means outside.
func windingNumber(of point: SIMD2<Float>, around polygon: [SIMD2<Float>]) -> Int {
    var winding = 0
    for i in polygon.indices {
        let a = polygon[i]
        let b = polygon[(i + 1) % polygon.count]
        let side = cross2D(b - a, point - a)
        if a.y <= point.y {
            if b.y > point.y, side > 0 { winding += 1 }
        } else if b.y <= point.y, side < 0 {
            winding -= 1
        }
    }
    return winding
}

/// The z component of the 3D cross product of two 2D vectors.
func cross2D(_ a: SIMD2<Float>, _ b: SIMD2<Float>) -> Float {
    a.x * b.y - a.y * b.x
}
