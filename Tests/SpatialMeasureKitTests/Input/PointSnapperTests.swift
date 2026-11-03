import Testing
import simd
import Foundation
@testable import SpatialMeasureKit

@Suite("PointSnapper")
struct PointSnapperTests {
    // Camera at the origin, aimed along +x. Snap candidates sit at a small angle `theta`
    // off that axis in the x/y plane, at some distance, so their angular offset from the
    // aim is exactly `theta` radians.
    private let camera = SIMD3<Float>(0, 0, 0)

    private func offAxisPoint(angle theta: Float, distance: Float) -> SIMD3<Float> {
        SIMD3(distance * cos(theta), distance * sin(theta), 0)
    }

    private func offAxisPoint(degrees: Float, distance: Float = 10) -> SIMD3<Float> {
        offAxisPoint(angle: degrees * .pi / 180, distance: distance)
    }

    @Test("Snaps to a point just inside grabDegrees")
    func snapsJustInsideGrabAngle() {
        let sut = PointSnapper()
        let point = offAxisPoint(angle: 0.02, distance: 5)
        let candidate = offAxisPoint(angle: 0, distance: 8)

        let result = sut.snap(candidate: candidate, to: [point], cameraPosition: camera, currentlySnapped: nil)
        #expect(result == point)
    }

    @Test("Does not snap to a point just outside grabDegrees")
    func ignoresPointJustOutsideGrabAngle() {
        let sut = PointSnapper()
        let point = offAxisPoint(angle: 0.05, distance: 5)
        let candidate = offAxisPoint(angle: 0, distance: 8)

        let result = sut.snap(candidate: candidate, to: [point], cameraPosition: camera, currentlySnapped: nil)
        #expect(result == nil)
    }

    @Test("Returns nil for an empty candidate list")
    func emptyCandidateList() {
        let sut = PointSnapper()
        let candidate = offAxisPoint(angle: 0, distance: 8)

        let result = sut.snap(candidate: candidate, to: [], cameraPosition: camera, currentlySnapped: nil)
        #expect(result == nil)
    }

    @Test("Prefers the nearer of two equally-aligned candidates")
    func prefersNearerOnAngleTie() {
        let sut = PointSnapper()
        let near = offAxisPoint(angle: 0, distance: 2)
        let far = offAxisPoint(angle: 0, distance: 10)
        let candidate = offAxisPoint(angle: 0, distance: 8)

        let result = sut.snap(candidate: candidate, to: [far, near], cameraPosition: camera, currentlySnapped: nil)
        #expect(result == near)
    }

    @Test("Ignores a candidate point that coincides with the camera")
    func ignoresPointAtCameraPosition() {
        let sut = PointSnapper()
        let candidate = offAxisPoint(angle: 0, distance: 8)

        let result = sut.snap(candidate: candidate, to: [camera], cameraPosition: camera, currentlySnapped: nil)
        #expect(result == nil)
    }

    @Test("Never snaps to a point behind the camera")
    func ignoresPointBehindCamera() {
        let sut = PointSnapper()
        let behind = SIMD3<Float>(-5, 0, 0)
        let candidate = offAxisPoint(angle: 0, distance: 8)

        let result = sut.snap(candidate: candidate, to: [behind], cameraPosition: camera, currentlySnapped: nil)
        #expect(result == nil)
    }

    @Test("Holds the lock past grabDegrees but releases past releaseDegrees")
    func hysteresisHoldsThenReleases() {
        let sut = PointSnapper()
        let point = offAxisPoint(angle: 0, distance: 10)

        let grabbed = sut.snap(candidate: offAxisPoint(angle: 0.01, distance: 8), to: [point], cameraPosition: camera, currentlySnapped: nil)
        #expect(grabbed == point)

        let held = sut.snap(candidate: offAxisPoint(angle: 0.05, distance: 8), to: [point], cameraPosition: camera, currentlySnapped: grabbed)
        #expect(held == point)

        let released = sut.snap(candidate: offAxisPoint(angle: 0.08, distance: 8), to: [point], cameraPosition: camera, currentlySnapped: held)
        #expect(released == nil)
    }

