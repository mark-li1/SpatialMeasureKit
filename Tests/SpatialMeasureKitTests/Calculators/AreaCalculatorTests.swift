import Testing
import simd
import Foundation
@testable import SpatialMeasureKit

@Suite("AreaCalculator")
struct AreaCalculatorTests {
    @Test("Computes 0 for empty input")
    func emptyInput() {
        let sut = AreaCalculator()
        #expect(sut.area(of: []) == 0)
    }

    @Test("Computes 0 for a single point")
    func onePoint() {
        let sut = AreaCalculator()
        #expect(sut.area(of: [SIMD3<Float>(1, 0, 0)]) == 0)
    }

    @Test("Computes 0 for two points")
    func twoPoints() {
        let sut = AreaCalculator()
        #expect(abs(sut.area(of: [SIMD3<Float>(1, 0, 0), SIMD3<Float>(1, 3, 0)]) - 0) < 0.001)
    }

    @Test("Computes 6 for a 3-4 right triangle")
    func triangle() {
        let sut = AreaCalculator()
        #expect(abs(sut.area(of: [SIMD3<Float>(0, 0, 0),  SIMD3<Float>(3, 0, 0), SIMD3<Float>(3, 0, 4)]) - 6) < 0.001)
    }

    @Test("Computes 1 for a unit square")
    func square() {
        let sut = AreaCalculator()
        #expect(abs(sut.area(of: [SIMD3<Float>(0, 0, 0),  SIMD3<Float>(1, 0, 0), SIMD3<Float>(1, 0, 1), SIMD3<Float>(0, 0, 1)]) - 1) < 0.001)
    }

    @Test("Computes 12 for a 3×4 rectangle")
    func rectangle() {
        let sut = AreaCalculator()
        #expect(abs(sut.area(of: [SIMD3<Float>(0, 0, 0),  SIMD3<Float>(3, 0, 0), SIMD3<Float>(3, 0, 4), SIMD3<Float>(0, 0, 4)]) - 12) < 0.001)
    }

    @Test("Computes 0 for collinear points")
    func straightLine() {
        let sut = AreaCalculator()
        #expect(abs(sut.area(of: [SIMD3<Float>(0, 0, 0),  SIMD3<Float>(0, 0, 3), SIMD3<Float>(0, 0, 4), SIMD3<Float>(0, 0, 5)])) < 0.001)
    }

    @Test("Area is unchanged when a corner point is duplicated")
    func duplicateCorner() {
        let sut = AreaCalculator()
        #expect(abs(sut.area(of: [SIMD3<Float>(0, 0, 0),  SIMD3<Float>(3, 0, 0), SIMD3<Float>(3, 0, 0), SIMD3<Float>(3, 0, 4)]) - 6) < 0.001)
    }

    @Test("Area is unchanged when an edge midpoint is duplicated")
    func duplicateMidEdge() {
        let sut = AreaCalculator()
        #expect(abs(sut.area(of: [SIMD3<Float>(0, 0, 0),  SIMD3<Float>(3, 0, 0), SIMD3<Float>(3, 0, 2), SIMD3<Float>(3, 0, 4)]) - 6) < 0.001)
    }

    @Test("Computes 0 when non-adjacent points coincide")
    func duplicateNonAdjacentPoint() {
        let sut = AreaCalculator()
        #expect(abs(sut.area(of: [SIMD3<Float>(0, 0, 0),  SIMD3<Float>(4, 0, 0), SIMD3<Float>(0, 0, 0), SIMD3<Float>(4, 0, 4)]) - 0) < 0.001)
    }

