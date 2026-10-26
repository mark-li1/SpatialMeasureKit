import simd

public struct HeightCalculator: Sendable {
    public init() {}
    
    public func computeTopPoint(
        bottomPoint: SIMD3<Float>,
        cameraPosition: SIMD3<Float>,
        cameraForward: SIMD3<Float>
    ) -> SIMD3<Float>? {
        let d1 = SIMD3<Float>(0, 1, 0)
        let d2 = cameraForward
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
