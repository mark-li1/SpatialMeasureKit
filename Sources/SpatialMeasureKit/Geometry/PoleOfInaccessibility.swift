import simd

/// The point inside the closed outline `polygon` farthest from every one of its segments, and that
/// distance, found with the polylabel algorithm (Agafonkin, 2016) to within `precision`. Inside
/// means a nonzero winding number. `nil` for degenerate input or when no inside point is found.
func poleOfInaccessibility(of polygon: [SIMD2<Float>], precision: Float) -> (center: SIMD2<Float>, distance: Float)? {
    guard polygon.count >= 3,
          let minX = polygon.map(\.x).min(), let maxX = polygon.map(\.x).max(),
          let minY = polygon.map(\.y).min(), let maxY = polygon.map(\.y).max()
    else { return nil }
    let cellSize = min(maxX - minX, maxY - minY)
    guard cellSize > .ulpOfOne else { return nil }

    func cell(at center: SIMD2<Float>, halfSize: Float) -> Cell {
        Cell(center: center, halfSize: halfSize, distance: signedDistance(from: center, to: polygon))
    }

    var queue = CellQueue()
    var x = minX
    while x < maxX {
        var y = minY
        while y < maxY {
            queue.push(cell(at: SIMD2(x + cellSize / 2, y + cellSize / 2), halfSize: cellSize / 2))
            y += cellSize
        }
        x += cellSize
    }

    let vertexAverage = cell(at: polygon.reduce(SIMD2<Float>.zero, +) / Float(polygon.count), halfSize: 0)
    let boxCenter = cell(at: SIMD2((minX + maxX) / 2, (minY + maxY) / 2), halfSize: 0)
    var best = boxCenter.distance > vertexAverage.distance ? boxCenter : vertexAverage

    while let current = queue.pop() {
        if current.distance > best.distance {
            best = current
        }
        guard current.potential - best.distance > precision else { continue }
        let half = current.halfSize / 2
        for offset in [SIMD2<Float>(-half, -half), SIMD2(half, -half), SIMD2(-half, half), SIMD2(half, half)] {
            queue.push(cell(at: current.center + offset, halfSize: half))
        }
    }

    guard best.distance > 0 else { return nil }
    return (best.center, best.distance)
}

private func signedDistance(from point: SIMD2<Float>, to polygon: [SIMD2<Float>]) -> Float {
    var nearest = Float.greatestFiniteMagnitude
    for i in polygon.indices {
        nearest = min(nearest, distance(from: point, toSegmentFrom: polygon[i], to: polygon[(i + 1) % polygon.count]))
    }
    return windingNumber(of: point, around: polygon) != 0 ? nearest : -nearest
}

private struct Cell {
    let center: SIMD2<Float>
    let halfSize: Float
    let distance: Float

    var potential: Float {
        distance + halfSize * Float(2).squareRoot()
    }
}

private struct CellQueue {
    private var cells: [Cell] = []

    mutating func push(_ cell: Cell) {
        cells.append(cell)
        var child = cells.count - 1
        while child > 0 {
            let parent = (child - 1) / 2
            guard cells[child].potential > cells[parent].potential else { break }
            cells.swapAt(child, parent)
            child = parent
        }
    }

    mutating func pop() -> Cell? {
        guard !cells.isEmpty else { return nil }
        cells.swapAt(0, cells.count - 1)
        let top = cells.removeLast()
        var parent = 0
        while true {
            let left = 2 * parent + 1
            let right = left + 1
            var largest = parent
            if left < cells.count, cells[left].potential > cells[largest].potential { largest = left }
            if right < cells.count, cells[right].potential > cells[largest].potential { largest = right }
            guard largest != parent else { break }
            cells.swapAt(parent, largest)
            parent = largest
        }
        return top
    }
}
