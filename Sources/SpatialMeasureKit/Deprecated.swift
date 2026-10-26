import simd

extension DistanceCalculator {
    @available(*, deprecated, renamed: "distance(from:to:)")
    public func computeDistance(from: SIMD3<Float>, to: SIMD3<Float>) -> Float {
        distance(from: from, to: to)
    }

    @available(*, deprecated, renamed: "length(of:)")
    public func computeLength(from points: [SIMD3<Float>]) -> Float {
        length(of: points)
    }

    @available(*, deprecated, renamed: "perimeter(of:)")
    public func computePerimeter(from points: [SIMD3<Float>]) -> Float {
        perimeter(of: points)
    }
}

extension AreaCalculator {
    @available(*, deprecated, renamed: "largestInscribedCircle(of:precision:)")
    public func largestInscribedCircle(from points: [SIMD3<Float>], precision: Float = 0.001) -> InscribedCircle? {
        largestInscribedCircle(of: points, precision: precision)
    }

    @available(*, deprecated, renamed: "area(of:)")
    public func computeArea(from points: [SIMD3<Float>]) -> Float {
        area(of: points)
    }

    @available(*, deprecated, renamed: "normal(of:)")
    public func normal(from points: [SIMD3<Float>]) -> SIMD3<Float>? {
        normal(of: points)
    }

    @available(*, deprecated, renamed: "centroid(of:)")
    public func centroid(from points: [SIMD3<Float>]) -> SIMD3<Float>? {
        centroid(of: points)
    }

    @available(*, deprecated, renamed: "planarityError(of:)")
    public func planarityError(from points: [SIMD3<Float>]) -> Float {
        planarityError(of: points)
    }
}

extension AngleCalculator {
    @available(*, deprecated, renamed: "angle(from:vertex:to:)")
    public func computeAngle(from a: SIMD3<Float>, vertex b: SIMD3<Float>, to c: SIMD3<Float>) -> Float? {
        angle(from: a, vertex: b, to: c)
    }
}

extension HeightCalculator {
    @available(*, deprecated, renamed: "topPoint(bottomPoint:cameraPosition:cameraForward:)")
    public func computeTopPoint(
        bottomPoint: SIMD3<Float>,
        cameraPosition: SIMD3<Float>,
        cameraForward: SIMD3<Float>
    ) -> SIMD3<Float>? {
        topPoint(bottomPoint: bottomPoint, cameraPosition: cameraPosition, cameraForward: cameraForward)
    }
}

extension LevelCalculator {
    @available(*, deprecated, renamed: "tilt(deviceUp:relativeTo:)")
    public func computeTilt(deviceUp: SIMD3<Float>, relativeTo reference: SIMD3<Float>? = nil) -> Tilt? {
        tilt(deviceUp: deviceUp, relativeTo: reference)
    }

    @available(*, deprecated, renamed: "roll(deviceUp:relativeTo:)")
    public func computeRoll(deviceUp: SIMD3<Float>, relativeTo reference: Float? = nil) -> Roll? {
        roll(deviceUp: deviceUp, relativeTo: reference)
    }
}

extension PointSnapper {
    @available(*, deprecated, message: "Pass grabDegrees and releaseDegrees: the snap zones are now in degrees, not radians.")
    public func snap(
        candidate: SIMD3<Float>,
        to points: [SIMD3<Float>],
        cameraPosition: SIMD3<Float>,
        currentlySnapped: SIMD3<Float>?,
        grabAngle: Float,
        releaseAngle: Float
    ) -> SIMD3<Float>? {
        snap(
            candidate: candidate,
            to: points,
            cameraPosition: cameraPosition,
            currentlySnapped: currentlySnapped,
            grabDegrees: grabAngle * 180 / .pi,
            releaseDegrees: releaseAngle * 180 / .pi
        )
    }
}
