import Testing
import simd
import Foundation
@testable import SpatialMeasureKit

@Suite("DistanceCalculator")
struct DistanceCalculatorTests {
    @Test("Computes 5 for a 3-4-5 right triangle")
    func threeFourFive() {
        let sut = DistanceCalculator()
        let a = SIMD3<Float>(0, 0, 0)
        let b = SIMD3<Float>(3, 4, 0)

        #expect(sut.computeDistance(from: a, to: b) == 5)
    }

    @Test("Computes 0 for identical points")
    func identicalPoints() {
        let sut = DistanceCalculator()
        let a = SIMD3<Float>(0, 0, 0)

        #expect(sut.computeDistance(from: a, to: a) == 0)
    }

    @Test("Computes 5 for negative coordinates")
    func negativeCoordinates() {
        let sut = DistanceCalculator()
        let a = SIMD3<Float>(0, 0, 0)
        let b = SIMD3<Float>(-3, -4, 0)

        #expect(sut.computeDistance(from: a, to: b) == 5)
    }

    @Test("Computes correct distance for a non-perfect-square input")
    func irrationalDistance() {
        let sut = DistanceCalculator()
        let a = SIMD3<Float>(0, 0, 0)
        let b = SIMD3<Float>(1, 1, 1)

        let result = sut.computeDistance(from: a, to: b)
        #expect(abs(result - 1.7320508) < 0.0001)
    }

    @Test("Computes 0 for empty input")
    func lengthEmptyInput() {
        let sut = DistanceCalculator()
        #expect(sut.computeLength(from: []) == 0)
    }

    @Test("Computes 0 for a single point")
    func lengthSinglePoint() {
        let sut = DistanceCalculator()
        #expect(sut.computeLength(from: [SIMD3<Float>(1, 2, 3)]) == 0)
    }

    @Test("Two points agree exactly with computeDistance")
    func lengthTwoPointsMatchesDistance() {
        let sut = DistanceCalculator()
        let a = SIMD3<Float>(0, 0, 0)
        let b = SIMD3<Float>(3, 4, 0)

        #expect(sut.computeLength(from: [a, b]) == sut.computeDistance(from: a, to: b))
    }

    @Test("Sums consecutive segments across multiple points")
    func lengthMultiSegmentSum() {
        let sut = DistanceCalculator()
        let points = [SIMD3<Float>(0, 0, 0), SIMD3<Float>(3, 0, 0), SIMD3<Float>(3, 4, 0)]

        #expect(abs(sut.computeLength(from: points) - 7) < 0.0001)
    }

    @Test("Treats the path as open: a unit square's four corners sum to 3, not 4")
    func lengthIsOpenNotClosed() {
        let sut = DistanceCalculator()
        let points = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(1, 0, 1),
            SIMD3<Float>(0, 0, 1),
        ]

