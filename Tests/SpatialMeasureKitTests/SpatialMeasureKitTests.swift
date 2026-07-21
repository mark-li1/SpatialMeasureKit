import Testing
import simd
@testable import SpatialMeasureKit

@Suite("DistanceCalculator")
struct DistanceCalculatorTests {
    @Test func threeFourFiveTriangle() {
        let sut = DistanceCalculator()
        let a = SIMD3<Float>(0, 0, 0)
        let b = SIMD3<Float>(3, 4, 0)

        #expect(sut.compute(from: a, to: b) == 5)
    }

    @Test func zeroDistance() {
        let sut = DistanceCalculator()
        let a = SIMD3<Float>(0, 0, 0)

        #expect(sut.compute(from: a, to: a) == 0)
    }

    @Test func negativeCoordinates() {
        let sut = DistanceCalculator()
        let a = SIMD3<Float>(0, 0, 0)
        let b = SIMD3<Float>(-3, -4, 0)

        #expect(sut.compute(from: a, to: b) == 5)
    }

    @Test func genericIrrationalDistance() {
        let sut = DistanceCalculator()
        let a = SIMD3<Float>(0, 0, 0)
        let b = SIMD3<Float>(1, 1, 1)

        let result = sut.compute(from: a, to: b)
        #expect(abs(result - 1.7320508) < 0.0001)
    }
}

@Suite("AngleCalculator")
struct AngleCalculatorTests {
    @Test func rightAngle() throws {
        let sut = AngleCalculator()
        let a = SIMD3<Float>(0, 0, 0)
        let vertex = SIMD3<Float>(3, 0, 0)
        let c = SIMD3<Float>(3, 4, 0)

        let result = try #require(sut.computeAngle(from: a, vertex: vertex, to: c))
        #expect(abs(result - 90) < 0.001)
    }

    @Test func straightLine() throws {
        let sut = AngleCalculator()
        let a = SIMD3<Float>(0, 0, 0)
        let vertex = SIMD3<Float>(3, 0, 0)
        let c = SIMD3<Float>(10, 0, 0)

        let result = try #require(sut.computeAngle(from: a, vertex: vertex, to: c))
        #expect(abs(result - 180) < 0.001)
    }

    @Test func zeroAngle() throws {
        let sut = AngleCalculator()
        let a = SIMD3<Float>(0, 0, 0)
        let vertex = SIMD3<Float>(3, 0, 0)
        let c = SIMD3<Float>(-1, 0, 0)

        let result = try #require(sut.computeAngle(from: a, vertex: vertex, to: c))
        #expect(abs(result - 0) < 0.001)
    }
    
    @Test func acuteAngle() throws {
        let sut = AngleCalculator()
        let a = SIMD3<Float>(0, 0, 0)
        let vertex = SIMD3<Float>(3, 0, 0)
        let c = SIMD3<Float>(0, 3, 0)

        let result = try #require(sut.computeAngle(from: a, vertex: vertex, to: c))
        #expect(abs(result - 45) < 0.001)
    }

    @Test func obtuseAngle() throws {
        let sut = AngleCalculator()
        let a = SIMD3<Float>(-1, 0, 0)
        let vertex = SIMD3<Float>(0, 0, 0)
        let c = SIMD3<Float>(1, 1, 0)

        let result = try #require(sut.computeAngle(from: a, vertex: vertex, to: c))
        #expect(abs(result - 135) < 0.001)
    }

    @Test func translationInvariance() throws {
        let sut = AngleCalculator()
        let a = SIMD3<Float>(10, 20, 30)
        let vertex = SIMD3<Float>(11, 20, 30)
        let c = SIMD3<Float>(11, 21, 30)

        let result = try #require(sut.computeAngle(from: a, vertex: vertex, to: c))
        #expect(abs(result - 90) < 0.001)
    }

    @Test func symmetryOfFromAndTo() throws {
        let sut = AngleCalculator()
        let a = SIMD3<Float>(0, 0, 0)
        let vertex = SIMD3<Float>(3, 0, 0)
        let c = SIMD3<Float>(0, 3, 0)

        let forward = try #require(sut.computeAngle(from: a, vertex: vertex, to: c))
        let reversed = try #require(sut.computeAngle(from: c, vertex: vertex, to: a))
        #expect(abs(forward - reversed) < 0.0001)
    }

    @Test func nilWhenFromPointCoincidesWithVertex() {
        let sut = AngleCalculator()
        let vertex = SIMD3<Float>(0, 0, 0)
        let c = SIMD3<Float>(1, 0, 0)

        #expect(sut.computeAngle(from: vertex, vertex: vertex, to: c) == nil)
    }

    @Test func nilWhenToPointCoincidesWithVertex() {
        let sut = AngleCalculator()
        let a = SIMD3<Float>(1, 0, 0)
        let vertex = SIMD3<Float>(0, 0, 0)

        #expect(sut.computeAngle(from: a, vertex: vertex, to: vertex) == nil)
    }
}

@Suite("AreaCalculator")
struct AreaCalculatorTests {
    @Test func emptyInput() {
        let sut = AreaCalculator()
        #expect(sut.computeArea(from: []) == 0)
    }
    
