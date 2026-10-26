import simd

public struct PointSnapper: Sendable {
    public init() {}

    // Threshold is angular, not metric: how close two points look on screen depends on the
    // angle at the camera, not the distance between them in the real world.
    public func snap(
        candidate: SIMD3<Float>,
        to points: [SIMD3<Float>],
        cameraPosition: SIMD3<Float>,
        currentlySnapped: SIMD3<Float>?,
        grabDegrees: Float = 2,
        releaseDegrees: Float = 4
    ) -> SIMD3<Float>? {
        let aimVector = candidate - cameraPosition
        let aimLength = simd_length(aimVector)
        guard aimLength > .ulpOfOne else { return nil }
        let aim = aimVector / aimLength
        let grabCosine = cos(grabDegrees * .pi / 180)
        let releaseCosine = cos(releaseDegrees * .pi / 180)

        var best: (point: SIMD3<Float>, cosine: Float, distance: Float)?
        for point in points {
            let toPoint = point - cameraPosition
            let distance = simd_length(toPoint)
            guard distance > .ulpOfOne else { continue }

            // dot of two unit vectors == cos(angle between them); comparing cosines instead
            // of calling acos() avoids a trig call per candidate.
            let cosine = simd_dot(aim, toPoint / distance)
            guard cosine >= grabCosine else { continue } // checks whether this point even close enough to be a snap candidate

            if let current = best {
                let better = cosine > current.cosine || (cosine == current.cosine && distance < current.distance)
                guard better else { continue }
            }
            best = (point, cosine, distance)
        }

        if let best { return best.point }

        // Nothing newly qualifies: hold the previous lock under the wider releaseDegrees so it
        // doesn't flicker on/off right at the grabDegrees boundary. `contains` also drops a
        // lock whose measurement was undone since the last call.
        if let currentlySnapped, points.contains(currentlySnapped) {
            let toPoint = currentlySnapped - cameraPosition
            let distance = simd_length(toPoint)
            if distance > .ulpOfOne, simd_dot(aim, toPoint / distance) >= releaseCosine {
                return currentlySnapped
            }
        }

        return nil
    }
}