        #expect(abs(sut.computeLength(from: points) - 3) < 0.0001)
    }

    @Test("Consecutive duplicate points contribute 0 to the length")
    func lengthDuplicateConsecutivePoint() {
        let sut = DistanceCalculator()
        let points = [SIMD3<Float>(0, 0, 0), SIMD3<Float>(3, 0, 0), SIMD3<Float>(3, 0, 0), SIMD3<Float>(3, 4, 0)]

        #expect(abs(sut.computeLength(from: points) - 7) < 0.0001)
    }

    @Test("Collinear points sum to the end-to-end distance")
    func lengthCollinearPoints() {
        let sut = DistanceCalculator()
        let points = [SIMD3<Float>(0, 0, 0), SIMD3<Float>(3, 0, 0), SIMD3<Float>(4, 0, 0), SIMD3<Float>(5, 0, 0)]

        #expect(abs(sut.computeLength(from: points) - 5) < 0.0001)
    }

    @Test("Length is unchanged far from the world origin")
    func lengthFarFromOrigin() {
        let sut = DistanceCalculator()
        let points = [SIMD3<Float>(0, 0, 0), SIMD3<Float>(3, 0, 0), SIMD3<Float>(3, 4, 0)]
        let baseline = sut.computeLength(from: points)

        let offset = SIMD3<Float>(1000, 1000, 1000)
        let translated = points.map { $0 + offset }

        #expect(abs(sut.computeLength(from: translated) - baseline) < 0.001)
    }

    @Test("Length is unchanged when the point order is reversed")
    func lengthReversedOrder() {
        let sut = DistanceCalculator()
        let points = [SIMD3<Float>(0, 0, 0), SIMD3<Float>(3, 0, 0), SIMD3<Float>(3, 4, 0)]

        #expect(abs(sut.computeLength(from: points.reversed()) - sut.computeLength(from: points)) < 0.0001)
    }

    @Test("Computes 0 for empty input")
    func perimeterEmptyInput() {
        let sut = DistanceCalculator()
        #expect(sut.computePerimeter(from: []) == 0)
    }

    @Test("Computes 0 for a single point")
    func perimeterSinglePoint() {
        let sut = DistanceCalculator()
        #expect(sut.computePerimeter(from: [SIMD3<Float>(1, 2, 3)]) == 0)
    }

    @Test("Falls back to the open length for two points, not a there-and-back distance")
    func perimeterTwoPointsFallsBackToLength() {
        let sut = DistanceCalculator()
        let a = SIMD3<Float>(0, 0, 0)
        let b = SIMD3<Float>(3, 4, 0)

        #expect(sut.computePerimeter(from: [a, b]) == sut.computeDistance(from: a, to: b))
    }

    @Test("Includes the closing segment: a unit square's four corners sum to 4, not 3")
    func perimeterIncludesClosingSegment() {
        let sut = DistanceCalculator()
        let points = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(1, 0, 1),
            SIMD3<Float>(0, 0, 1),
        ]

        #expect(abs(sut.computePerimeter(from: points) - 4) < 0.0001)
        #expect(abs(sut.computePerimeter(from: points) - sut.computeLength(from: points) - 1) < 0.0001)
    }

    @Test("Computes 12 for a 3-4-5 right triangle's perimeter")
    func perimeterTriangle() {
        let sut = DistanceCalculator()
        let points = [SIMD3<Float>(0, 0, 0), SIMD3<Float>(3, 0, 0), SIMD3<Float>(3, 4, 0)]

        #expect(abs(sut.computePerimeter(from: points) - 12) < 0.0001)
    }

    @Test("Perimeter is unchanged far from the world origin")
    func perimeterFarFromOrigin() {
        let sut = DistanceCalculator()
        let points = [SIMD3<Float>(0, 0, 0), SIMD3<Float>(3, 0, 0), SIMD3<Float>(3, 4, 0)]
        let baseline = sut.computePerimeter(from: points)

        let offset = SIMD3<Float>(1000, 1000, 1000)
        let translated = points.map { $0 + offset }

        #expect(abs(sut.computePerimeter(from: translated) - baseline) < 0.001)
    }

    @Test("Perimeter is unchanged when the point order is reversed")
    func perimeterReversedOrder() {
        let sut = DistanceCalculator()
        let points = [SIMD3<Float>(0, 0, 0), SIMD3<Float>(3, 0, 0), SIMD3<Float>(3, 4, 0)]

        #expect(abs(sut.computePerimeter(from: points.reversed()) - sut.computePerimeter(from: points)) < 0.0001)
    }
}

@Suite("AngleCalculator")
struct AngleCalculatorTests {
    @Test("Computes 90° for perpendicular rays")
    func rightAngle() throws {
        let sut = AngleCalculator()
        let a = SIMD3<Float>(0, 0, 0)
        let vertex = SIMD3<Float>(3, 0, 0)
        let c = SIMD3<Float>(3, 4, 0)

        let result = try #require(sut.computeAngle(from: a, vertex: vertex, to: c))
        #expect(abs(result - 90) < 0.001)
    }

    @Test("Computes 180° for opposite-direction rays")
    func straightLine() throws {
        let sut = AngleCalculator()
        let a = SIMD3<Float>(0, 0, 0)
        let vertex = SIMD3<Float>(3, 0, 0)
        let c = SIMD3<Float>(10, 0, 0)

        let result = try #require(sut.computeAngle(from: a, vertex: vertex, to: c))
        #expect(abs(result - 180) < 0.001)
    }

