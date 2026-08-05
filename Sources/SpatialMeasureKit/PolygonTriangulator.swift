import simd

public struct PolygonTriangulator {
    /// Three vertex indices, into the `points` array passed to `triangulate(_:)`, describing one
    /// triangle.
    public struct Triangle: Equatable, Sendable {
        public let a: Int
        public let b: Int
        public let c: Int

        public init(_ a: Int, _ b: Int, _ c: Int) {
            self.a = a
            self.b = b
            self.c = c
        }
    }

    public init() {}

    /// Triangles covering a simple (non-self-intersecting) planar polygon, as indices into
    /// `points`. Handles concave outlines via ear clipping. Returns an empty array for fewer than
    /// three points, or for degenerate input (collinear points, zero-area polygon) the algorithm
    /// can't decompose.
    public func triangulate(_ points: [SIMD3<Float>]) -> [Triangle] {
        guard points.count >= 3 else { return [] }

        // A repeated point always sits exactly on a candidate ear's own corner, which the
        // containment test below reads as "another vertex is in the way" — every ear gets
        // rejected and the polygon is left half-clipped. Drop the repeats up front and map the
        // emitted indices back, so callers still get indices into their original array.
        let sourceIndices = deduplicatedIndices(of: points)
        guard sourceIndices.count >= 3 else { return [] }
        let vertices = sourceIndices.map { points[$0] }

        let normal = newellNormal(from: vertices)
        guard let (u, v) = planeBasis(normal: normal) else { return [] }

        let centroid = vertices.reduce(SIMD3<Float>.zero, +) / Float(vertices.count)
        let projected = vertices.map { vertex -> SIMD2<Float> in
            let offset = vertex - centroid
            return SIMD2(simd_dot(offset, u), simd_dot(offset, v))
        }

        // Ear clipping works on a counter-clockwise ring; flip if Newell's normal gave us the
        // opposite winding for this basis.
        var ring = Array(vertices.indices)
        if signedArea(of: ring, points: projected) < 0 {
            ring.reverse()
        }

        var triangles: [Triangle] = []

        func emitTriangle(_ a: Int, _ b: Int, _ c: Int) {
            triangles.append(Triangle(sourceIndices[a], sourceIndices[b], sourceIndices[c]))
        }

        while ring.count > 3 {
            guard let earPosition = findEar(in: ring, points: projected) else {
                // No ear found in a full pass over the ring — self-intersecting or degenerate
                // input the algorithm can't make progress on. Stop rather than loop forever.
                break
            }

            let previous = ring[(earPosition - 1 + ring.count) % ring.count]
            let current = ring[earPosition]
            let next = ring[(earPosition + 1) % ring.count]
            emitTriangle(previous, current, next)

            ring.remove(at: earPosition)
        }

        if ring.count == 3 {
            emitTriangle(ring[0], ring[1], ring[2])
        }

        return triangles
    }

    /// Indices into `points` with consecutive duplicates collapsed. The polygon is a closed ring,
    /// so a last point repeating the first counts as consecutive too.
    private func deduplicatedIndices(of points: [SIMD3<Float>]) -> [Int] {
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

    private func signedArea(of ring: [Int], points: [SIMD2<Float>]) -> Float {
        var sum: Float = 0
        for i in ring.indices {
            let p = points[ring[i]]
            let q = points[ring[(i + 1) % ring.count]]
            sum += p.x * q.y - q.x * p.y
        }
        return sum / 2
    }

    /// Finds the index *within `ring`* (not the point index itself) of a vertex that can be
    /// safely clipped: its triangle with its two neighbours is convex, and no other remaining
    /// vertex lies inside that triangle.
    private func findEar(in ring: [Int], points: [SIMD2<Float>]) -> Int? {
        for i in ring.indices {
            let previous = points[ring[(i - 1 + ring.count) % ring.count]]
            let current = points[ring[i]]
            let next = points[ring[(i + 1) % ring.count]]

            guard isConvex(previous, current, next) else { continue }

            let containsOther = ring.indices.contains { j in
                guard j != i,
                      j != (i - 1 + ring.count) % ring.count,
                      j != (i + 1) % ring.count
                else { return false }
                return isInsideTriangle(points[ring[j]], previous, current, next)
            }

            if !containsOther { return i }
        }
        return nil
    }

    private func isConvex(_ previous: SIMD2<Float>, _ current: SIMD2<Float>, _ next: SIMD2<Float>) -> Bool {
        cross(current - previous, next - current) > 0
    }

    private func isInsideTriangle(
        _ point: SIMD2<Float>,
        _ a: SIMD2<Float>,
        _ b: SIMD2<Float>,
        _ c: SIMD2<Float>
    ) -> Bool {
        let d1 = cross(b - a, point - a)
        let d2 = cross(c - b, point - b)
        let d3 = cross(a - c, point - c)

        let hasNegative = (d1 < 0) || (d2 < 0) || (d3 < 0)
        let hasPositive = (d1 > 0) || (d2 > 0) || (d3 > 0)
        return !(hasNegative && hasPositive)
    }

    private func cross(_ a: SIMD2<Float>, _ b: SIMD2<Float>) -> Float {
        a.x * b.y - a.y * b.x
    }
}