    @Test("Computes 12 for a 3×4 rectangle traced on a vertical wall")
    func wallRectangle() {
        let sut = AreaCalculator()
        // Lies in the XZ-less, vertical XY plane — a 2D shoelace on x/z alone would see this
        // polygon's shadow as a single line and return 0.
        let points = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(3, 0, 0),
            SIMD3<Float>(3, 4, 0),
            SIMD3<Float>(0, 4, 0),
        ]
        #expect(abs(sut.area(of: points) - 12) < 0.001)
    }

    @Test("Computes 1 for a unit square tilted 45 degrees")
    func tiltedSquare() {
        let sut = AreaCalculator()
        let points = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(1, 0.70710678, 0.70710678),
            SIMD3<Float>(0, 0.70710678, 0.70710678),
        ]
        #expect(abs(sut.area(of: points) - 1) < 0.001)
    }

    @Test("Area is unchanged when the polygon is rotated in space")
    func rotationInvariant() {
        let sut = AreaCalculator()
        let points = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(3, 0, 0),
            SIMD3<Float>(3, 0, 4),
            SIMD3<Float>(0, 0, 4),
        ]
        let baseline = sut.area(of: points)

        let rotation = simd_quatf(angle: 0.83, axis: simd_normalize(SIMD3<Float>(1, 2, 3)))
        let rotated = points.map { simd_act(rotation, $0) }

        #expect(abs(sut.area(of: rotated) - baseline) < 0.001)
    }

    @Test("Area is unchanged far from the world origin")
    func farFromOrigin() {
        let sut = AreaCalculator()
        let points = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(3, 0, 0),
            SIMD3<Float>(3, 0, 4),
            SIMD3<Float>(0, 0, 4),
        ]
        let baseline = sut.area(of: points)

        let offset = SIMD3<Float>(1000, 1000, 1000)
        let translated = points.map { $0 + offset }

        #expect(abs(sut.area(of: translated) - baseline) < 0.001)
    }

    @Test("Area is unchanged when winding order is reversed")
    func reversedWinding() {
        let sut = AreaCalculator()
        let points = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(3, 0, 0),
            SIMD3<Float>(3, 0, 4),
            SIMD3<Float>(0, 0, 4),
        ]
        #expect(abs(sut.area(of: points.reversed()) - sut.area(of: points)) < 0.001)
    }

    @Test("Area stays within 1% of exact for a wall traced with small raycast noise")
    func nearPlanarNoise() {
        let sut = AreaCalculator()
        // A 3×4 wall rectangle with each corner nudged up to 1cm off-plane.
        let points = [
            SIMD3<Float>(0, 0, 0.008),
            SIMD3<Float>(3, 0, -0.006),
            SIMD3<Float>(3, 4, 0.009),
            SIMD3<Float>(0, 4, -0.004),
        ]
        #expect(abs(sut.area(of: points) - 12) / 12 < 0.01)
    }

    @Test("planarityError is 0 for an exactly planar polygon")
    func planarityErrorZeroForFlat() {
        let sut = AreaCalculator()
        let points = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(3, 0, 0),
            SIMD3<Float>(3, 0, 4),
            SIMD3<Float>(0, 0, 4),
        ]
        #expect(sut.planarityError(of: points) < 0.0001)
    }

    @Test("planarityError reflects a point pulled off the shared plane")
    func planarityErrorDetectsOffPlanePoint() {
        let sut = AreaCalculator()
        let points = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(3, 0, 0),
            SIMD3<Float>(3, 0, 4),
            SIMD3<Float>(0, 1.0, 4),
        ]
        #expect(sut.planarityError(of: points) > 0.15)
    }

    @Test("normal points straight up for a floor-plane square")
    func normalForFloorSquare() throws {
        let sut = AreaCalculator()
        let points = [
            SIMD3<Float>(0, 0, 1),
            SIMD3<Float>(1, 0, 1),
            SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(0, 0, 0),
        ]
        let normal = try #require(sut.normal(of: points))
        #expect(simd_distance(normal, SIMD3<Float>(0, 1, 0)) < 0.001)
    }

    @Test("normal points outward for a vertical wall square")
    func normalForWallSquare() throws {
        let sut = AreaCalculator()
        let points = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(1, 1, 0),
            SIMD3<Float>(0, 1, 0),
        ]
        let normal = try #require(sut.normal(of: points))
        #expect(abs(normal.x) < 0.001)
        #expect(abs(normal.y) < 0.001)
        #expect(abs(abs(normal.z) - 1) < 0.001)
    }

    @Test("normal is a unit vector")
    func normalIsUnitLength() throws {
        let sut = AreaCalculator()
        let points = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(3, 0, 0),
            SIMD3<Float>(3, 0, 4),
            SIMD3<Float>(0, 0, 4),
        ]
        let normal = try #require(sut.normal(of: points))
        #expect(abs(simd_length(normal) - 1) < 0.0001)
    }

    @Test("normal is nil for fewer than three points")
    func normalNilForTooFewPoints() {
        let sut = AreaCalculator()
        #expect(sut.normal(of: [SIMD3<Float>(0, 0, 0), SIMD3<Float>(1, 0, 0)]) == nil)
    }

    @Test("normal is nil for collinear points")
    func normalNilForCollinearPoints() {
        let sut = AreaCalculator()
        let points = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(2, 0, 0),
        ]
        #expect(sut.normal(of: points) == nil)
    }

    @Test("centroid is nil for empty input")
    func centroidNilForEmpty() {
        let sut = AreaCalculator()
        #expect(sut.centroid(of: []) == nil)
    }

    @Test("centroid of a unit square is its exact center")
    func centroidSquareExactCenter() throws {
        let sut = AreaCalculator()
        let points = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(1, 0, 1),
            SIMD3<Float>(0, 0, 1),
        ]
        let centroid = try #require(sut.centroid(of: points))
        #expect(simd_distance(centroid, SIMD3<Float>(0.5, 0, 0.5)) < 0.001)
    }

    @Test("centroid of a triangle equals the plain vertex average")
    func centroidTriangleEqualsVertexAverage() throws {
        let sut = AreaCalculator()
        let points = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(3, 0, 0),
            SIMD3<Float>(3, 0, 4),
        ]
        let centroid = try #require(sut.centroid(of: points))
        let average = points.reduce(SIMD3<Float>.zero, +) / 3
        #expect(simd_distance(centroid, average) < 0.001)
    }

    @Test("centroid is unchanged by an extra collinear point on one edge, unlike a plain average")
    func centroidUnchangedByCollinearMidEdgePoint() throws {
        let sut = AreaCalculator()
        let points = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(0.5, 0, 0),
            SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(1, 0, 1),
            SIMD3<Float>(0, 0, 1),
        ]
        let centroid = try #require(sut.centroid(of: points))
        #expect(simd_distance(centroid, SIMD3<Float>(0.5, 0, 0.5)) < 0.001)

        let plainAverage = points.reduce(SIMD3<Float>.zero, +) / Float(points.count)
        #expect(simd_distance(plainAverage, SIMD3<Float>(0.5, 0, 0.5)) > 0.05)
    }

    @Test("centroid of a concave L-shape lands inside one of its triangles")
    func centroidLShapeInsideTriangle() throws {
        let sut = AreaCalculator()
        let points = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(4, 0, 0),
            SIMD3<Float>(4, 0, 2),
            SIMD3<Float>(2, 0, 2),
            SIMD3<Float>(2, 0, 4),
            SIMD3<Float>(0, 0, 4),
        ]
        let centroid = try #require(sut.centroid(of: points))

        let triangles = PolygonTriangulator().triangulate(points)
        #expect(!triangles.isEmpty)

        func cross(_ u: SIMD3<Float>, _ v: SIMD3<Float>) -> Float { u.x * v.z - u.z * v.x }
        func isInside(_ p: SIMD3<Float>, _ a: SIMD3<Float>, _ b: SIMD3<Float>, _ c: SIMD3<Float>) -> Bool {
            let d1 = cross(b - a, p - a)
            let d2 = cross(c - b, p - b)
            let d3 = cross(a - c, p - c)
            let hasNegative = (d1 < 0) || (d2 < 0) || (d3 < 0)
            let hasPositive = (d1 > 0) || (d2 > 0) || (d3 > 0)
            return !(hasNegative && hasPositive)
        }

        let insideAny = triangles.contains {
            isInside(centroid, points[$0.a], points[$0.b], points[$0.c])
        }
        #expect(insideAny)
    }

    @Test("centroid falls back to the vertex average for collinear points")
    func centroidCollinearFallsBackToAverage() throws {
        let sut = AreaCalculator()
        let points = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(2, 0, 0),
        ]
        let centroid = try #require(sut.centroid(of: points))
        #expect(simd_distance(centroid, SIMD3<Float>(1, 0, 0)) < 0.001)
    }

    @Test("centroid is translation invariant")
    func centroidTranslationInvariant() throws {
        let sut = AreaCalculator()
        let points = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(3, 0, 0),
            SIMD3<Float>(3, 0, 4),
            SIMD3<Float>(0, 0, 4),
        ]
        let baseline = try #require(sut.centroid(of: points))

        let offset = SIMD3<Float>(10, 5, -7)
        let translated = try #require(sut.centroid(of: points.map { $0 + offset }))
        #expect(simd_distance(translated, baseline + offset) < 0.001)
    }

    private let bowTie = [
        SIMD3<Float>(0, 0, 0),
        SIMD3<Float>(2, 0, 0),
        SIMD3<Float>(0, 0, 2),
        SIMD3<Float>(2, 0, 2),
    ]

    private let unevenBowTie = [
        SIMD3<Float>(0, 0, 0),
        SIMD3<Float>(3, 0, 0),
        SIMD3<Float>(0, 0, 1),
        SIMD3<Float>(1, 0, 1),
    ]

    private func pentagram(radius: Float) -> [SIMD3<Float>] {
        (0..<5).map { k in
            let angle = Float.pi / 2 + Float((2 * k) % 5) * 2 * .pi / 5
            return SIMD3<Float>(radius * cos(angle), 0, radius * sin(angle))
        }
    }

    private func starOutline(radius: Float) -> [SIMD3<Float>] {
        let innerRadius = radius * cos(2 * .pi / 5) / cos(.pi / 5)
        return (0..<10).map { i in
            let r = i.isMultiple(of: 2) ? radius : innerRadius
            let angle = Float.pi / 2 + Float(i) * .pi / 5
            return SIMD3<Float>(r * cos(angle), 0, r * sin(angle))
        }
    }

    @Test("Counts both loops of a bow-tie instead of cancelling them")
    func bowTieArea() {
        let sut = AreaCalculator()
        #expect(simd_length(newellNormal(from: bowTie)) < 0.001)
        #expect(abs(sut.area(of: bowTie) - 2) < 0.001)
    }

    @Test("Bow-tie area doesn't depend on drawing direction")
    func bowTieReversed() {
        let sut = AreaCalculator()
        #expect(abs(sut.area(of: bowTie.reversed()) - 2) < 0.001)
    }

    @Test("Adds the loops of an uneven bow-tie: 1.125 + 0.125, not their 1.0 difference")
    func unevenBowTieArea() {
        let sut = AreaCalculator()
        #expect(abs(sut.area(of: unevenBowTie) - 1.25) < 0.001)
    }

    @Test("A bow-tie on the floor has a vertical normal, not a wall's")
    func bowTieNormalIsVertical() throws {
        let sut = AreaCalculator()
        let normal = try #require(sut.normal(of: bowTie))

        #expect(abs(normal.y) > 0.999)
    }

    @Test("A bow-tie with one corner 2 cm higher is off its plane by about 1 cm, not 0.5 m")
    func bowTiePlanarityErrorWithLiftedCorner() throws {
        let sut = AreaCalculator()
        var lifted = bowTie
        lifted[3].y = 0.02

        let normal = try #require(sut.normal(of: lifted))

        #expect(abs(normal.y) > 0.999)
        #expect(sut.planarityError(of: lifted) < 0.015)
    }

    @Test("Counts the middle of a 5-point star once, like its simple 10-point outline")
    func pentagramUnion() {
        let sut = AreaCalculator()
        let crossed = sut.area(of: pentagram(radius: 2))
        let simple = sut.area(of: starOutline(radius: 2))
        #expect(abs(crossed - simple) < 0.01)
    }

    @Test("An outline traced twice counts its area once")
    func tracedTwice() {
        let sut = AreaCalculator()
        let square = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(1, 0, 1),
            SIMD3<Float>(0, 0, 1),
        ]
        #expect(abs(sut.area(of: square + square) - 1) < 0.001)
    }

    @Test("Two loops touching at one shared corner add up instead of cancelling")
    func loopsSharingACorner() {
        let sut = AreaCalculator()
        let points = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(2, 0, 0),
            SIMD3<Float>(1, 0, 1),
            SIMD3<Float>(0, 0, 2),
            SIMD3<Float>(2, 0, 2),
            SIMD3<Float>(1, 0, 1),
        ]
        #expect(abs(sut.area(of: points) - 2) < 0.001)
    }

    @Test("An outline that runs back along its first edge keeps the full area")
    func runsBackAlongFirstEdge() {
        let sut = AreaCalculator()
        let points = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(2, 0, 0),
            SIMD3<Float>(2, 0, 2),
            SIMD3<Float>(0, 0, 2),
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 0, 0),
        ]
        #expect(abs(sut.area(of: points) - 4) < 0.001)
    }

    @Test("Crossed outline area is unchanged far from the world origin")
    func crossedFarFromOrigin() {
        let sut = AreaCalculator()
        let offset = SIMD3<Float>(1000, 1000, 1000)
        #expect(abs(sut.area(of: bowTie.map { $0 + offset }) - 2) < 0.01)
    }

    @Test("Small height noise doesn't change a crossed outline's area")
    func crossedWithNoise() {
        let sut = AreaCalculator()
        let noise: [Float] = [0.004, -0.003, 0.005, -0.002]
        let noisy = zip(bowTie, noise).map { point, dy in point + SIMD3<Float>(0, dy, 0) }
        #expect(abs(sut.area(of: noisy) - 2) < 0.02)
    }

    @Test("Centroid of a crossed outline weights each loop by its area")
    func crossedCentroid() throws {
        let sut = AreaCalculator()
        let centroid = try #require(sut.centroid(of: unevenBowTie))
        #expect(simd_distance(centroid, SIMD3<Float>(1.18333, 0, 0.31667)) < 0.001)
    }

    @Test("Outlines that never touch themselves keep the simple-polygon path")
    func simpleOutlinesSkipArrangement() {
        let square = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(1, 0, 1),
            SIMD3<Float>(0, 0, 1),
        ]
        let pointMidEdge = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(2, 0, 0),
            SIMD3<Float>(2, 0, 2),
            SIMD3<Float>(0, 0, 2),
        ]
        #expect(PolygonArrangement(crossingOutline: square) == nil)
        #expect(PolygonArrangement(crossingOutline: pointMidEdge) == nil)
        #expect(PolygonArrangement(crossingOutline: starOutline(radius: 2)) == nil)
    }

    private let squareTwoByTwo = [
        SIMD3<Float>(0, 0, 0),
        SIMD3<Float>(2, 0, 0),
        SIMD3<Float>(2, 0, 2),
        SIMD3<Float>(0, 0, 2),
    ]

    private let uShape = [
        SIMD3<Float>(0, 0, 0),
        SIMD3<Float>(3, 0, 0),
        SIMD3<Float>(3, 0, 3),
        SIMD3<Float>(2, 0, 3),
        SIMD3<Float>(2, 0, 1),
        SIMD3<Float>(1, 0, 1),
        SIMD3<Float>(1, 0, 3),
        SIMD3<Float>(0, 0, 3),
    ]

    private func isInside(_ point: SIMD3<Float>, outline: [SIMD3<Float>]) -> Bool {
        windingNumber(of: SIMD2(point.x, point.z), around: outline.map { SIMD2($0.x, $0.z) }) != 0
    }

    private func isClearOfEveryLine(_ circle: InscribedCircle, outline: [SIMD3<Float>]) -> Bool {
        let flat = outline.map { SIMD2($0.x, $0.z) }
        let center = SIMD2(circle.center.x, circle.center.z)
        return flat.indices.allSatisfy { i in
            distance(from: center, toSegmentFrom: flat[i], to: flat[(i + 1) % flat.count]) >= circle.radius - 0.001
        }
    }

    @Test("A 2×2 square's largest circle sits in the middle with radius 1")
    func inscribedCircleSquare() throws {
        let sut = AreaCalculator()
        let circle = try #require(sut.largestInscribedCircle(of: squareTwoByTwo))

        #expect(simd_distance(circle.center, SIMD3<Float>(1, 0, 1)) < 0.01)
        #expect(abs(circle.radius - 1) < 0.002)
    }

    @Test("A 4×2 rectangle's largest circle has radius 1, centred between the long sides")
    func inscribedCircleRectangle() throws {
        let sut = AreaCalculator()
        let rectangle = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(4, 0, 0),
            SIMD3<Float>(4, 0, 2),
            SIMD3<Float>(0, 0, 2),
        ]
        let circle = try #require(sut.largestInscribedCircle(of: rectangle))

        #expect(abs(circle.radius - 1) < 0.002)
        #expect(abs(circle.center.z - 1) < 0.01)
        #expect(circle.center.x > 0.99 && circle.center.x < 3.01)
    }

    @Test("Among equally roomy points, a rectangle's circle is centred in the middle")
    func inscribedCircleRectanglePrefersMiddle() throws {
        let sut = AreaCalculator()
        let rectangle = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(4, 0, 0),
            SIMD3<Float>(4, 0, 2),
            SIMD3<Float>(0, 0, 2),
        ]
        let circle = try #require(sut.largestInscribedCircle(of: rectangle))

        #expect(simd_distance(circle.center, SIMD3<Float>(2, 0, 1)) < 0.01)
    }

    @Test("Moving one corner by 1 mm doesn't make the centre jump along the middle line")
    func inscribedCircleIsStable() throws {
        let sut = AreaCalculator()
        let nudged = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(4, 0, 0),
            SIMD3<Float>(4, 0, 2.001),
            SIMD3<Float>(0, 0, 2),
        ]
        let circle = try #require(sut.largestInscribedCircle(of: nudged))

        #expect(simd_distance(circle.center, SIMD3<Float>(2, 0, 1)) < 0.02)
    }

    @Test("In an L-shape the inner corner limits the circle to √2 / (1 + √2)")
    func inscribedCircleLShape() throws {
        let sut = AreaCalculator()
        let lShape = [
            SIMD3<Float>(2, 0, 1),
            SIMD3<Float>(1, 0, 1),
            SIMD3<Float>(1, 0, 2),
            SIMD3<Float>(0, 0, 2),
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(2, 0, 0),
        ]
        let expected = Float(2).squareRoot() / (1 + Float(2).squareRoot())
        let circle = try #require(sut.largestInscribedCircle(of: lShape))

        #expect(abs(circle.radius - expected) < 0.003)
        #expect(simd_distance(circle.center, SIMD3<Float>(expected, 0, expected)) < 0.01)
    }

    @Test("A U-shape whose centroid falls outside it still gets a centre inside")
    func inscribedCircleUShape() throws {
        let sut = AreaCalculator()
        let centroid = try #require(sut.centroid(of: uShape))
        let circle = try #require(sut.largestInscribedCircle(of: uShape))

        #expect(!isInside(centroid, outline: uShape))
        #expect(isInside(circle.center, outline: uShape))
        #expect(isClearOfEveryLine(circle, outline: uShape))
        #expect(abs(circle.radius - Float(2).squareRoot() / (1 + Float(2).squareRoot())) < 0.003)
    }

    @Test("Drawing direction doesn't change the largest circle")
    func inscribedCircleReversed() throws {
        let sut = AreaCalculator()
        let forward = try #require(sut.largestInscribedCircle(of: uShape))
        let reversed = try #require(sut.largestInscribedCircle(of: uShape.reversed()))

        #expect(abs(forward.radius - reversed.radius) < 0.002)
    }

    @Test("A bow-tie's largest circle sits inside one loop, not on the crossing")
    func inscribedCircleBowTie() throws {
        let sut = AreaCalculator()
        let circle = try #require(sut.largestInscribedCircle(of: bowTie))

        #expect(abs(circle.radius - 1 / (1 + Float(2).squareRoot())) < 0.003)
        #expect(simd_distance(circle.center, SIMD3<Float>(1, 0, 1)) > 0.3)
        #expect(isClearOfEveryLine(circle, outline: bowTie))
    }

    @Test("An uneven bow-tie's largest circle goes into the bigger loop")
    func inscribedCircleUnevenBowTie() throws {
        let sut = AreaCalculator()
        let circle = try #require(sut.largestInscribedCircle(of: unevenBowTie))

        #expect(circle.center.z < 0.75)
        #expect(abs(circle.radius - 0.3498) < 0.003)
    }

    @Test("A 5-point star's largest circle fills its inner pentagon, clear of every line")
    func inscribedCirclePentagram() throws {
        let sut = AreaCalculator()
        let star = pentagram(radius: 2)
        let circle = try #require(sut.largestInscribedCircle(of: star))

        #expect(simd_distance(circle.center, .zero) < 0.01)
        #expect(abs(circle.radius - 2 * 0.381966 * 0.809017) < 0.003)
        #expect(isClearOfEveryLine(circle, outline: star))
    }

    @Test("A circle measured on a vertical wall comes back on the wall")
    func inscribedCircleOnWall() throws {
        let sut = AreaCalculator()
        let wall = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(2, 0, 0),
            SIMD3<Float>(2, 2, 0),
            SIMD3<Float>(0, 2, 0),
        ]
        let circle = try #require(sut.largestInscribedCircle(of: wall))

        #expect(simd_distance(circle.center, SIMD3<Float>(1, 1, 0)) < 0.01)
        #expect(abs(circle.radius - 1) < 0.002)
    }

    @Test("Largest circle is unchanged far from the world origin")
    func inscribedCircleFarFromOrigin() throws {
        let sut = AreaCalculator()
        let offset = SIMD3<Float>(1000, 1000, 1000)
        let circle = try #require(sut.largestInscribedCircle(of: squareTwoByTwo.map { $0 + offset }))

        #expect(simd_distance(circle.center, SIMD3<Float>(1, 0, 1) + offset) < 0.01)
        #expect(abs(circle.radius - 1) < 0.01)
    }

    @Test("A coarser precision still lands within that precision")
    func inscribedCircleCoarsePrecision() throws {
        let sut = AreaCalculator()
        let circle = try #require(sut.largestInscribedCircle(of: squareTwoByTwo, precision: 0.1))

        #expect(abs(circle.radius - 1) <= 0.1)
    }

    @Test("largestInscribedCircle returns nil for too few or collinear points")
    func inscribedCircleDegenerate() {
        let sut = AreaCalculator()
        #expect(sut.largestInscribedCircle(of: [SIMD3<Float>(0, 0, 0), SIMD3<Float>(1, 0, 0)]) == nil)
        #expect(sut.largestInscribedCircle(of: [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(2, 0, 0),
        ]) == nil)
    }

    @Test("largestInscribedCircle returns nil for a sliver thinner than precision instead of searching it")
    func inscribedCircleSliverThinnerThanPrecision() {
        let sut = AreaCalculator()
        let sliver = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(3, 0, 0),
            SIMD3<Float>(3, 0, 0.000002),
            SIMD3<Float>(0, 0, 0.000002),
        ]

        #expect(sut.largestInscribedCircle(of: sliver, precision: 0.005) == nil)
    }

    // MARK: - inscribedCircle(of:radius:)

    private let rectangleFourByTwo = [
        SIMD3<Float>(0, 0, 0),
        SIMD3<Float>(4, 0, 0),
        SIMD3<Float>(4, 0, 2),
        SIMD3<Float>(0, 0, 2),
    ]

    private let lShape = [
        SIMD3<Float>(0, 0, 0),
        SIMD3<Float>(2, 0, 0),
        SIMD3<Float>(2, 0, 1),
        SIMD3<Float>(1, 0, 1),
        SIMD3<Float>(1, 0, 2),
        SIMD3<Float>(0, 0, 2),
    ]

    private let lShapeCentroid = SIMD3<Float>(2.5 / 3, 0, 2.5 / 3)

    @Test("A rectangle gives its exact centre for any radius it has room for", arguments: [Float(0), 0.5, 1])
    func inscribedCircleRectangleCentre(radius: Float) throws {
        let sut = AreaCalculator()
        let circle = try #require(sut.inscribedCircle(of: rectangleFourByTwo, radius: radius))

        #expect(simd_distance(circle.center, SIMD3<Float>(2, 0, 1)) < 0.01)
    }

    @Test("The returned radius is the real room at the centre, which can exceed the requested one")
    func inscribedCircleReportsRealRoom() throws {
        let sut = AreaCalculator()
        let circle = try #require(sut.inscribedCircle(of: rectangleFourByTwo, radius: 0.5))

        #expect(abs(circle.radius - 1) < 0.002)
    }

    @Test("In an L-shape a radius the centroid has room for keeps the centroid")
    func inscribedCircleLShapeKeepsCentroid() throws {
        let sut = AreaCalculator()
        let circle = try #require(sut.inscribedCircle(of: lShape, radius: 0.2))

        #expect(simd_distance(circle.center, lShapeCentroid) < 0.01)
    }

    @Test("A radius the centroid lacks moves only as far as needed, not to the largest circle")
    func inscribedCircleLShapeMovesALittle() throws {
        let sut = AreaCalculator()
        let circle = try #require(sut.inscribedCircle(of: lShape, radius: 0.3))
        let largest = try #require(sut.largestInscribedCircle(of: lShape))

        let moved = simd_distance(circle.center, lShapeCentroid)

        #expect(moved > 0.03 && moved < 0.15)
        #expect(simd_distance(largest.center, lShapeCentroid) > 0.3)
        #expect(circle.radius >= 0.3 - 0.001)
        #expect(isClearOfEveryLine(circle, outline: lShape))
    }

    @Test("Returns nil when no point has that much room")
    func inscribedCircleNoRoom() {
        let sut = AreaCalculator()

        #expect(sut.inscribedCircle(of: lShape, radius: 0.7) == nil)
    }

    @Test("In a bow-tie it finds a roomy point inside one loop, not on the crossing")
    func inscribedCircleBowTieRadius() throws {
        let sut = AreaCalculator()
        let circle = try #require(sut.inscribedCircle(of: bowTie, radius: 0.3))

        #expect(isInside(circle.center, outline: bowTie))
        #expect(circle.radius >= 0.3 - 0.001)
        #expect(isClearOfEveryLine(circle, outline: bowTie))
    }

    @Test("Honours a custom target: the roomy point nearest a corner")
    func inscribedCircleCustomTarget() throws {
        let sut = AreaCalculator()
        let circle = try #require(sut.inscribedCircle(of: rectangleFourByTwo, radius: 0.5, nearest: SIMD3(0, 0, 0)))

        #expect(simd_distance(circle.center, SIMD3<Float>(0.5, 0, 0.5)) < 0.01)
    }

    @Test("clearance is the distance to the nearest line: positive inside, negative outside")
    func clearanceInsideAndOutside() throws {
        let sut = AreaCalculator()
        let middle = try #require(sut.clearance(at: SIMD3<Float>(1, 0, 1), in: squareTwoByTwo))
        let nearEdge = try #require(sut.clearance(at: SIMD3<Float>(0.25, 0, 1), in: squareTwoByTwo))
        let outside = try #require(sut.clearance(at: SIMD3<Float>(3, 0, 1), in: squareTwoByTwo))

        #expect(abs(middle - 1) < 0.001)
        #expect(abs(nearEdge - 0.25) < 0.001)
        #expect(abs(outside + 1) < 0.001)
    }

    @Test("clearance matches the largest inscribed circle's radius at its centre")
    func clearanceAtInscribedCentre() throws {
        let sut = AreaCalculator()
        let lShape = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(4, 0, 0),
            SIMD3<Float>(4, 0, 1),
            SIMD3<Float>(1, 0, 1),
            SIMD3<Float>(1, 0, 4),
            SIMD3<Float>(0, 0, 4),
        ]
        let circle = try #require(sut.largestInscribedCircle(of: lShape))
        let clearance = try #require(sut.clearance(at: circle.center, in: lShape))

        #expect(abs(clearance - circle.radius) < 0.002)
    }

    @Test("clearance measures in the outline's plane, ignoring height above it")
    func clearanceOffPlane() throws {
        let sut = AreaCalculator()
        let raised = try #require(sut.clearance(at: SIMD3<Float>(1, 0.5, 1), in: squareTwoByTwo))

        #expect(abs(raised - 1) < 0.001)
    }

    @Test("clearance returns nil for too few or collinear points")
    func clearanceDegenerate() {
        let sut = AreaCalculator()
        #expect(sut.clearance(at: .zero, in: [SIMD3<Float>(0, 0, 0), SIMD3<Float>(1, 0, 0)]) == nil)
        #expect(sut.clearance(at: .zero, in: [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(2, 0, 0),
        ]) == nil)
    }
}
