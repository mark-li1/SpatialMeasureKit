import simd

let bowTie: [SIMD3<Float>] = [
    SIMD3(0, 0, 0),
    SIMD3(2, 0, 0),
    SIMD3(0, 0, 2),
    SIMD3(2, 0, 2),
]

func pentagram(radius: Float) -> [SIMD3<Float>] {
    (0..<5).map { k in
        let angle = Float.pi / 2 + Float((2 * k) % 5) * 2 * .pi / 5
        return SIMD3<Float>(radius * cos(angle), 0, radius * sin(angle))
    }
}
