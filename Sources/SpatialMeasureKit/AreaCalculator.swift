import simd

public struct AreaCalculator {
    public init() {}

    public func computeArea(from points: [SIMD3<Float>]) -> Float {
        guard points.count >= 3 else { return 0 }
        var sum: Float = 0
        for i in 0..<points.count {
            let j = (i + 1) % points.count
            sum += points[i].x * points[j].z - points[j].x * points[i].z
        }
        return abs(sum) / 2
    }
}

