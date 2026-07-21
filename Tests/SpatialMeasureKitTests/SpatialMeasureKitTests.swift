import Testing
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
