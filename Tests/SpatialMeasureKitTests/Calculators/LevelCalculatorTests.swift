import Testing
import simd
import Foundation
@testable import SpatialMeasureKit

@Suite("LevelCalculator")
struct LevelCalculatorTests {
    @Test("Computes 0° with no direction when lying face-up")
    func faceUpIsLevel() throws {
        let sut = LevelCalculator()
        let result = try #require(sut.tilt(deviceUp: SIMD3<Float>(0, 0, 1)))

        #expect(abs(result.degrees - 0) < 0.001)
        #expect(result.direction == nil)
    }

    @Test("Computes 90° pointing right when the device is on its right edge")
    func onItsSide() throws {
        let sut = LevelCalculator()
        let result = try #require(sut.tilt(deviceUp: SIMD3<Float>(1, 0, 0)))

        #expect(abs(result.degrees - 90) < 0.001)
        let direction = try #require(result.direction)
        #expect(abs(direction.x - 1) < 0.001)
        #expect(abs(direction.y - 0) < 0.001)
    }

    @Test("Computes 180° when upside down")
    func upsideDown() throws {
        let sut = LevelCalculator()
        let result = try #require(sut.tilt(deviceUp: SIMD3<Float>(0, 0, -1)))

        #expect(abs(result.degrees - 180) < 0.001)
    }

    @Test("A 10° tilt to the right reports 10° with a rightward direction")
    func tiltRight() throws {
        let sut = LevelCalculator()
        let radians: Float = 10 * .pi / 180
        let deviceUp = SIMD3<Float>(sin(radians), 0, cos(radians))

        let result = try #require(sut.tilt(deviceUp: deviceUp))

        #expect(abs(result.degrees - 10) < 0.001)
        let direction = try #require(result.direction)
        #expect(abs(direction.x - 1) < 0.001)
        #expect(abs(direction.y - 0) < 0.001)
    }

    @Test("A 10° tilt forward reports an upward-in-screen direction")
    func tiltForward() throws {
        let sut = LevelCalculator()
        let radians: Float = 10 * .pi / 180
        let deviceUp = SIMD3<Float>(0, sin(radians), cos(radians))

        let result = try #require(sut.tilt(deviceUp: deviceUp))

        #expect(abs(result.degrees - 10) < 0.001)
        let direction = try #require(result.direction)
        #expect(abs(direction.x - 0) < 0.001)
        #expect(abs(direction.y - 1) < 0.001)
    }

    @Test("A 0.05° tilt is not lost to precision the way acos(dot) would lose it")
    func staysPreciseNearLevel() throws {
        let sut = LevelCalculator()
        let radians: Float = 0.05 * .pi / 180
        let deviceUp = SIMD3<Float>(sin(radians), 0, cos(radians))

        let result = try #require(sut.tilt(deviceUp: deviceUp))

        #expect(abs(result.degrees - 0.05) < 0.005)
    }

    @Test("Result is unchanged when deviceUp is not normalised")
    func unnormalisedInput() throws {
        let sut = LevelCalculator()
        let normalised = SIMD3<Float>(1, 0, 0)
        let scaled = normalised * 7

        let a = try #require(sut.tilt(deviceUp: normalised))
        let b = try #require(sut.tilt(deviceUp: scaled))

        #expect(abs(a.degrees - b.degrees) < 0.0001)
    }

    @Test("Degrees are unchanged when deviceUp and reference are rotated together")
    func rotationInvariance() throws {
        let sut = LevelCalculator()
        let deviceUp = SIMD3<Float>(0.1, 0.2, 1)
        let reference = SIMD3<Float>(0, 0, 1)
        let rotation = simd_quatf(angle: 1.1, axis: simd_normalize(SIMD3<Float>(1, 1, 1)))

        let unrotated = try #require(sut.tilt(deviceUp: deviceUp, relativeTo: reference))
        let rotated = try #require(sut.tilt(deviceUp: rotation.act(deviceUp), relativeTo: rotation.act(reference)))

        #expect(abs(unrotated.degrees - rotated.degrees) < 0.001)
    }

