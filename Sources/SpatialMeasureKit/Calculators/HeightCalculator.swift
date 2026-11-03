import simd

/// Measures heights straight up from a point.
///
/// World up is +y, as in ARKit and RealityKit.
public struct HeightCalculator: Sendable {
    public init() {}

    /// The point straight above `bottomPoint` that the camera is aiming at.
    ///
    /// It's where the camera's line of sight passes closest to the vertical line through
    /// `bottomPoint`, usually a point on the floor. The height is the result's `y` minus
    /// `bottomPoint.y`. `cameraForward` can have any length.
    ///
    /// Returns `nil` when the camera looks almost straight up or down, or aims at or below
    /// `bottomPoint`.
    public func topPoint(
        bottomPoint: SIMD3<Float>,
        cameraPosition: SIMD3<Float>,
        cameraForward: SIMD3<Float>
    ) -> SIMD3<Float>? {
        let forwardLength = simd_length(cameraForward)
        guard forwardLength > .ulpOfOne else { return nil }
        let d1 = SIMD3<Float>(0, 1, 0)
        let d2 = cameraForward / forwardLength
        let w = cameraPosition - bottomPoint
        let b = simd_dot(d1, d2)
        let d = simd_dot(d1, w)
        let e = simd_dot(d2, w)
        let denom = 1 - b * b
        guard denom > 0.001 else { return nil }
        let t = (d - b * e) / denom
        guard t > 0 else { return nil }
        return SIMD3(bottomPoint.x, bottomPoint.y + t, bottomPoint.z)
    }
}
