import simd

/// How far a device is tilted from level, and which way it leans.
public struct Tilt: Equatable, Sendable {
    /// The tilt in degrees, from 0 (level) to 180.
    public let degrees: Float
    /// Which way the device leans, as a unit vector in screen axes (+x right, +y up).
    /// `nil` when the device is exactly level.
    public let direction: SIMD2<Float>?

    public init(degrees: Float, direction: SIMD2<Float>?) {
        self.degrees = degrees
        self.direction = direction
    }
}

/// How far an upright device is rotated from plumb.
public struct Roll: Equatable, Sendable {
    /// The roll in degrees, from -45 to 45, measured from whichever edge of the device is closest
    /// to vertical. This is the number to show.
    public let degrees: Float
    /// Where up points on the screen, as a unit vector (+x right, +y up).
    ///
    /// Unlike `degrees`, it ignores `relativeTo:` and never jumps, so use it to rotate an
    /// indicator. To smooth it, blend vectors, not angles: an angle jumps from 180° to -180°.
    public let direction: SIMD2<Float>

    public init(degrees: Float, direction: SIMD2<Float>) {
        self.degrees = degrees
        self.direction = direction
    }
}

/// A spirit level for a device.
///
/// Both methods take `deviceUp`: the world's up direction in the device's own axes, for example
/// Core Motion's gravity with its sign flipped. It's about `[0, 0, 1]` for a device lying face up
/// and doesn't need to be normalized.
public struct LevelCalculator: Sendable {
    public init() {}

    /// How far the device is tilted from lying flat, or from a locked `reference`.
    ///
    /// Use it for a device lying on a surface. For a device held upright, use
    /// `roll(deviceUp:relativeTo:)`. `reference` is the `deviceUp` saved when the user locked
    /// zero; `nil` measures from true level.
    ///
    /// Returns `nil` when a vector has zero length, or when `reference` points almost exactly
    /// away from the screen.
    public func tilt(deviceUp: SIMD3<Float>, relativeTo reference: SIMD3<Float>? = nil) -> Tilt? {
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

        // simd_quatf(from:to:) has no single answer for opposite vectors.
        guard simd_dot(referenceVector, screenNormal) > -0.9999 else { return nil }
        let toFlat = simd_quatf(from: referenceVector, to: screenNormal)
        let v = toFlat.act(up)

        // atan2, not acos: acos loses precision near 0°, where a level spends most of its time.
        let horizontal = hypot(v.x, v.y)
        let degrees = atan2(horizontal, v.z) * 180 / .pi
        let direction: SIMD2<Float>? = horizontal > .ulpOfOne ? SIMD2(v.x, v.y) / horizontal : nil

        return Tilt(degrees: degrees, direction: direction)
    }

    /// How far an upright device is rotated from plumb.
    ///
    /// It's measured from whichever edge of the device is closest to vertical, so a device held
    /// sideways against a door frame works too. Leaning toward or away from you doesn't count.
    /// `reference` is the roll in degrees saved when the user locked zero; only its value modulo
    /// 90° matters, and `nil` measures from true vertical.
    ///
    /// Returns `nil` when the device lies flat, where roll has no meaning.
    public func roll(deviceUp: SIMD3<Float>, relativeTo reference: Float? = nil) -> Roll? {
        let horizontal = hypot(deviceUp.x, deviceUp.y)
        guard horizontal > .ulpOfOne else { return nil }
        let direction = SIMD2(deviceUp.x, deviceUp.y) / horizontal
        let rawAngle = atan2(deviceUp.x, deviceUp.y) * 180 / .pi
        let delta = rawAngle - (reference ?? 0)
        let nearestCardinal = (delta / 90).rounded(.toNearestOrAwayFromZero) * 90
        let degrees = delta - nearestCardinal
        return Roll(degrees: degrees, direction: direction)
    }
}