    @Test("Computes 0° for same-direction rays")
    func zeroAngle() throws {
        let sut = AngleCalculator()
        let a = SIMD3<Float>(0, 0, 0)
        let vertex = SIMD3<Float>(3, 0, 0)
        let c = SIMD3<Float>(-1, 0, 0)

        let result = try #require(sut.computeAngle(from: a, vertex: vertex, to: c))
        #expect(abs(result - 0) < 0.001)
    }

    @Test("Computes 45° for an acute angle")
    func acuteAngle() throws {
        let sut = AngleCalculator()
        let a = SIMD3<Float>(0, 0, 0)
        let vertex = SIMD3<Float>(3, 0, 0)
        let c = SIMD3<Float>(0, 3, 0)

        let result = try #require(sut.computeAngle(from: a, vertex: vertex, to: c))
        #expect(abs(result - 45) < 0.001)
    }

    @Test("Computes 135° for an obtuse angle")
    func obtuseAngle() throws {
        let sut = AngleCalculator()
        let a = SIMD3<Float>(-1, 0, 0)
        let vertex = SIMD3<Float>(0, 0, 0)
        let c = SIMD3<Float>(1, 1, 0)

        let result = try #require(sut.computeAngle(from: a, vertex: vertex, to: c))
        #expect(abs(result - 135) < 0.001)
    }

    @Test("Angle is invariant under translation")
    func translationInvariance() throws {
        let sut = AngleCalculator()
        let a = SIMD3<Float>(10, 20, 30)
        let vertex = SIMD3<Float>(11, 20, 30)
        let c = SIMD3<Float>(11, 21, 30)

        let result = try #require(sut.computeAngle(from: a, vertex: vertex, to: c))
        #expect(abs(result - 90) < 0.001)
    }

    @Test("Angle is symmetric when from/to are swapped")
    func symmetry() throws {
        let sut = AngleCalculator()
        let a = SIMD3<Float>(0, 0, 0)
        let vertex = SIMD3<Float>(3, 0, 0)
        let c = SIMD3<Float>(0, 3, 0)

        let forward = try #require(sut.computeAngle(from: a, vertex: vertex, to: c))
        let reversed = try #require(sut.computeAngle(from: c, vertex: vertex, to: a))
        #expect(abs(forward - reversed) < 0.0001)
    }

    @Test("Returns nil when the 'from' point coincides with the vertex")
    func fromCoincidesWithVertex() {
        let sut = AngleCalculator()
        let vertex = SIMD3<Float>(0, 0, 0)
        let c = SIMD3<Float>(1, 0, 0)

        #expect(sut.computeAngle(from: vertex, vertex: vertex, to: c) == nil)
    }

    @Test("Returns nil when the 'to' point coincides with the vertex")
    func toCoincidesWithVertex() {
        let sut = AngleCalculator()
        let a = SIMD3<Float>(1, 0, 0)
        let vertex = SIMD3<Float>(0, 0, 0)

        #expect(sut.computeAngle(from: a, vertex: vertex, to: vertex) == nil)
    }
}

@Suite("AreaCalculator")
struct AreaCalculatorTests {
    @Test("Computes 0 for empty input")
    func emptyInput() {
        let sut = AreaCalculator()
        #expect(sut.computeArea(from: []) == 0)
    }

    @Test("Computes 0 for a single point")
    func onePoint() {
        let sut = AreaCalculator()
        #expect(sut.computeArea(from: [SIMD3<Float>(1, 0, 0)]) == 0)
    }

    @Test("Computes 0 for two points")
    func twoPoints() {
        let sut = AreaCalculator()
        #expect(abs(sut.computeArea(from: [SIMD3<Float>(1, 0, 0), SIMD3<Float>(1, 3, 0)]) - 0) < 0.001)
    }

    @Test("Computes 6 for a 3-4 right triangle")
    func triangle() {
        let sut = AreaCalculator()
        #expect(abs(sut.computeArea(from: [SIMD3<Float>(0, 0, 0),  SIMD3<Float>(3, 0, 0), SIMD3<Float>(3, 0, 4)]) - 6) < 0.001)
    }

    @Test("Computes 1 for a unit square")
    func square() {
        let sut = AreaCalculator()
        #expect(abs(sut.computeArea(from: [SIMD3<Float>(0, 0, 0),  SIMD3<Float>(1, 0, 0), SIMD3<Float>(1, 0, 1), SIMD3<Float>(0, 0, 1)]) - 1) < 0.001)
    }