    @Test func onePoint() {
        let sut = AreaCalculator()
        #expect(sut.computeArea(from: [SIMD3<Float>(1, 0, 0)]) == 0)
    }
    
    @Test func twoPoints() {
        let sut = AreaCalculator()
        #expect(abs(sut.computeArea(from: [SIMD3<Float>(1, 0, 0), SIMD3<Float>(1, 3, 0)]) - 0) < 0.001)
    }
    
    @Test func triangle() {
        let sut = AreaCalculator()
        #expect(abs(sut.computeArea(from: [SIMD3<Float>(0, 0, 0),  SIMD3<Float>(3, 0, 0), SIMD3<Float>(3, 0, 4)]) - 6) < 0.001)
    }

    @Test func square() {
        let sut = AreaCalculator()
        #expect(abs(sut.computeArea(from: [SIMD3<Float>(0, 0, 0),  SIMD3<Float>(1, 0, 0), SIMD3<Float>(1, 0, 1), SIMD3<Float>(0, 0, 1)]) - 1) < 0.001)
    }

    @Test func rectangle() {
        let sut = AreaCalculator()
        #expect(abs(sut.computeArea(from: [SIMD3<Float>(0, 0, 0),  SIMD3<Float>(3, 0, 0), SIMD3<Float>(3, 0, 4), SIMD3<Float>(0, 0, 4)]) - 12) < 0.001)
    }

    @Test func straightLine() {
        let sut = AreaCalculator()
        #expect(abs(sut.computeArea(from: [SIMD3<Float>(0, 0, 0),  SIMD3<Float>(0, 0, 3), SIMD3<Float>(0, 0, 4), SIMD3<Float>(0, 0, 5)])) < 0.001)
    }

    @Test func duplicateCornerPoints() {
        let sut = AreaCalculator()
        #expect(abs(sut.computeArea(from: [SIMD3<Float>(0, 0, 0),  SIMD3<Float>(3, 0, 0), SIMD3<Float>(3, 0, 0), SIMD3<Float>(3, 0, 4)]) - 6) < 0.001)
    }

    @Test func duplicateMidEdge() {
        let sut = AreaCalculator()
        #expect(abs(sut.computeArea(from: [SIMD3<Float>(0, 0, 0),  SIMD3<Float>(3, 0, 0), SIMD3<Float>(3, 0, 2), SIMD3<Float>(3, 0, 4)]) - 6) < 0.001)
    }

    @Test func duplicateNotFollowingPoint() {
        let sut = AreaCalculator()
        #expect(abs(sut.computeArea(from: [SIMD3<Float>(0, 0, 0),  SIMD3<Float>(4, 0, 0), SIMD3<Float>(0, 0, 0), SIMD3<Float>(4, 0, 4)]) - 0) < 0.001)
    }
}

@Suite("HeightCalculator")
struct HeightCalculatorTests {
    // If the camera is aimed exactly at a point already sitting on the vertical line
    // through bottomPoint, the ray intersects that line exactly there — so the result
    // must equal the aimed point exactly, and `t` equals the aimed height exactly.

    @Test func happyPath() throws {
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

    @Test func boundaryNearZeroHeight() throws {
        let sut = HeightCalculator()
        let bottomPoint = SIMD3<Float>(0, 0, 0)
        let cameraPosition = SIMD3<Float>(5, 0, 0)
        let aimPoint = SIMD3<Float>(0, 0.01, 0)
        let cameraForward = simd_normalize(aimPoint - cameraPosition)

        let result = try #require(sut.computeTopPoint(bottomPoint: bottomPoint, cameraPosition: cameraPosition, cameraForward: cameraForward))
        #expect(abs(result.y - 0.01) < 0.001)
    }

    @Test func boundaryNearParallelStillValid() throws {
        let sut = HeightCalculator()
        let bottomPoint = SIMD3<Float>(0, 0, 0)
        let cameraPosition = SIMD3<Float>(1, 0, 0)
        let aimPoint = SIMD3<Float>(0, 20, 0)
        let cameraForward = simd_normalize(aimPoint - cameraPosition)

        let result = try #require(sut.computeTopPoint(bottomPoint: bottomPoint, cameraPosition: cameraPosition, cameraForward: cameraForward))
        #expect(abs(result.y - 20) < 0.01)
    }

    @Test func nilWhenLookingStraightUp() {
        let sut = HeightCalculator()
        let bottomPoint = SIMD3<Float>(0, 0, 0)
        let cameraPosition = SIMD3<Float>(5, 0, 0)
        let cameraForward = SIMD3<Float>(0, 1, 0)

        #expect(sut.computeTopPoint(bottomPoint: bottomPoint, cameraPosition: cameraPosition, cameraForward: cameraForward) == nil)
    }

    @Test func nilWhenAimingBelowBase() {
        let sut = HeightCalculator()
        let bottomPoint = SIMD3<Float>(0, 0, 0)
        let cameraPosition = SIMD3<Float>(5, 0, 0)
        let aimPoint = SIMD3<Float>(0, -5, 0)
        let cameraForward = simd_normalize(aimPoint - cameraPosition)

        #expect(sut.computeTopPoint(bottomPoint: bottomPoint, cameraPosition: cameraPosition, cameraForward: cameraForward) == nil)
    }
}
