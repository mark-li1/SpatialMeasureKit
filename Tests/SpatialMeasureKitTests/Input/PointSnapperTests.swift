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

    @Test("Switches immediately to a better point, ignoring the current lock")
    func switchesToABetterPoint() {
        let sut = PointSnapper()
        let previouslySnapped = offAxisPoint(angle: 0.05, distance: 10)
        let betterMatch = offAxisPoint(angle: 0.01, distance: 10)
        let candidate = offAxisPoint(angle: 0, distance: 8)

        let result = sut.snap(candidate: candidate, to: [previouslySnapped, betterMatch], cameraPosition: camera, currentlySnapped: previouslySnapped)
        #expect(result == betterMatch)
    }

    @Test("Drops a lock whose point is no longer in the candidate list")
    func dropsLockOnRemovedPoint() {
        let sut = PointSnapper()
        let removedPoint = offAxisPoint(angle: 0, distance: 10)
        let candidate = offAxisPoint(angle: 0, distance: 8)

        let result = sut.snap(candidate: candidate, to: [], cameraPosition: camera, currentlySnapped: removedPoint)
        #expect(result == nil)
    }
}
