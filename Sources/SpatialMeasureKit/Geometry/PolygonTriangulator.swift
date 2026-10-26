import simd

public struct PolygonTriangulator: Sendable {
    /// Three indices into `Triangulation.vertices` describing one triangle.
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

    /// Triangles over a vertex list that may extend the input with the points where an outline
    /// crosses itself.
    public struct Triangulation: Equatable, Sendable {
        /// The input points at their original indices, followed by any points where the outline
        /// crosses itself.
        public let vertices: [SIMD3<Float>]
        /// Triangles as indices into `vertices`, all counter-clockwise around `normal`.
        public let triangles: [Triangle]
        /// Unit normal of the plane the triangles lie in.
        public let normal: SIMD3<Float>
    }

    public init() {}

    /// Triangles covering every region the outline `points` encloses, including outlines that
    /// cross or touch themselves: each enclosed region is covered once
    /// (nonzero winding rule), matching `AreaCalculator.area(of:)`. `nil` for fewer than
    /// three points or degenerate (collinear) input.
    public func triangulation(of points: [SIMD3<Float>]) -> Triangulation? {
        if let arrangement = PolygonArrangement(crossingOutline: points) {
            return Triangulation(
                vertices: arrangement.vertices,
                triangles: arrangement.triangles,
                normal: arrangement.normal
            )
        }
        let triangles = triangulate(points)
        guard !triangles.isEmpty else { return nil }
        let normal = newellNormal(from: points)
        guard simd_length(normal) > .ulpOfOne else { return nil }
        return Triangulation(vertices: points, triangles: triangles, normal: simd_normalize(normal))
    }

    /// Triangles covering a simple (non-self-intersecting) planar polygon, as indices into
    /// `points`. Handles concave outlines via ear clipping. Returns an empty array for fewer than
    /// three points, or for degenerate input (collinear points, zero-area polygon) the algorithm
    /// can't decompose. For an outline that may cross itself, use `triangulation(of:)`.
    func triangulate(_ points: [SIMD3<Float>]) -> [Triangle] {
        guard points.count >= 3 else { return [] }

        // A repeated point always sits exactly on a candidate ear's own corner, which the
        // containment test below reads as "another vertex is in the way" — every ear gets
        // rejected and the polygon is left half-clipped. Drop the repeats up front and map the
        // emitted indices back, so callers still get indices into their original array.
        let sourceIndices = deduplicatedIndices(of: points)
        guard sourceIndices.count >= 3 else { return [] }
        let vertices = sourceIndices.map { points[$0] }

        guard let projected = projectOntoPlane(vertices, normal: newellNormal(from: vertices)) else { return [] }

        // Ear clipping works on a counter-clockwise ring; flip if Newell's normal gave us the
        // opposite winding for this basis.
        var ring = Array(vertices.indices)
        if signedArea(of: ring, points: projected) < 0 {
            ring.reverse()
        }

        return clipEars(ring, points: projected).map {
            Triangle(sourceIndices[$0.a], sourceIndices[$0.b], sourceIndices[$0.c])
        }
    }

    /// Ear-clips a counter-clockwise `ring` of indices into `points`. The triangles use the same
    /// indices as `ring` and keep its counter-clockwise winding.
    func clipEars(_ ring: [Int], points: [SIMD2<Float>]) -> [Triangle] {
        var ring = ring
        var triangles: [Triangle] = []

        while ring.count > 3 {
            guard let earPosition = findEar(in: ring, points: points) else {
                // No ear found in a full pass over the ring — self-intersecting or degenerate
                // input the algorithm can't make progress on. Stop rather than loop forever.
                break
            }

            let previous = ring[(earPosition - 1 + ring.count) % ring.count]
            let current = ring[earPosition]
            let next = ring[(earPosition + 1) % ring.count]
            triangles.append(Triangle(previous, current, next))

            ring.remove(at: earPosition)
        }

        if ring.count == 3 {
            triangles.append(Triangle(ring[0], ring[1], ring[2]))
        }

        return triangles
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

            let corners = [ring[(i - 1 + ring.count) % ring.count], ring[i], ring[(i + 1) % ring.count]]
            let containsOther = ring.contains { vertex in
                !corners.contains(vertex) && isInsideTriangle(points[vertex], previous, current, next)
            }

            if !containsOther { return i }
        }
        return nil
    }

    private func isConvex(_ previous: SIMD2<Float>, _ current: SIMD2<Float>, _ next: SIMD2<Float>) -> Bool {
        cross2D(current - previous, next - current) > 0
    }

    private func isInsideTriangle(
        _ point: SIMD2<Float>,
        _ a: SIMD2<Float>,
        _ b: SIMD2<Float>,
        _ c: SIMD2<Float>
    ) -> Bool {
        let d1 = cross2D(b - a, point - a)
        let d2 = cross2D(c - b, point - b)
        let d3 = cross2D(a - c, point - c)

        let hasNegative = (d1 < 0) || (d2 < 0) || (d3 < 0)
        let hasPositive = (d1 > 0) || (d2 > 0) || (d3 > 0)
        return !(hasNegative && hasPositive)
    }
}
