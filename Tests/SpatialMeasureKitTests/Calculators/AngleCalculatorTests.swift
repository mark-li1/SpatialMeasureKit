import Testing
import simd
import Foundation
@testable import SpatialMeasureKit

@Suite("AngleCalculator")
struct AngleCalculatorTests {
    @Test("Computes 90° for perpendicular rays")
    func rightAngle() throws {
        let sut = AngleCalculator()
        let a = SIMD3<Float>(0, 0, 0)
        let vertex = SIMD3<Float>(3, 0, 0)
        let c = SIMD3<Float>(3, 4, 0)

        let result = try #require(sut.angle(from: a, vertex: vertex, to: c))
        #expect(abs(result - 90) < 0.001)
    }

    @Test("Computes 180° for opposite-direction rays")
    func straightLine() throws {
        let sut = AngleCalculator()
        let a = SIMD3<Float>(0, 0, 0)
        let vertex = SIMD3<Float>(3, 0, 0)
        let c = SIMD3<Float>(10, 0, 0)

        let result = try #require(sut.angle(from: a, vertex: vertex, to: c))
        #expect(abs(result - 180) < 0.001)
    }

    @Test("Computes 0° for same-direction rays")
    func zeroAngle() throws {
        let sut = AngleCalculator()
        let a = SIMD3<Float>(0, 0, 0)
        let vertex = SIMD3<Float>(3, 0, 0)
        let c = SIMD3<Float>(-1, 0, 0)

        let result = try #require(sut.angle(from: a, vertex: vertex, to: c))
        #expect(abs(result - 0) < 0.001)
    }

    @Test("Computes 45° for an acute angle")
    func acuteAngle() throws {
        let sut = AngleCalculator()
        let a = SIMD3<Float>(0, 0, 0)
        let vertex = SIMD3<Float>(3, 0, 0)
        let c = SIMD3<Float>(0, 3, 0)

        let result = try #require(sut.angle(from: a, vertex: vertex, to: c))
        #expect(abs(result - 45) < 0.001)
    }

    @Test("Computes 135° for an obtuse angle")
    func obtuseAngle() throws {
        let sut = AngleCalculator()
        let a = SIMD3<Float>(-1, 0, 0)
        let vertex = SIMD3<Float>(0, 0, 0)
        let c = SIMD3<Float>(1, 1, 0)

        let result = try #require(sut.angle(from: a, vertex: vertex, to: c))
        #expect(abs(result - 135) < 0.001)
    }

    @Test("Angle is invariant under translation")
    func translationInvariance() throws {
        let sut = AngleCalculator()
        let a = SIMD3<Float>(10, 20, 30)
        let vertex = SIMD3<Float>(11, 20, 30)
        let c = SIMD3<Float>(11, 21, 30)

        let result = try #require(sut.angle(from: a, vertex: vertex, to: c))
        #expect(abs(result - 90) < 0.001)
    }

    @Test("Angle is symmetric when from/to are swapped")
    func symmetry() throws {
        let sut = AngleCalculator()
        let a = SIMD3<Float>(0, 0, 0)
        let vertex = SIMD3<Float>(3, 0, 0)
        let c = SIMD3<Float>(0, 3, 0)

        let forward = try #require(sut.angle(from: a, vertex: vertex, to: c))
        let reversed = try #require(sut.angle(from: c, vertex: vertex, to: a))
        #expect(abs(forward - reversed) < 0.0001)
    }

    @Test("Returns nil when the 'from' point coincides with the vertex")
    func fromCoincidesWithVertex() {
        let sut = AngleCalculator()
        let vertex = SIMD3<Float>(0, 0, 0)
        let c = SIMD3<Float>(1, 0, 0)

        #expect(sut.angle(from: vertex, vertex: vertex, to: c) == nil)
    }

    @Test("Returns nil when the 'to' point coincides with the vertex")
    func toCoincidesWithVertex() {
        let sut = AngleCalculator()
        let a = SIMD3<Float>(1, 0, 0)
        let vertex = SIMD3<Float>(0, 0, 0)

        #expect(sut.angle(from: a, vertex: vertex, to: vertex) == nil)
    }

    @Test("Keeps a 0.01° angle instead of rounding it to 0°")
    func tinyAngleKeepsPrecision() throws {
        let sut = AngleCalculator()
        let radians: Float = 0.01 * .pi / 180

        let result = try #require(sut.angle(from: SIMD3(1, 0, 0), vertex: .zero, to: SIMD3(cos(radians), sin(radians), 0)))

        #expect(abs(result - 0.01) < 0.0005)
    }

    @Test("Keeps a 179.99° angle instead of rounding it to 180°")
    func nearlyStraightAngleKeepsPrecision() throws {
        let sut = AngleCalculator()
        let radians: Float = 0.01 * .pi / 180

        let result = try #require(sut.angle(from: SIMD3(1, 0, 0), vertex: .zero, to: SIMD3(-cos(radians), sin(radians), 0)))

        #expect(abs(result - 179.99) < 0.0005)
    }

    @Test("Returns nil for a point at infinity or NaN instead of a NaN angle")
    func rejectsNonFinitePoints() {
        let sut = AngleCalculator()
        let vertex = SIMD3<Float>(0, 0, 0)
        let c = SIMD3<Float>(0, 1, 0)

        #expect(sut.angle(from: SIMD3(.infinity, 0, 0), vertex: vertex, to: c) == nil)
        #expect(sut.angle(from: SIMD3(.nan, 0, 0), vertex: vertex, to: c) == nil)
    }
}
