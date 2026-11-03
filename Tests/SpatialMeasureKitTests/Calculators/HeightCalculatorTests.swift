import Testing
import simd
import Foundation
@testable import SpatialMeasureKit

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

        let result = try #require(sut.topPoint(bottomPoint: bottomPoint, cameraPosition: cameraPosition, cameraForward: cameraForward))
        #expect(abs(result.x - 0) < 0.001)
        #expect(abs(result.y - 4) < 0.001)
        #expect(abs(result.z - 0) < 0.001)
    }

    @Test("A camera direction that isn't unit length gives the same top point")
    func nonUnitCameraForward() throws {
        let sut = HeightCalculator()
        let bottomPoint = SIMD3<Float>(0, 0, 0)
        let cameraPosition = SIMD3<Float>(3, 0, 0)
        let direction = simd_normalize(SIMD3<Float>(0, 4, 0) - cameraPosition)

        let doubled = try #require(sut.topPoint(bottomPoint: bottomPoint, cameraPosition: cameraPosition, cameraForward: direction * 2))
        let halved = try #require(sut.topPoint(bottomPoint: bottomPoint, cameraPosition: cameraPosition, cameraForward: direction * 0.5))

        #expect(abs(doubled.y - 4) < 0.001)
        #expect(abs(halved.y - 4) < 0.001)
    }

    @Test("Computes a small positive height near the zero boundary")
    func nearZeroHeight() throws {
        let sut = HeightCalculator()
        let bottomPoint = SIMD3<Float>(0, 0, 0)
        let cameraPosition = SIMD3<Float>(5, 0, 0)
        let aimPoint = SIMD3<Float>(0, 0.01, 0)
        let cameraForward = simd_normalize(aimPoint - cameraPosition)

        let result = try #require(sut.topPoint(bottomPoint: bottomPoint, cameraPosition: cameraPosition, cameraForward: cameraForward))
        #expect(abs(result.y - 0.01) < 0.001)
    }

    @Test("Computes correct height at a steep, near-parallel angle")
    func steepAngle() throws {
        let sut = HeightCalculator()
        let bottomPoint = SIMD3<Float>(0, 0, 0)
        let cameraPosition = SIMD3<Float>(1, 0, 0)
        let aimPoint = SIMD3<Float>(0, 20, 0)
        let cameraForward = simd_normalize(aimPoint - cameraPosition)

        let result = try #require(sut.topPoint(bottomPoint: bottomPoint, cameraPosition: cameraPosition, cameraForward: cameraForward))
        #expect(abs(result.y - 20) < 0.01)
    }

    @Test("Returns nil when looking straight up (parallel to vertical)")
    func lookingStraightUp() {
        let sut = HeightCalculator()
        let bottomPoint = SIMD3<Float>(0, 0, 0)
        let cameraPosition = SIMD3<Float>(5, 0, 0)
        let cameraForward = SIMD3<Float>(0, 1, 0)

        #expect(sut.topPoint(bottomPoint: bottomPoint, cameraPosition: cameraPosition, cameraForward: cameraForward) == nil)
    }

    @Test("Returns nil when aiming below the base point")
    func aimingBelowBase() {
        let sut = HeightCalculator()
        let bottomPoint = SIMD3<Float>(0, 0, 0)
        let cameraPosition = SIMD3<Float>(5, 0, 0)
        let aimPoint = SIMD3<Float>(0, -5, 0)
        let cameraForward = simd_normalize(aimPoint - cameraPosition)

        #expect(sut.topPoint(bottomPoint: bottomPoint, cameraPosition: cameraPosition, cameraForward: cameraForward) == nil)
    }

    @Test("Returns nil when aiming exactly at the base point")
    func aimingAtBase() {
        let sut = HeightCalculator()
        let bottomPoint = SIMD3<Float>(0, 0, 0)
        let cameraPosition = SIMD3<Float>(5, 0, 0)
        let aimPoint = SIMD3<Float>(0, 0, 0)
        let cameraForward = simd_normalize(aimPoint - cameraPosition)

        #expect(sut.topPoint(bottomPoint: bottomPoint, cameraPosition: cameraPosition, cameraForward: cameraForward) == nil)
    }

    @Test("Returns nil when cameraForward is a zero vector")
    func zeroForwardVector() {
        let sut = HeightCalculator()
        let bottomPoint = SIMD3<Float>(0, 0, 0)
        let cameraPosition = SIMD3<Float>(5, 0, 0)
        let cameraForward = simd_normalize(SIMD3<Float>(0, 0, 0))

        #expect(sut.topPoint(bottomPoint: bottomPoint, cameraPosition: cameraPosition, cameraForward: cameraForward) == nil)
    }

    @Test("Returns nil when the camera coincides with the bottom point")
    func cameraAtBottomPoint() {
        let sut = HeightCalculator()
        let bottomPoint = SIMD3<Float>(0, 0, 0)
        let cameraPosition = SIMD3<Float>(0, 0, 0)
        let aimPoint = SIMD3<Float>(0, 0, 0)
        let cameraForward = simd_normalize(aimPoint - cameraPosition)

        #expect(sut.topPoint(bottomPoint: bottomPoint, cameraPosition: cameraPosition, cameraForward: cameraForward) == nil)
    }

    @Test("Preserves bottomPoint's x/z coordinates in the result")
    func preservesXZ() throws {
        let sut = HeightCalculator()
        let bottomPoint = SIMD3<Float>(7, 2, -3)
        let cameraPosition = SIMD3<Float>(10, 2, -3)
        let aimPoint = SIMD3<Float>(7, 6, -3)
        let cameraForward = simd_normalize(aimPoint - cameraPosition)

        let result = try #require(sut.topPoint(bottomPoint: bottomPoint, cameraPosition: cameraPosition, cameraForward: cameraForward))
        #expect(result.x == bottomPoint.x)
        #expect(result.z == bottomPoint.z)
        #expect(abs(result.y - 6) < 0.001)
    }
}
