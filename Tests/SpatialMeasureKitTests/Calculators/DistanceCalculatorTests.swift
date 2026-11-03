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

        #expect(sut.distance(from: a, to: b) == 5)
    }

    @Test("Computes 0 for identical points")
    func identicalPoints() {
        let sut = DistanceCalculator()
        let a = SIMD3<Float>(0, 0, 0)

        #expect(sut.distance(from: a, to: a) == 0)
    }

    @Test("Computes 5 for negative coordinates")
    func negativeCoordinates() {
        let sut = DistanceCalculator()
        let a = SIMD3<Float>(0, 0, 0)
        let b = SIMD3<Float>(-3, -4, 0)

        #expect(sut.distance(from: a, to: b) == 5)
    }

    @Test("Computes correct distance for a non-perfect-square input")
    func irrationalDistance() {
        let sut = DistanceCalculator()
        let a = SIMD3<Float>(0, 0, 0)
        let b = SIMD3<Float>(1, 1, 1)

        let result = sut.distance(from: a, to: b)
        #expect(abs(result - 1.7320508) < 0.0001)
    }

    @Test("Computes 0 for empty input")
    func lengthEmptyInput() {
        let sut = DistanceCalculator()
        #expect(sut.length(of: []) == 0)
    }

    @Test("Computes 0 for a single point")
    func lengthSinglePoint() {
        let sut = DistanceCalculator()
        #expect(sut.length(of: [SIMD3<Float>(1, 2, 3)]) == 0)
    }

    @Test("Two points agree exactly with distance(from:to:)")
    func lengthTwoPointsMatchesDistance() {
        let sut = DistanceCalculator()
        let a = SIMD3<Float>(0, 0, 0)
        let b = SIMD3<Float>(3, 4, 0)

        #expect(sut.length(of: [a, b]) == sut.distance(from: a, to: b))
    }

    @Test("Sums consecutive segments across multiple points")
    func lengthMultiSegmentSum() {
        let sut = DistanceCalculator()
        let points = [SIMD3<Float>(0, 0, 0), SIMD3<Float>(3, 0, 0), SIMD3<Float>(3, 4, 0)]

        #expect(abs(sut.length(of: points) - 7) < 0.0001)
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

        #expect(abs(sut.length(of: points) - 3) < 0.0001)
    }

    @Test("Consecutive duplicate points contribute 0 to the length")
    func lengthDuplicateConsecutivePoint() {
        let sut = DistanceCalculator()
        let points = [SIMD3<Float>(0, 0, 0), SIMD3<Float>(3, 0, 0), SIMD3<Float>(3, 0, 0), SIMD3<Float>(3, 4, 0)]

        #expect(abs(sut.length(of: points) - 7) < 0.0001)
    }

    @Test("Collinear points sum to the end-to-end distance")
    func lengthCollinearPoints() {
        let sut = DistanceCalculator()
        let points = [SIMD3<Float>(0, 0, 0), SIMD3<Float>(3, 0, 0), SIMD3<Float>(4, 0, 0), SIMD3<Float>(5, 0, 0)]

        #expect(abs(sut.length(of: points) - 5) < 0.0001)
    }

    @Test("Length is unchanged far from the world origin")
    func lengthFarFromOrigin() {
        let sut = DistanceCalculator()
        let points = [SIMD3<Float>(0, 0, 0), SIMD3<Float>(3, 0, 0), SIMD3<Float>(3, 4, 0)]
        let baseline = sut.length(of: points)

        let offset = SIMD3<Float>(1000, 1000, 1000)
        let translated = points.map { $0 + offset }

        #expect(abs(sut.length(of: translated) - baseline) < 0.001)
    }

    @Test("Length is unchanged when the point order is reversed")
    func lengthReversedOrder() {
        let sut = DistanceCalculator()
        let points = [SIMD3<Float>(0, 0, 0), SIMD3<Float>(3, 0, 0), SIMD3<Float>(3, 4, 0)]

        #expect(abs(sut.length(of: points.reversed()) - sut.length(of: points)) < 0.0001)
    }

    @Test("Computes 0 for empty input")
    func perimeterEmptyInput() {
        let sut = DistanceCalculator()
        #expect(sut.perimeter(of: []) == 0)
    }

    @Test("Computes 0 for a single point")
    func perimeterSinglePoint() {
        let sut = DistanceCalculator()
        #expect(sut.perimeter(of: [SIMD3<Float>(1, 2, 3)]) == 0)
    }

    @Test("Falls back to the open length for two points, not a there-and-back distance")
    func perimeterTwoPointsFallsBackToLength() {
        let sut = DistanceCalculator()
        let a = SIMD3<Float>(0, 0, 0)
        let b = SIMD3<Float>(3, 4, 0)

        #expect(sut.perimeter(of: [a, b]) == sut.distance(from: a, to: b))
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

        #expect(abs(sut.perimeter(of: points) - 4) < 0.0001)
        #expect(abs(sut.perimeter(of: points) - sut.length(of: points) - 1) < 0.0001)
    }

    @Test("Computes 12 for a 3-4-5 right triangle's perimeter")
    func perimeterTriangle() {
        let sut = DistanceCalculator()
        let points = [SIMD3<Float>(0, 0, 0), SIMD3<Float>(3, 0, 0), SIMD3<Float>(3, 4, 0)]

        #expect(abs(sut.perimeter(of: points) - 12) < 0.0001)
    }

    @Test("Perimeter is unchanged far from the world origin")
    func perimeterFarFromOrigin() {
        let sut = DistanceCalculator()
        let points = [SIMD3<Float>(0, 0, 0), SIMD3<Float>(3, 0, 0), SIMD3<Float>(3, 4, 0)]
        let baseline = sut.perimeter(of: points)

        let offset = SIMD3<Float>(1000, 1000, 1000)
        let translated = points.map { $0 + offset }

        #expect(abs(sut.perimeter(of: translated) - baseline) < 0.001)
    }

    @Test("Perimeter is unchanged when the point order is reversed")
    func perimeterReversedOrder() {
        let sut = DistanceCalculator()
        let points = [SIMD3<Float>(0, 0, 0), SIMD3<Float>(3, 0, 0), SIMD3<Float>(3, 4, 0)]

        #expect(abs(sut.perimeter(of: points.reversed()) - sut.perimeter(of: points)) < 0.0001)
    }
}
