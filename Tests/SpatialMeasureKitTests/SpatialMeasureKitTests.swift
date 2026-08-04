import Testing
import simd
@testable import SpatialMeasureKit

@Suite("DistanceCalculator")
struct DistanceCalculatorTests {
    @Test("Computes 5 for a 3-4-5 right triangle")
    func threeFourFive() {
        let sut = DistanceCalculator()
        let a = SIMD3<Float>(0, 0, 0)
        let b = SIMD3<Float>(3, 4, 0)

        #expect(sut.compute(from: a, to: b) == 5)
    }

    @Test("Computes 0 for identical points")
    func identicalPoints() {
        let sut = DistanceCalculator()
        let a = SIMD3<Float>(0, 0, 0)

        #expect(sut.compute(from: a, to: a) == 0)
    }

    @Test("Computes 5 for negative coordinates")
    func negativeCoordinates() {
        let sut = DistanceCalculator()
        let a = SIMD3<Float>(0, 0, 0)
        let b = SIMD3<Float>(-3, -4, 0)

        #expect(sut.compute(from: a, to: b) == 5)
    }

    @Test("Computes correct distance for a non-perfect-square input")
    func irrationalDistance() {
        let sut = DistanceCalculator()
        let a = SIMD3<Float>(0, 0, 0)
        let b = SIMD3<Float>(1, 1, 1)

        let result = sut.compute(from: a, to: b)
        #expect(abs(result - 1.7320508) < 0.0001)
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
