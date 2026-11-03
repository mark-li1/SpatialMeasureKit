import simd

/// The regions enclosed by an outline that crosses or touches itself, cut apart where it does.
/// Each enclosed region counts once (the nonzero winding rule).
struct PolygonArrangement {
    /// The input points at their original indices, followed by the points where the outline
    /// crosses itself.
    let vertices: [SIMD3<Float>]
    /// Triangles over `vertices`, counter-clockwise around `normal`.
    let triangles: [PolygonTriangulator.Triangle]
    /// Unit normal of the outline's best-fit plane.
    let normal: SIMD3<Float>
    /// Total area of the enclosed regions.
    let area: Float

    /// `nil` when the outline never crosses or touches itself, or has no area.
    init?(crossingOutline points: [SIMD3<Float>]) {
        let ring = deduplicatedIndices(of: points)
        guard ring.count >= 3 else { return nil }
        let outline = ring.map { points[$0] }
        let planeNormal = unsignedNormal(from: outline)
        guard let flatOutline = projectOntoPlane(outline, normal: planeNormal) else { return nil }

        var graph = OutlineGraph(outline: outline, flatOutline: flatOutline)
        guard graph.splitAtSelfContacts() else { return nil }

        let triangulator = PolygonTriangulator()
        var faceTriangles: [PolygonTriangulator.Triangle] = []
        var enclosedArea: Float = 0
        for face in graph.boundedFaces() {
            let triangles = triangulator.clipEars(face, points: graph.flatPositions)
            guard let sample = graph.interiorPoint(of: triangles),
                  windingNumber(of: sample, around: flatOutline) != 0
            else { continue }
            faceTriangles += triangles
            enclosedArea += signedArea(of: face, points: graph.flatPositions)
        }
        guard !faceTriangles.isEmpty else { return nil }

        let inputIndex = { (vertex: Int) -> Int in
            vertex < ring.count ? ring[vertex] : points.count + vertex - ring.count
        }
        vertices = points + graph.positions.dropFirst(ring.count)
        triangles = faceTriangles.map { .init(inputIndex($0.a), inputIndex($0.b), inputIndex($0.c)) }
        normal = simd_normalize(planeNormal)
        area = enclosedArea
    }
}

/// The outline as a planar graph: its edges cut at every point where they cross or touch.
private struct OutlineGraph {
    private struct Stop {
        let t: Float
        let vertex: Int
    }

    private struct Segment: Hashable, Comparable {
        let a: Int
        let b: Int

        init(_ first: Int, _ second: Int) {
            a = min(first, second)
            b = max(first, second)
        }

        static func < (lhs: Segment, rhs: Segment) -> Bool {
            (lhs.a, lhs.b) < (rhs.a, rhs.b)
        }
    }

    private struct DirectedEdge: Hashable {
        let from: Int
        let to: Int
    }

    private(set) var positions: [SIMD3<Float>]
    private(set) var flatPositions: [SIMD2<Float>]
    private let outlineCount: Int
    private let tolerance: Float
    private var canonical: [Int]
    private var stops: [[Stop]]

    init(outline: [SIMD3<Float>], flatOutline: [SIMD2<Float>]) {
        positions = outline
        flatPositions = flatOutline
        outlineCount = outline.count
        let extent = flatOutline.map { max(abs($0.x), abs($0.y)) }.max() ?? 0
        tolerance = 1e-4 * max(extent, 1)
        canonical = Array(outline.indices)
        stops = Array(repeating: [], count: outline.count)
    }

    mutating func splitAtSelfContacts() -> Bool {
        var touches = mergeCoincidentVertices()
        for i in 0..<outlineCount {
            for j in (i + 1)..<outlineCount {
                if splitContact(between: i, and: j) {
                    touches = true
                }
            }
        }
        return touches
    }

    func boundedFaces() -> [[Int]] {
        var neighbors: [Int: [Int]] = [:]
        for segment in prunedSegments() {
            neighbors[segment.a, default: []].append(segment.b)
            neighbors[segment.b, default: []].append(segment.a)
        }
        for vertex in neighbors.keys {
            neighbors[vertex]?.sort { angle(from: vertex, to: $0) < angle(from: vertex, to: $1) }
        }

        var visited = Set<DirectedEdge>()
        var faces: [[Int]] = []
        for vertex in neighbors.keys.sorted() {
            for neighbor in neighbors[vertex] ?? [] {
                var edge = DirectedEdge(from: vertex, to: neighbor)
                var face: [Int] = []
                while visited.insert(edge).inserted {
                    face.append(edge.from)
                    guard let around = neighbors[edge.to],
                          let back = around.firstIndex(of: edge.from)
                    else { break }
                    edge = DirectedEdge(from: edge.to, to: around[(back - 1 + around.count) % around.count])
                }
                if signedArea(of: face, points: flatPositions) > tolerance * tolerance {
                    faces.append(face)
                }
            }
        }
        return faces
    }

    func interiorPoint(of triangles: [PolygonTriangulator.Triangle]) -> SIMD2<Float>? {
        triangles
            .max { flatArea(of: $0) < flatArea(of: $1) }
            .map { (flatPositions[$0.a] + flatPositions[$0.b] + flatPositions[$0.c]) / 3 }
    }