    @Test("Computes 12 for a 3×4 rectangle")
    func rectangle() {
        let sut = AreaCalculator()
        #expect(abs(sut.computeArea(from: [SIMD3<Float>(0, 0, 0),  SIMD3<Float>(3, 0, 0), SIMD3<Float>(3, 0, 4), SIMD3<Float>(0, 0, 4)]) - 12) < 0.001)
    }

    @Test("Computes 0 for collinear points")
    func straightLine() {
        let sut = AreaCalculator()
        #expect(abs(sut.computeArea(from: [SIMD3<Float>(0, 0, 0),  SIMD3<Float>(0, 0, 3), SIMD3<Float>(0, 0, 4), SIMD3<Float>(0, 0, 5)])) < 0.001)
    }

    @Test("Area is unchanged when a corner point is duplicated")
    func duplicateCorner() {
        let sut = AreaCalculator()
        #expect(abs(sut.computeArea(from: [SIMD3<Float>(0, 0, 0),  SIMD3<Float>(3, 0, 0), SIMD3<Float>(3, 0, 0), SIMD3<Float>(3, 0, 4)]) - 6) < 0.001)
    }

    @Test("Area is unchanged when an edge midpoint is duplicated")
    func duplicateMidEdge() {
        let sut = AreaCalculator()
        #expect(abs(sut.computeArea(from: [SIMD3<Float>(0, 0, 0),  SIMD3<Float>(3, 0, 0), SIMD3<Float>(3, 0, 2), SIMD3<Float>(3, 0, 4)]) - 6) < 0.001)
    }

    @Test("Computes 0 when non-adjacent points coincide")
    func duplicateNonAdjacentPoint() {
        let sut = AreaCalculator()
        #expect(abs(sut.computeArea(from: [SIMD3<Float>(0, 0, 0),  SIMD3<Float>(4, 0, 0), SIMD3<Float>(0, 0, 0), SIMD3<Float>(4, 0, 4)]) - 0) < 0.001)
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
        #expect(abs(sut.computeArea(from: points) - 12) < 0.001)
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
        #expect(abs(sut.computeArea(from: points) - 1) < 0.001)
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
        let baseline = sut.computeArea(from: points)

        let rotation = simd_quatf(angle: 0.83, axis: simd_normalize(SIMD3<Float>(1, 2, 3)))
        let rotated = points.map { simd_act(rotation, $0) }

        #expect(abs(sut.computeArea(from: rotated) - baseline) < 0.001)
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
        let baseline = sut.computeArea(from: points)

        let offset = SIMD3<Float>(1000, 1000, 1000)
        let translated = points.map { $0 + offset }

        #expect(abs(sut.computeArea(from: translated) - baseline) < 0.001)
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
        #expect(abs(sut.computeArea(from: points.reversed()) - sut.computeArea(from: points)) < 0.001)
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
        #expect(abs(sut.computeArea(from: points) - 12) / 12 < 0.01)
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
        #expect(sut.planarityError(from: points) < 0.0001)
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
        #expect(sut.planarityError(from: points) > 0.15)
    }
}

@Suite("HeightCalculator")
struct HeightCalculatorTests {
    // If the camera is aimed exactly at a point already sitting on the vertical line
    // through bottomPoint, the ray intersects that line exactly there — so the result
    // must equal the aimed point exactly, and `t` equals the aimed height exactly.

    @Test("Computes correct height when aimed at a known point")
    func aimedAtKnownPoint() throws {
        let sut = HeightCalculator()
        let bottomPoint = SIMD3<Float>(0, 0, 0)
        let cameraPosition = SIMD3<Float>(3, 0, 0)
        let aimPoint = SIMD3<Float>(0, 4, 0)
        let cameraForward = simd_normalize(aimPoint - cameraPosition)

        let result = try #require(sut.computeTopPoint(bottomPoint: bottomPoint, cameraPosition: cameraPosition, cameraForward: cameraForward))
        #expect(abs(result.x - 0) < 0.001)
        #expect(abs(result.y - 4) < 0.001)
        #expect(abs(result.z - 0) < 0.001)
    }