    @Test("By default it grabs within 2° and holds a lock until 4°")
    func defaultThresholdsInDegrees() {
        let sut = PointSnapper()
        let point = offAxisPoint(degrees: 0)
        func snap(aimDegrees: Float, lock: SIMD3<Float>?) -> SIMD3<Float>? {
            sut.snap(candidate: offAxisPoint(degrees: aimDegrees, distance: 8), to: [point], cameraPosition: camera, currentlySnapped: lock)
        }

        #expect(snap(aimDegrees: 1.9, lock: nil) == point)
        #expect(snap(aimDegrees: 2.1, lock: nil) == nil)
        #expect(snap(aimDegrees: 3.9, lock: point) == point)
        #expect(snap(aimDegrees: 4.1, lock: point) == nil)
    }

    @Test("Switches to a better point when the current lock is outside grabDegrees")
    func switchesToABetterPoint() {
        let sut = PointSnapper()
        let previouslySnapped = offAxisPoint(angle: 0.05, distance: 10)
        let betterMatch = offAxisPoint(angle: 0.01, distance: 10)
        let candidate = offAxisPoint(angle: 0, distance: 8)

        let result = sut.snap(candidate: candidate, to: [previouslySnapped, betterMatch], cameraPosition: camera, currentlySnapped: previouslySnapped)
        #expect(result == betterMatch)
    }

    @Test("Keeps the current lock while it is within grabDegrees, even if another point is nearer the aim")
    func keepsLockWithinGrabAngle() {
        let sut = PointSnapper()
        let locked = offAxisPoint(degrees: 0)
        let neighbour = offAxisPoint(degrees: 1.5)
        let candidate = offAxisPoint(degrees: 1, distance: 8)

        let result = sut.snap(candidate: candidate, to: [locked, neighbour], cameraPosition: camera, currentlySnapped: locked)
        #expect(result == locked)
    }

    @Test("Moves to the neighbour once the aim takes the lock past grabDegrees")
    func movesOnWhenLockLeavesGrabAngle() {
        let sut = PointSnapper()
        let locked = offAxisPoint(degrees: 0)
        let neighbour = offAxisPoint(degrees: 3)
        let candidate = offAxisPoint(degrees: 2.5, distance: 8)

        let result = sut.snap(candidate: candidate, to: [locked, neighbour], cameraPosition: camera, currentlySnapped: locked)
        #expect(result == neighbour)
    }

    @Test("A shaking aim between two close points never flips the lock")
    func shakingAimDoesNotFlip() {
        let sut = PointSnapper()
        let first = offAxisPoint(degrees: 0)
        let second = offAxisPoint(degrees: 1.5)
        var lock: SIMD3<Float>? = first
        var switches = 0

        for index in 0..<120 {
            let shake: Float = index.isMultiple(of: 2) ? 0.3 : -0.3
            let candidate = offAxisPoint(degrees: 0.75 + shake, distance: 8)
            let result = sut.snap(candidate: candidate, to: [first, second], cameraPosition: camera, currentlySnapped: lock)
            if result != lock {
                switches += 1
            }
            lock = result
        }

        #expect(switches == 0)
        #expect(lock == first)
    }

    @Test("Drops a lock whose point is no longer in the candidate list")
    func dropsLockOnRemovedPoint() {
        let sut = PointSnapper()
        let removedPoint = offAxisPoint(angle: 0, distance: 10)
        let candidate = offAxisPoint(angle: 0, distance: 8)

        let result = sut.snap(candidate: candidate, to: [], cameraPosition: camera, currentlySnapped: removedPoint)
        #expect(result == nil)
    }

    #if compiler(>=6.2) && os(macOS)
    @Test("Stops on a negative grab angle, a release smaller than the grab, or a release above 180°")
    func invalidThresholdsStop() async {
        await #expect(processExitsWith: .failure) {
            _ = PointSnapper().snap(candidate: SIMD3(1, 0, 0), to: [], cameraPosition: .zero, currentlySnapped: nil, grabDegrees: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = PointSnapper().snap(candidate: SIMD3(1, 0, 0), to: [], cameraPosition: .zero, currentlySnapped: nil, grabDegrees: 4, releaseDegrees: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = PointSnapper().snap(candidate: SIMD3(1, 0, 0), to: [], cameraPosition: .zero, currentlySnapped: nil, releaseDegrees: 181)
        }
    }
    #endif
}