    @Test("Reports exactly 0° when the reference equals the current pose")
    func referenceEqualsCurrent() throws {
        let sut = LevelCalculator()
        let deviceUp = SIMD3<Float>(0.3, 0.4, 0.8)

        let result = try #require(sut.tilt(deviceUp: deviceUp, relativeTo: deviceUp))

        #expect(abs(result.degrees - 0) < 0.001)
    }

    @Test("A 15° pose measured against a 10° reference in the same plane reports 5°")
    func relativeToTiltedReference() throws {
        let sut = LevelCalculator()
        func upAt(_ degrees: Float) -> SIMD3<Float> {
            let radians = degrees * .pi / 180
            return SIMD3<Float>(sin(radians), 0, cos(radians))
        }

        let result = try #require(sut.tilt(deviceUp: upAt(15), relativeTo: upAt(10)))

        #expect(abs(result.degrees - 5) < 0.001)
    }

    @Test("Returns nil for a zero-length deviceUp")
    func zeroDeviceUp() {
        let sut = LevelCalculator()
        #expect(sut.tilt(deviceUp: .zero) == nil)
    }

    @Test("Returns nil for a zero-length reference")
    func zeroReference() {
        let sut = LevelCalculator()
        #expect(sut.tilt(deviceUp: SIMD3<Float>(0, 0, 1), relativeTo: .zero) == nil)
    }

    @Test("Returns nil when the reference points opposite the screen normal")
    func antiparallelReference() {
        let sut = LevelCalculator()
        #expect(sut.tilt(deviceUp: SIMD3<Float>(0, 0, 1), relativeTo: SIMD3<Float>(0, 0, -1)) == nil)
    }

    @Test("Computes 0° when plumb (deviceUp aligned with the screen's own up edge)")
    func plumbIsZeroRoll() throws {
        let sut = LevelCalculator()
        let result = try #require(sut.roll(deviceUp: SIMD3<Float>(0, 1, 0)))
        #expect(abs(result.degrees - 0) < 0.001)
    }

    @Test("Computes a positive roll when tilted right")
    func rolledRight() throws {
        let sut = LevelCalculator()
        let radians: Float = 30 * .pi / 180
        let deviceUp = SIMD3<Float>(sin(radians), cos(radians), 0)

        let result = try #require(sut.roll(deviceUp: deviceUp))
        #expect(abs(result.degrees - 30) < 0.001)
    }

    @Test("Computes a negative roll when tilted left")
    func rolledLeft() throws {
        let sut = LevelCalculator()
        let radians: Float = -30 * .pi / 180
        let deviceUp = SIMD3<Float>(sin(radians), cos(radians), 0)

        let result = try #require(sut.roll(deviceUp: deviceUp))
        #expect(abs(result.degrees - (-30)) < 0.001)
    }

    @Test("Returns nil when the device is flat, not upright (deviceUp along the screen normal)")
    func flatDeviceHasNoRoll() {
        let sut = LevelCalculator()
        #expect(sut.roll(deviceUp: SIMD3<Float>(0, 0, 1)) == nil)
    }

    @Test("The z component never affects degrees — leaning toward the viewer doesn't change roll")
    func ignoresLean() throws {
        let sut = LevelCalculator()
        let flat = try #require(sut.roll(deviceUp: SIMD3<Float>(0.5, 0.5, 0)))
        let leaning = try #require(sut.roll(deviceUp: SIMD3<Float>(0.5, 0.5, 10)))
        #expect(abs(flat.degrees - leaning.degrees) < 0.001)
    }

    @Test("Relative mode subtracts the reference")
    func relativeRoll() throws {
        let sut = LevelCalculator()
        let radians: Float = 35 * .pi / 180
        let deviceUp = SIMD3<Float>(sin(radians), cos(radians), 0)

        let result = try #require(sut.roll(deviceUp: deviceUp, relativeTo: 30))
        #expect(abs(result.degrees - 5) < 0.001)
    }

    @Test("Wraps around the ±180° boundary instead of jumping to ~360°")
    func wrapsAroundBoundary() throws {
        let sut = LevelCalculator()
        let radians: Float = -170 * .pi / 180
        let deviceUp = SIMD3<Float>(sin(radians), cos(radians), 0)

        let result = try #require(sut.roll(deviceUp: deviceUp, relativeTo: 170))
        #expect(abs(result.degrees - 20) < 0.01)
    }