    @Test("Computes a small positive height near the zero boundary")
    func nearZeroHeight() throws {
        let sut = HeightCalculator()
        let bottomPoint = SIMD3<Float>(0, 0, 0)
        let cameraPosition = SIMD3<Float>(5, 0, 0)
        let aimPoint = SIMD3<Float>(0, 0.01, 0)
        let cameraForward = simd_normalize(aimPoint - cameraPosition)

        let result = try #require(sut.computeTopPoint(bottomPoint: bottomPoint, cameraPosition: cameraPosition, cameraForward: cameraForward))
        #expect(abs(result.y - 0.01) < 0.001)
    }

    @Test("Computes correct height at a steep, near-parallel angle")
    func steepAngle() throws {
        let sut = HeightCalculator()
        let bottomPoint = SIMD3<Float>(0, 0, 0)
        let cameraPosition = SIMD3<Float>(1, 0, 0)
        let aimPoint = SIMD3<Float>(0, 20, 0)
        let cameraForward = simd_normalize(aimPoint - cameraPosition)

        let result = try #require(sut.computeTopPoint(bottomPoint: bottomPoint, cameraPosition: cameraPosition, cameraForward: cameraForward))
        #expect(abs(result.y - 20) < 0.01)
    }

    @Test("Returns nil when looking straight up (parallel to vertical)")
    func lookingStraightUp() {
        let sut = HeightCalculator()
        let bottomPoint = SIMD3<Float>(0, 0, 0)
        let cameraPosition = SIMD3<Float>(5, 0, 0)
        let cameraForward = SIMD3<Float>(0, 1, 0)

        #expect(sut.computeTopPoint(bottomPoint: bottomPoint, cameraPosition: cameraPosition, cameraForward: cameraForward) == nil)
    }

    @Test("Returns nil when aiming below the base point")
    func aimingBelowBase() {
        let sut = HeightCalculator()
        let bottomPoint = SIMD3<Float>(0, 0, 0)
        let cameraPosition = SIMD3<Float>(5, 0, 0)
        let aimPoint = SIMD3<Float>(0, -5, 0)
        let cameraForward = simd_normalize(aimPoint - cameraPosition)

        #expect(sut.computeTopPoint(bottomPoint: bottomPoint, cameraPosition: cameraPosition, cameraForward: cameraForward) == nil)
    }

    @Test("Returns nil when aiming exactly at the base point")
    func aimingAtBase() {
        let sut = HeightCalculator()
        let bottomPoint = SIMD3<Float>(0, 0, 0)
        let cameraPosition = SIMD3<Float>(5, 0, 0)
        let aimPoint = SIMD3<Float>(0, 0, 0)
        let cameraForward = simd_normalize(aimPoint - cameraPosition)

        #expect(sut.computeTopPoint(bottomPoint: bottomPoint, cameraPosition: cameraPosition, cameraForward: cameraForward) == nil)
    }

    @Test("Returns nil when cameraForward is a zero vector")
    func zeroForwardVector() {
        let sut = HeightCalculator()
        let bottomPoint = SIMD3<Float>(0, 0, 0)
        let cameraPosition = SIMD3<Float>(5, 0, 0)
        let cameraForward = simd_normalize(SIMD3<Float>(0, 0, 0))

        #expect(sut.computeTopPoint(bottomPoint: bottomPoint, cameraPosition: cameraPosition, cameraForward: cameraForward) == nil)
    }

    @Test("Returns nil when the camera coincides with the bottom point")
    func cameraAtBottomPoint() {
        let sut = HeightCalculator()
        let bottomPoint = SIMD3<Float>(0, 0, 0)
        let cameraPosition = SIMD3<Float>(0, 0, 0)
        let aimPoint = SIMD3<Float>(0, 0, 0)
        let cameraForward = simd_normalize(aimPoint - cameraPosition)

        #expect(sut.computeTopPoint(bottomPoint: bottomPoint, cameraPosition: cameraPosition, cameraForward: cameraForward) == nil)
    }

