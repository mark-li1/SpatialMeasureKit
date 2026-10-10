import simd

/// How far a device is from a reference orientation, and in which direction.
public struct Tilt: Equatable, Sendable {
    /// Angle from the reference direction, 0...180. Zero means level.
    public let degrees: Float
    /// Unit vector in the device's screen axes (+x right, +y up) pointing where the tilt leans;
    /// `nil` when the device is exactly level, where no direction exists.
    public let direction: SIMD2<Float>?

    // The compiler-synthesized memberwise init for a public struct is only `internal`, so
    // callers outside this package (the app, or a smoothing layer that rebuilds a Tilt from
    // blended values) need this explicit public one.
    public init(degrees: Float, direction: SIMD2<Float>?) {
        self.degrees = degrees
        self.direction = direction
    }
}

/// How far a device is rolled from level, and which way it's actually oriented right now.
public struct Roll: Equatable, Sendable {
    /// How far from level, measured from whichever of the device's 4 physical edges is closest to
    /// "up" — small in ordinary use (±45° at most). What a numeric readout should show. Respects
    /// `relativeTo:`.
    public let degrees: Float
/// The device's tilt direction in the screen's own x/y plane, as a unit vector — always
    /// absolute (ignores `relativeTo:`, unlike `degrees`). Lets a caller visually rotate an
    /// indicator so it tracks the device's true physical orientation continuously, without the
    /// snapping `degrees` applies. Smooth this as a vector (blend + renormalise, same trick as
    /// `Tilt.direction`), not `degrees` as a scalar — a raw scalar would glitch when the device
    /// rotates through the ±180° seam; blending unit vectors sidesteps that entirely.
    public let direction: SIMD2<Float>

    public init(degrees: Float, direction: SIMD2<Float>) {
        self.degrees = degrees
        self.direction = direction
    }
}

public struct LevelCalculator {
    public init() {}

    /// - deviceUp: the world's up axis expressed in the device's own axes. A device lying
    ///   face-up gives roughly `[0, 0, 1]`. Need not be normalised.
    /// - reference: the value `deviceUp` had when the user locked a zero. `nil` measures
    ///   against true horizontal.
    /// - Returns: `nil` when either vector is zero-length, or when the reference points
    ///   opposite the screen normal (the rotation between them is undefined).
    public func computeTilt(deviceUp: SIMD3<Float>, relativeTo reference: SIMD3<Float>? = nil) -> Tilt? {
        let upLength = simd_length(deviceUp)
        guard upLength > .ulpOfOne else { return nil }
        let up = deviceUp / upLength

        let screenNormal = SIMD3<Float>(0, 0, 1)
        var referenceVector = screenNormal
        if let reference {
            let referenceLength = simd_length(reference)
            guard referenceLength > .ulpOfOne else { return nil }
            referenceVector = reference / referenceLength
        }

        // simd_quatf(from:to:) is undefined for antiparallel vectors (no unique rotation exists).
        guard simd_dot(referenceVector, screenNormal) > -0.9999 else { return nil }
        let toFlat = simd_quatf(from: referenceVector, to: screenNormal)
        let v = toFlat.act(up)

        // v.z == dot(v, screenNormal), horizontal == length(cross(v, screenNormal)): the general
        // stable-angle formula atan2(length(cross(a, b)), dot(a, b)) collapses to this because
        // screenNormal is a basis axis. atan2 is used instead of acos(dot) because a level lives
        // near 0°, exactly where acos loses precision (cos(0.1°) == 0.9999985, so almost all of a
        // Float's ~7 digits are spent on the leading nines); atan2 stays accurate there.
        let horizontal = hypot(v.x, v.y)
        let degrees = atan2(horizontal, v.z) * 180 / .pi
        let direction: SIMD2<Float>? = horizontal > .ulpOfOne ? SIMD2(v.x, v.y) / horizontal : nil

        return Tilt(degrees: degrees, direction: direction)
    }

    /// Signed rotation around the screen-normal axis, relative to whichever of the device's four
    /// physical edges (top/right/bottom/left) is currently closest to true vertical — not always
    /// the screen's own top edge. Only meaningful when the device is held close to upright; see
    /// `computeTilt` for the complementary "is it flat" case.
    /// - deviceUp: same input as `computeTilt`. Only x/y are used — deliberately ignores lean
    ///   toward/away from the viewer, since that doesn't affect whether an edge is plumb.
    /// - reference: the roll (degrees) to measure relative to, e.g. the device's angle when the
    ///   user locked it. Only its value modulo 90° matters, so a previous `degrees` and a
    ///   continuous angle both work. `nil` measures against true vertical.
    /// - Returns: `nil` when x and y are both negligible — deviceUp points nearly straight through
    ///   the screen, meaning the device is flat, not upright, and roll is undefined.
    public func computeRoll(deviceUp: SIMD3<Float>, relativeTo reference: Float? = nil) -> Roll? {
        let horizontal = hypot(deviceUp.x, deviceUp.y)
        guard horizontal > .ulpOfOne else { return nil }
        let direction = SIMD2(deviceUp.x, deviceUp.y) / horizontal
        let rawAngle = atan2(deviceUp.x, deviceUp.y) * 180 / .pi
        let delta = rawAngle - (reference ?? 0)
        // Auto-detect which of the device's 4 physical edges is currently closest to "up" and
        // measure roll from THAT edge, not always the screen's own top edge — this is what makes
        // the reading correct whether the device is held with its top or one of its sides toward
        // true vertical (e.g. resting a side edge against a door frame to check it's plumb).
        let nearestCardinal = (delta / 90).rounded(.toNearestOrAwayFromZero) * 90
        let degrees = delta - nearestCardinal // naturally within [-45, 45]
        return Roll(degrees: degrees, direction: direction)
    }
}