    @Test("A locked reading stays continuous past the 45° edge switch")
    func relativeRollPastCardinalBoundary() throws {
        let sut = LevelCalculator()
        let radians: Float = 50 * .pi / 180
        let deviceUp = SIMD3<Float>(sin(radians), cos(radians), 0)

        let result = try #require(sut.roll(deviceUp: deviceUp, relativeTo: 30))
        #expect(abs(result.degrees - 20) < 0.01)
    }

    @Test("A reference a quarter turn away reads the same, so a continuous angle works as one")
    func referenceModuloQuarterTurn() throws {
        let sut = LevelCalculator()
        let radians: Float = 140 * .pi / 180
        let deviceUp = SIMD3<Float>(sin(radians), cos(radians), 0)

        let snapped = try #require(sut.roll(deviceUp: deviceUp, relativeTo: 30))
        let continuous = try #require(sut.roll(deviceUp: deviceUp, relativeTo: 480))
        #expect(abs(snapped.degrees - 20) < 0.01)
        #expect(abs(continuous.degrees - 20) < 0.01)
    }

    @Test("Rolled 90° from the screen's own top edge but plumb relative to that edge reads 0°, not 90°")
    func snapsToNearestPhysicalEdge() throws {
        let sut = LevelCalculator()
        // deviceUp aligned with the screen's right edge, not its top — e.g. resting the phone's
        // side edge against a door frame and holding it plumb that way.
        let result = try #require(sut.roll(deviceUp: SIMD3<Float>(1, 0, 0)))
        #expect(abs(result.degrees - 0) < 0.001)
    }

    @Test("Just below the 45° tie reads relative to the near edge")
    func belowCardinalBoundary() throws {
        let sut = LevelCalculator()
        let radians: Float = 44 * .pi / 180
        let deviceUp = SIMD3<Float>(sin(radians), cos(radians), 0)
        let result = try #require(sut.roll(deviceUp: deviceUp))
        #expect(abs(result.degrees - 44) < 0.01)
    }

    @Test("Just above the 45° tie flips to measuring from the other edge")
    func aboveCardinalBoundary() throws {
        let sut = LevelCalculator()
        let radians: Float = 46 * .pi / 180
        let deviceUp = SIMD3<Float>(sin(radians), cos(radians), 0)
        let result = try #require(sut.roll(deviceUp: deviceUp))
        #expect(abs(result.degrees - (-44)) < 0.01)
    }

    @Test("Result is unchanged when deviceUp is not normalised")
    func rollUnnormalisedInput() throws {
        let sut = LevelCalculator()
        let normalised = SIMD3<Float>(0.6, 0.8, 0)
        let scaled = normalised * 5

        let a = try #require(sut.roll(deviceUp: normalised))
        let b = try #require(sut.roll(deviceUp: scaled))
        #expect(abs(a.degrees - b.degrees) < 0.0001)
        #expect(simd_distance(a.direction, b.direction) < 0.0001)
    }

    @Test("direction matches deviceUp's own x/y, normalised — a plain unit vector, not cardinal-snapped")
    func directionIsRawUnitVector() throws {
        let sut = LevelCalculator()
        // Deliberately not aligned with any cardinal — direction should point exactly where
        // deviceUp's x/y point, unlike degrees which snaps to the nearest edge.
        let radians: Float = 20 * .pi / 180
        let deviceUp = SIMD3<Float>(sin(radians), cos(radians), 0)

        let result = try #require(sut.roll(deviceUp: deviceUp))
        #expect(abs(result.direction.x - sin(radians)) < 0.001)
        #expect(abs(result.direction.y - cos(radians)) < 0.001)
    }

    @Test("direction is unaffected by relativeTo:, unlike degrees")
    func directionIgnoresReference() throws {
        let sut = LevelCalculator()
        let radians: Float = 35 * .pi / 180
        let deviceUp = SIMD3<Float>(sin(radians), cos(radians), 0)

        let absolute = try #require(sut.roll(deviceUp: deviceUp))
        let relative = try #require(sut.roll(deviceUp: deviceUp, relativeTo: 30))

        #expect(simd_distance(absolute.direction, relative.direction) < 0.0001)
        #expect(abs(absolute.degrees - relative.degrees) > 0.001) // degrees DID change
    }
}
