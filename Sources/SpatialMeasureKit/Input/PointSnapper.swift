import simd

/// Locks the aim onto a nearby point, so a measurement can start or end exactly on it.
///
/// "Nearby" is an angle at the camera, not a distance, so the snap zone looks the same size on
/// screen whether a point is close or far away.
public struct PointSnapper: Sendable {
    public init() {}

    /// The point to lock onto for this frame, or `nil` for none.
    ///
    /// Locks the nearest point within `grabDegrees` of the aim. A locked point is kept while it
    /// stays within `grabDegrees`, even if another point gets closer. With no other point in
    /// reach, it's kept until `releaseDegrees`, so the lock doesn't flicker at the edge. Call this
    /// every frame and pass the previous result as `currentlySnapped`.
    ///
    /// - Parameters:
    ///   - candidate: the raw aim position, for example a raycast hit.
    ///   - points: the points that can be snapped to.
    ///   - cameraPosition: where the camera is. Angles are measured from here.
    ///   - currentlySnapped: the previous result. A lock whose point is no longer in `points` is
    ///     dropped.
    ///   - grabDegrees: how close the aim must come to lock a point. Must not be negative.
    ///   - releaseDegrees: how far the aim must move to let go. Must be from `grabDegrees` to 180.
    public func snap(
        candidate: SIMD3<Float>,
        to points: [SIMD3<Float>],
        cameraPosition: SIMD3<Float>,
        currentlySnapped: SIMD3<Float>?,
        grabDegrees: Float = 2,
        releaseDegrees: Float = 4
    ) -> SIMD3<Float>? {
        precondition(grabDegrees >= 0, "grabDegrees must not be negative, got \(grabDegrees)")
        precondition(
            releaseDegrees >= grabDegrees,
            "releaseDegrees (\(releaseDegrees)) must not be smaller than grabDegrees (\(grabDegrees))"
        )
        precondition(releaseDegrees <= 180, "releaseDegrees must not be above 180, got \(releaseDegrees)")
        let aimVector = candidate - cameraPosition
        let aimLength = simd_length(aimVector)
        guard aimLength > .ulpOfOne else { return nil }
        let aim = aimVector / aimLength
        let grabCosine = cos(grabDegrees * .pi / 180)
        let releaseCosine = cos(releaseDegrees * .pi / 180)

        var lockCosine: Float?
        if let currentlySnapped, points.contains(currentlySnapped) {
            let toLock = currentlySnapped - cameraPosition
            let distance = simd_length(toLock)
            if distance > .ulpOfOne {
                lockCosine = simd_dot(aim, toLock / distance)
            }
        }
        if let lockCosine, lockCosine >= grabCosine {
            return currentlySnapped
        }

        var best: (point: SIMD3<Float>, cosine: Float, distance: Float)?
        for point in points {
            let toPoint = point - cameraPosition
            let distance = simd_length(toPoint)
            guard distance > .ulpOfOne else { continue }

            let cosine = simd_dot(aim, toPoint / distance)
            guard cosine >= grabCosine else { continue }

            if let current = best {
                let better = cosine > current.cosine || (cosine == current.cosine && distance < current.distance)
                guard better else { continue }
            }
            best = (point, cosine, distance)
        }

        if let best { return best.point }

        if let lockCosine, lockCosine >= releaseCosine {
            return currentlySnapped
        }

        return nil
    }
}