    @Test("Preserves bottomPoint's x/z coordinates in the result")
    func preservesXZ() throws {
        let sut = HeightCalculator()
        let bottomPoint = SIMD3<Float>(7, 2, -3)
        let cameraPosition = SIMD3<Float>(10, 2, -3)
        let aimPoint = SIMD3<Float>(7, 6, -3)
        let cameraForward = simd_normalize(aimPoint - cameraPosition)

        let result = try #require(sut.computeTopPoint(bottomPoint: bottomPoint, cameraPosition: cameraPosition, cameraForward: cameraForward))
        #expect(result.x == bottomPoint.x)
        #expect(result.z == bottomPoint.z)
        #expect(abs(result.y - 6) < 0.001)
    }
}

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
        #expect(abs(summedArea(triangles, points: points) - areaCalculator.computeArea(from: points)) < 0.001)
    }

    @Test("Triangle areas sum to the polygon's area for a concave L-shape")
    func areaSumConcaveLShape() {
        let sut = PolygonTriangulator()
        let triangles = sut.triangulate(lShape)
        #expect(abs(summedArea(triangles, points: lShape) - areaCalculator.computeArea(from: lShape)) < 0.001)
    }

    @Test("Triangle areas sum to the polygon's area for a concave star")
    func areaSumStar() {
        let sut = PolygonTriangulator()
        let points = starPoints()
        let triangles = sut.triangulate(points)
        #expect(abs(summedArea(triangles, points: points) - areaCalculator.computeArea(from: points)) < 0.01)
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
        #expect(abs(summedArea(triangles, points: points) - areaCalculator.computeArea(from: points)) < 0.001)
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
}

@Suite("ValueFormatter")
struct ValueFormatterTests {
    /// Pinned so the decimal separator and grouping don't shift with the host machine's region.
    private let sut = ValueFormatter(locale: Locale(identifier: "en_US"))

    @Test("Formats a whole number of meters with two fraction digits")
    func metricWholeMeters() {
        #expect(sut.formatLength(meters: 3, system: .metric) == FormattedValue(value: "3.00", unit: .meters))
    }

    @Test("Formats a fractional length in meters")
    func metricFractionalMeters() {
        #expect(sut.formatLength(meters: 3.45, system: .metric) == FormattedValue(value: "3.45", unit: .meters))
    }

    @Test("Switches to whole centimeters below one meter")
    func metricSwitchesToCentimeters() {
        #expect(sut.formatLength(meters: 0.45, system: .metric) == FormattedValue(value: "45", unit: .centimeters))
    }

    @Test("Rounds centimeters to whole numbers")
    func metricRoundsCentimeters() {
        #expect(sut.formatLength(meters: 0.994, system: .metric) == FormattedValue(value: "99", unit: .centimeters))
    }

    @Test("Exactly one meter stays in meters")
    func metricOneMeterBoundary() {
        #expect(sut.formatLength(meters: 1, system: .metric) == FormattedValue(value: "1.00", unit: .meters))
    }

    @Test("Centimeters rounding up to 100 carry into meters instead of showing '100 CM'")
    func metricCentimeterCarry() {
        #expect(sut.formatLength(meters: 0.999, system: .metric) == FormattedValue(value: "1.00", unit: .meters))
    }

    @Test("Formats zero as centimeters")
    func metricZero() {
        #expect(sut.formatLength(meters: 0, system: .metric) == FormattedValue(value: "0", unit: .centimeters))
    }

    @Test("Honors a custom fraction-digit count")
    func metricCustomFractionDigits() {
        let result = sut.formatLength(meters: 3.456, system: .metric, fractionDigits: 1)

        #expect(result == FormattedValue(value: "3.5", unit: .meters))
    }

    @Test("Uses the locale's decimal separator")
    func metricLocalizedSeparator() {
        let german = ValueFormatter(locale: Locale(identifier: "de_DE"))

        #expect(german.formatLength(meters: 3.45, system: .metric) == FormattedValue(value: "3,45", unit: .meters))
    }

    @Test("Returns nil for a negative length")
    func rejectsNegative() {
        #expect(sut.formatLength(meters: -1, system: .metric) == nil)
    }

    @Test("Returns nil for NaN")
    func rejectsNaN() {
        #expect(sut.formatLength(meters: .nan, system: .metric) == nil)
    }

    @Test("Returns nil for infinity")
    func rejectsInfinity() {
        #expect(sut.formatLength(meters: .infinity, system: .metric) == nil)
    }