    private mutating func mergeCoincidentVertices() -> Bool {
        var merged = false
        for j in 0..<outlineCount {
            for i in 0..<j where canonical[i] == i && !areAdjacent(i, j)
                && simd_distance(flatPositions[i], flatPositions[j]) <= tolerance {
                canonical[j] = i
                merged = true
                break
            }
        }
        return merged
    }

    private mutating func splitContact(between i: Int, and j: Int) -> Bool {
        let p = flatPositions[i]
        let r = flatPositions[next(i)] - p
        let q = flatPositions[j]
        let s = flatPositions[next(j)] - q
        guard simd_length(r) > tolerance, simd_length(s) > tolerance else { return false }

        let denominator = cross2D(r, s)
        guard abs(denominator) > 1e-6 * simd_length(r) * simd_length(s) else {
            return splitCollinearOverlap(between: i, and: j)
        }
        guard !areAdjacent(i, j) else { return false }

        let t = cross2D(q - p, s) / denominator
        let u = cross2D(q - p, r) / denominator
        let tSlack = tolerance / simd_length(r)
        let uSlack = tolerance / simd_length(s)
        guard t >= -tSlack, t <= 1 + tSlack, u >= -uSlack, u <= 1 + uSlack else { return false }

        let tInside = t > tSlack && t < 1 - tSlack
        let uInside = u > uSlack && u < 1 - uSlack
        switch (tInside, uInside) {
        case (true, true):
            let lifted = positions[i] + t * (positions[next(i)] - positions[i])
            let vertex = crossingVertex(at: p + t * r, lifted: lifted)
            stops[i].append(Stop(t: t, vertex: vertex))
            stops[j].append(Stop(t: u, vertex: vertex))
        case (true, false):
            stops[i].append(Stop(t: t, vertex: canonical[u < 0.5 ? j : next(j)]))
        case (false, true):
            stops[j].append(Stop(t: u, vertex: canonical[t < 0.5 ? i : next(i)]))
        case (false, false):
            return false
        }
        return true
    }

    private mutating func splitCollinearOverlap(between i: Int, and j: Int) -> Bool {
        let p = flatPositions[i]
        let r = flatPositions[next(i)] - p
        guard abs(cross2D(r, flatPositions[j] - p)) <= tolerance * simd_length(r) else { return false }
        let cutI = cutAtEndpoints(of: j, onEdge: i)
        let cutJ = cutAtEndpoints(of: i, onEdge: j)
        return cutI || cutJ
    }

    private mutating func cutAtEndpoints(of other: Int, onEdge edge: Int) -> Bool {
        let p = flatPositions[edge]
        let r = flatPositions[next(edge)] - p
        let slack = tolerance / simd_length(r)
        var cut = false
        for endpoint in [other, next(other)] {
            let t = simd_dot(flatPositions[endpoint] - p, r) / simd_length_squared(r)
            if t > slack, t < 1 - slack {
                stops[edge].append(Stop(t: t, vertex: canonical[endpoint]))
                cut = true
            }
        }
        return cut
    }

    private mutating func crossingVertex(at point: SIMD2<Float>, lifted: SIMD3<Float>) -> Int {
        let existing = flatPositions.indices.first { index in
            (index >= outlineCount || canonical[index] == index)
                && simd_distance(flatPositions[index], point) <= tolerance
        }
        if let existing { return existing }
        flatPositions.append(point)
        positions.append(lifted)
        return flatPositions.count - 1
    }

    private func prunedSegments() -> [Segment] {
        var segments = Set<Segment>()
        for edge in 0..<outlineCount {
            let ends = [Stop(t: 0, vertex: canonical[edge]), Stop(t: 1, vertex: canonical[next(edge)])]
            let ordered = (ends + stops[edge]).sorted { $0.t < $1.t }
            for (from, to) in zip(ordered, ordered.dropFirst()) where from.vertex != to.vertex {
                segments.insert(Segment(from.vertex, to.vertex))
            }
        }

        var degree: [Int: Int] = [:]
        for segment in segments {
            degree[segment.a, default: 0] += 1
            degree[segment.b, default: 0] += 1
        }
        while let dangling = segments.first(where: { degree[$0.a] == 1 || degree[$0.b] == 1 }) {
            segments.remove(dangling)
            degree[dangling.a, default: 0] -= 1
            degree[dangling.b, default: 0] -= 1
        }
        return segments.sorted()
    }

    private func angle(from vertex: Int, to neighbor: Int) -> Float {
        let direction = flatPositions[neighbor] - flatPositions[vertex]
        return atan2(direction.y, direction.x)
    }

    private func flatArea(of triangle: PolygonTriangulator.Triangle) -> Float {
        let a = flatPositions[triangle.a]
        return abs(cross2D(flatPositions[triangle.b] - a, flatPositions[triangle.c] - a)) / 2
    }

    private func next(_ index: Int) -> Int {
        (index + 1) % outlineCount
    }

    private func areAdjacent(_ i: Int, _ j: Int) -> Bool {
        j == i + 1 || (i == 0 && j == outlineCount - 1)
    }
}
