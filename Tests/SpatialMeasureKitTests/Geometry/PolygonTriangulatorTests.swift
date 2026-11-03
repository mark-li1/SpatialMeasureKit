import Testing
import simd
import Foundation
@testable import SpatialMeasureKit

@Suite("PolygonTriangulator")
struct PolygonTriangulatorTests {
    private let areaCalculator = AreaCalculator()

    // All fixtures below lie flat at y = 0, so area/containment checks work in the (x, z) plane.

    // A 2×2 square with the (1..2, 1..2) corner cut out, so its area is 3.
    // The starting vertex matters: a triangle fan from vertex 0 is correct whenever the polygon is
    // star-shaped about that vertex, and this L is star-shaped about its (0,0) corner — starting
    // there would let the old, broken fan pass every test below. Starting at (2,1), the corner
    // beside the notch, is what makes these tests discriminate.
    private let lShape = [
        SIMD3<Float>(2, 0, 1),
        SIMD3<Float>(1, 0, 1),
        SIMD3<Float>(1, 0, 2),
        SIMD3<Float>(0, 0, 2),
        SIMD3<Float>(0, 0, 0),
        SIMD3<Float>(2, 0, 0),
    ]

    
    private func starPoints() -> [SIMD3<Float>] {
        let outerRadius: Float = 2
        let innerRadius: Float = 0.8
        return (0..<10).map { i -> SIMD3<Float> in
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let angle = Float(i) * .pi / 5
            return SIMD3<Float>(radius * cos(angle), 0, radius * sin(angle))
        }
    }

    private func triangleArea(_ a: SIMD3<Float>, _ b: SIMD3<Float>, _ c: SIMD3<Float>) -> Float {
        simd_length(simd_cross(b - a, c - a)) / 2
    }

    private func summedArea(_ triangles: [PolygonTriangulator.Triangle], points: [SIMD3<Float>]) -> Float {
        triangles.reduce(into: Float(0)) { total, triangle in
            total += triangleArea(points[triangle.a], points[triangle.b], points[triangle.c])
        }
    }

    /// Ray-casting point-in-polygon test on the (x, z) plane.
    private func contains(_ point: SIMD2<Float>, polygon: [SIMD3<Float>]) -> Bool {
        var inside = false
        var j = polygon.count - 1
        for i in polygon.indices {
            let pi = SIMD2<Float>(polygon[i].x, polygon[i].z)
            let pj = SIMD2<Float>(polygon[j].x, polygon[j].z)
            if (pi.y > point.y) != (pj.y > point.y),
               point.x < (pj.x - pi.x) * (point.y - pi.y) / (pj.y - pi.y) + pi.x {
                inside.toggle()
            }
            j = i
        }
        return inside
    }