    // MARK: - Imperial

    @Test("Formats feet with whole inches and a fraction")
    func imperialFeetInchesAndFraction() {
        #expect(sut.formatLength(meters: 3.45, system: .imperial)
                == FormattedValue(value: "11' 3⅞\"", unit: .feetAndInches))
    }

    @Test("Omits a zero inch component: 10 feet reads '10\\'', not \"10' 0\\\"\"")
    func imperialExactFeetOmitsInches() {
        #expect(sut.formatLength(meters: 3.048, system: .imperial)
                == FormattedValue(value: "10'", unit: .feetAndInches))
    }

    @Test("Omits a zero foot component: below a foot reads '8¼\"', not \"0' 8¼\\\"\"")
    func imperialSubFootOmitsFeet() {
        #expect(sut.formatLength(meters: 0.21, system: .imperial)
                == FormattedValue(value: "8¼\"", unit: .feetAndInches))
    }

    @Test("Inches rounding up to twelve carry into feet instead of showing \"11' 12\\\"\"")
    func imperialInchCarry() {
        #expect(sut.formatLength(meters: 3.65759, system: .imperial)
                == FormattedValue(value: "12'", unit: .feetAndInches))
    }

    @Test("Omits zero whole inches but keeps the fraction")
    func imperialFractionWithoutWholeInches() {
        #expect(sut.formatLength(meters: 0.307975, system: .imperial)
                == FormattedValue(value: "1' ⅛\"", unit: .feetAndInches))
    }

    @Test("Formats zero as inches")
    func imperialZero() {
        #expect(sut.formatLength(meters: 0, system: .imperial)
                == FormattedValue(value: "0\"", unit: .feetAndInches))
    }

    @Test("Rounds to the nearest eighth from both sides")
    func imperialRoundsToNearestEighth() {
        // Deliberately off the midpoint: exactly 1/16" is a tie, and which way a tie falls depends
        // on Float's representation of it rather than on the rounding rule under test.
        #expect(sut.formatLength(meters: 0.0254 * 0.1, system: .imperial)   // 0.8 eighths
                == FormattedValue(value: "⅛\"", unit: .feetAndInches))
        #expect(sut.formatLength(meters: 0.0254 * 0.05, system: .imperial)  // 0.4 eighths
                == FormattedValue(value: "0\"", unit: .feetAndInches))
    }

    @Test("fractionDigits does not affect imperial output")
    func imperialIgnoresFractionDigits() {
        let coarse = sut.formatLength(meters: 3.45, system: .imperial, fractionDigits: 0)
        let fine = sut.formatLength(meters: 3.45, system: .imperial, fractionDigits: 5)

        #expect(coarse == fine)
    }

    @Test("Returns nil rather than trapping for a length too large to count in eighths")
    func imperialRejectsUncountableLength() {
        #expect(sut.formatLength(meters: 1e30, system: .imperial) == nil)
    }

    // MARK: - Area

    @Test("Formats a metric area with two fraction digits")
    func areaMetric() {
        #expect(sut.formatArea(squareMeters: 3.45, system: .metric)
                == FormattedValue(value: "3.45", unit: .squareMeters))
    }

    @Test("Converts one square meter to square feet")
    func areaOneSquareMeterInSquareFeet() {
        #expect(sut.formatArea(squareMeters: 1, system: .imperial)
                == FormattedValue(value: "10.76", unit: .squareFeet))
    }

    @Test("Converts a worked example to square feet")
    func areaWorkedExample() {
        #expect(sut.formatArea(squareMeters: 12.3, system: .imperial)
                == FormattedValue(value: "132.40", unit: .squareFeet))
    }

    @Test("Formats zero area")
    func areaZero() {
        #expect(sut.formatArea(squareMeters: 0, system: .metric)
                == FormattedValue(value: "0.00", unit: .squareMeters))
    }

    @Test("Returns nil for a negative area")
    func areaRejectsNegative() {
        #expect(sut.formatArea(squareMeters: -1, system: .metric) == nil)
    }

    @Test("Returns nil for NaN area")
    func areaRejectsNaN() {
        #expect(sut.formatArea(squareMeters: .nan, system: .metric) == nil)
    }

    @Test("Returns nil for infinite area")
    func areaRejectsInfinity() {
        #expect(sut.formatArea(squareMeters: .infinity, system: .imperial) == nil)
    }

    @Test("Unlike imperial length, fractionDigits is honored for imperial area")
    func areaImperialHonorsFractionDigits() {
        let coarse = sut.formatArea(squareMeters: 12.3, system: .imperial, fractionDigits: 0)
        let fine = sut.formatArea(squareMeters: 12.3, system: .imperial, fractionDigits: 4)

        #expect(coarse == FormattedValue(value: "132", unit: .squareFeet))
        #expect(fine == FormattedValue(value: "132.3961", unit: .squareFeet))
    }

    @Test("Uses the locale's decimal separator for area")
    func areaLocalizedSeparator() {
        let german = ValueFormatter(locale: Locale(identifier: "de_DE"))

        #expect(german.formatArea(squareMeters: 3.45, system: .metric)
                == FormattedValue(value: "3,45", unit: .squareMeters))
    }

    @Test("Imperial area is always decimal — never a feet-and-inches-style combination")
    func areaImperialHasNoLengthPunctuation() throws {
        let result = try #require(sut.formatArea(squareMeters: 12.3, system: .imperial))

        #expect(!result.value.contains("'"))
        #expect(!result.value.contains("\""))
    }
}

@Suite("AreaUnit")
struct AreaUnitTests {
    @Test("Exposes lowercase symbols, leaving casing to the caller")
    func symbols() {
        #expect(AreaUnit.squareMeters.symbol == "m²")
        #expect(AreaUnit.squareFeet.symbol == "ft²")
    }
}

@Suite("ImperialLength")
struct ImperialLengthTests {
    @Test("Splits a length into feet, whole inches, and eighths")
    func decomposes() throws {
        let sut = try #require(ImperialLength(meters: 3.45))

        #expect(sut.feet == 11)
        #expect(sut.inches == 3)
        #expect(sut.eighths == 7)
    }

    @Test("A whole foot leaves no inch or eighth remainder")
    func exactFootHasNoRemainder() throws {
        let sut = try #require(ImperialLength(meters: 0.3048))

        #expect(sut == ImperialLength(meters: 0.3048))
        #expect(sut.feet == 1)
        #expect(sut.inches == 0)
        #expect(sut.eighths == 0)
    }

    @Test("Twelve inches never survives as an inch component")
    func twelveInchesBecomesAFoot() throws {
        let sut = try #require(ImperialLength(meters: 3.65759))

        #expect(sut.feet == 12)
        #expect(sut.inches == 0)
    }

    @Test("Reduces each eighth to its lowest-terms glyph")
    func fractionGlyphs() throws {
        let expected = ["", "⅛", "¼", "⅜", "½", "⅝", "¾", "⅞"]

        for eighth in 0..<8 {
            // One whole inch plus `eighth` eighths, so the whole-inch part is never empty.
            let meters = Double(8 + eighth) * 0.0254 / 8
            let sut = try #require(ImperialLength(meters: meters))

            #expect(sut.inches == 1)
            #expect(sut.eighths == eighth)
            #expect(sut.fractionGlyph == expected[eighth])
        }
    }

    @Test("Returns nil for a negative length")
    func rejectsNegative() {
        #expect(ImperialLength(meters: -1) == nil)
    }

    @Test("Returns nil for input too large to count in eighths of an inch")
    func rejectsUncountable() {
        #expect(ImperialLength(meters: 1e30) == nil)
    }

    @Test("Returns nil for non-finite input")
    func rejectsNonFinite() {
        #expect(ImperialLength(meters: .nan) == nil)
        #expect(ImperialLength(meters: .infinity) == nil)
    }
}

@Suite("LengthUnit")
struct LengthUnitTests {
    @Test("Exposes lowercase SI symbols, leaving casing to the caller")
    func siSymbols() {
        #expect(LengthUnit.meters.symbol == "m")
        #expect(LengthUnit.centimeters.symbol == "cm")
    }

    @Test("Feet-and-inches has no separate symbol because the value carries its own")
    func selfDescribingUnitHasNoSymbol() {
        #expect(LengthUnit.feetAndInches.symbol.isEmpty)
    }
}