    @Test("Triangulates a convex square into 2 triangles")
    func convexSquare() {
        let sut = PolygonTriangulator()
        let points = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(1, 0, 1),
            SIMD3<Float>(0, 0, 1),
        ]
        #expect(sut.triangulate(points).count == 2)
    }

    @Test("Every triangle centroid stays inside a concave L-shaped polygon")
    func concaveLShapeTrianglesStayInside() {
        let sut = PolygonTriangulator()
        let triangles = sut.triangulate(lShape)
        #expect(!triangles.isEmpty)

        for triangle in triangles {
            let centroid = (lShape[triangle.a] + lShape[triangle.b] + lShape[triangle.c]) / Float(3)
            #expect(contains(SIMD2(centroid.x, centroid.z), polygon: lShape))
        }
    }

    @Test("Triangle areas sum to the polygon's area for a convex square")
    func areaSumConvexSquare() {
        let sut = PolygonTriangulator()
        let points = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(3, 0, 0),
            SIMD3<Float>(3, 0, 4),
            SIMD3<Float>(0, 0, 4),
        ]
        let triangles = sut.triangulate(points)
        #expect(abs(summedArea(triangles, points: points) - areaCalculator.area(of: points)) < 0.001)
    }

    @Test("Triangle areas sum to the polygon's area for a concave L-shape")
    func areaSumConcaveLShape() {
        let sut = PolygonTriangulator()
        let triangles = sut.triangulate(lShape)
        #expect(abs(summedArea(triangles, points: lShape) - areaCalculator.area(of: lShape)) < 0.001)
    }

    @Test("Triangle areas sum to the polygon's area for a concave star")
    func areaSumStar() {
        let sut = PolygonTriangulator()
        let points = starPoints()
        let triangles = sut.triangulate(points)
        #expect(abs(summedArea(triangles, points: points) - areaCalculator.area(of: points)) < 0.01)
    }

    @Test("Winding order doesn't change the total triangulated area")
    func windingIndependence() {
        let sut = PolygonTriangulator()
        let forward = summedArea(sut.triangulate(lShape), points: lShape)

        let reversedPoints = Array(lShape.reversed())
        let reversed = summedArea(sut.triangulate(reversedPoints), points: reversedPoints)

        #expect(abs(forward - reversed) < 0.001)
    }

    @Test("Returns empty for fewer than three points")
    func fewerThanThreePoints() {
        let sut = PolygonTriangulator()
        #expect(sut.triangulate([]).isEmpty)
        #expect(sut.triangulate([SIMD3<Float>(0, 0, 0)]).isEmpty)
        #expect(sut.triangulate([SIMD3<Float>(0, 0, 0), SIMD3<Float>(1, 0, 0)]).isEmpty)
    }

    @Test("Returns empty for collinear points")
    func collinearPoints() {
        let sut = PolygonTriangulator()
        let points = [SIMD3<Float>(0, 0, 0), SIMD3<Float>(1, 0, 0), SIMD3<Float>(2, 0, 0), SIMD3<Float>(3, 0, 0)]
        #expect(sut.triangulate(points).isEmpty)
    }

    // A double tap on the same spot, or raycast jitter landing a point on top of the previous one,
    // both produce duplicate consecutive points — so these must still triangulate completely,
    // not just terminate.

    @Test("A duplicated corner still covers the whole polygon")
    func duplicateConsecutivePoint() {
        let sut = PolygonTriangulator()
        let points = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(1, 0, 1),
            SIMD3<Float>(0, 0, 1),
        ]
        let triangles = sut.triangulate(points)

        #expect(triangles.count <= points.count - 2)
        #expect(abs(summedArea(triangles, points: points) - areaCalculator.area(of: points)) < 0.001)
    }

    @Test("A duplicated point next to a reflex vertex still covers the whole polygon")
    func duplicatePointOnConcaveShape() {
        let sut = PolygonTriangulator()
        // lShape with its reflex vertex (1,1) repeated.
        let points = [
            SIMD3<Float>(2, 0, 1),
            SIMD3<Float>(1, 0, 1),
            SIMD3<Float>(1, 0, 1),
            SIMD3<Float>(1, 0, 2),
            SIMD3<Float>(0, 0, 2),
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(2, 0, 0),
        ]
        let triangles = sut.triangulate(points)

        #expect(abs(summedArea(triangles, points: points) - 3) < 0.001)
    }

    @Test("Total triangulated area is unchanged far from the world origin")
    func farFromOrigin() {
        let sut = PolygonTriangulator()
        let baseline = summedArea(sut.triangulate(lShape), points: lShape)

        let offset = SIMD3<Float>(1000, 1000, 1000)
        let translated = lShape.map { $0 + offset }
        let translatedArea = summedArea(sut.triangulate(translated), points: translated)

        #expect(abs(translatedArea - baseline) < 0.01)
    }

    private func isCounterClockwise(_ triangulation: PolygonTriangulator.Triangulation) -> Bool {
        triangulation.triangles.allSatisfy { triangle in
            let a = triangulation.vertices[triangle.a]
            let b = triangulation.vertices[triangle.b]
            let c = triangulation.vertices[triangle.c]
            return simd_dot(simd_cross(b - a, c - a), triangulation.normal) > 0
        }
    }

    @Test("triangulation(of:) keeps a simple polygon's vertices and triangles")
    func triangulationOfSimplePolygon() throws {
        let sut = PolygonTriangulator()
        let triangulation = try #require(sut.triangulation(of: lShape))

        #expect(triangulation.vertices == lShape)
        #expect(triangulation.triangles == sut.triangulate(lShape))
        #expect(abs(simd_length(triangulation.normal) - 1) < 0.001)
        #expect(isCounterClockwise(triangulation))
    }

    @Test("A bow-tie gains its crossing point and both loops get covered")
    func triangulationOfBowTie() throws {
        let sut = PolygonTriangulator()
        let triangulation = try #require(sut.triangulation(of: bowTie))

        #expect(triangulation.vertices.count == 5)
        #expect(Array(triangulation.vertices.prefix(4)) == bowTie)
        #expect(simd_distance(triangulation.vertices[4], SIMD3<Float>(1, 0, 1)) < 0.001)
        #expect(abs(summedArea(triangulation.triangles, points: triangulation.vertices) - 2) < 0.001)
        #expect(isCounterClockwise(triangulation))
    }

    @Test("Crossed triangulation covers exactly area(of:), middle of the star included")
    func triangulationOfPentagram() throws {
        let sut = PolygonTriangulator()
        let star = pentagram(radius: 2)
        let triangulation = try #require(sut.triangulation(of: star))
        let covered = summedArea(triangulation.triangles, points: triangulation.vertices)

        #expect(abs(covered - areaCalculator.area(of: star)) < 0.01)
        #expect(isCounterClockwise(triangulation))
        let coversMiddle = triangulation.triangles.contains { triangle in
            contains(.zero, polygon: [triangle.a, triangle.b, triangle.c].map { triangulation.vertices[$0] })
        }
        #expect(coversMiddle)
    }

    @Test("A corner touching the middle of another edge splits into two covered regions")
    func triangulationOfCornerTouchingEdge() throws {
        let sut = PolygonTriangulator()
        let points = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(4, 0, 0),
            SIMD3<Float>(4, 0, 2),
            SIMD3<Float>(2, 0, 0),
            SIMD3<Float>(0, 0, 2),
        ]
        let triangulation = try #require(sut.triangulation(of: points))

        #expect(triangulation.vertices == points)
        #expect(abs(summedArea(triangulation.triangles, points: triangulation.vertices) - 4) < 0.001)
        #expect(abs(areaCalculator.area(of: points) - 4) < 0.001)
        #expect(isCounterClockwise(triangulation))
    }

    @Test("A loop inside the outline, pinned at its crossing, leaves the rest of the outline filled")
    func triangulationOfLoopPinnedInside() throws {
        let sut = PolygonTriangulator()
        let points = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(6, 0, 0),
            SIMD3<Float>(6, 0, 6),
            SIMD3<Float>(0, 0, 6),
            SIMD3<Float>(4, 0, 2),
            SIMD3<Float>(4, 0, 4),
        ]
        let triangulation = try #require(sut.triangulation(of: points))

        #expect(abs(summedArea(triangulation.triangles, points: triangulation.vertices) - 27) < 0.01)
        #expect(abs(areaCalculator.area(of: points) - 27) < 0.01)
        #expect(isCounterClockwise(triangulation))
    }

    @Test("triangulation(of:) returns nil for too few or collinear points")
    func triangulationOfDegenerateInput() {
        let sut = PolygonTriangulator()
        #expect(sut.triangulation(of: [SIMD3<Float>(0, 0, 0), SIMD3<Float>(1, 0, 0)]) == nil)
        #expect(sut.triangulation(of: [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(2, 0, 0),
        ]) == nil)
    }
}
