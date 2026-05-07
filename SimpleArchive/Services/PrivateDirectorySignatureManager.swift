import Foundation
import UIKit

protocol PrivateDirectorySignatureManagerType: AnyObject {
    var isRegisteredSignature: Bool { get }
    var centerPoints: [[Double]] { get }

    func registerSignature(sign: [[Double]]) -> [Double]
    func verifySignature(sign: [[Double]]) -> Bool
    func removeSignature(index: Int)
    func completeRegister()
    func clearSignature()
}

final class PrivateDirectorySignatureManager: PrivateDirectorySignatureManagerType {

    private let ud = UserDefaults.standard
    private let privateDirectoryAccessPassSignatureKey = "privateDirectoryPassSignature"
    private let passSignatureRegisterStateKey = "passSignatureRegisterStateKey"
    private let passSignatureCenterPointKey = "passSignatureCenterPointKey"
    private let xSimilarityPassScore: Double = 0.2
    private let ySimilarityPassScore: Double = 0.2
    private let patternSimilarityPassScore: Double = 0.7

    var centerPoints: [[Double]] {
        ud.object(forKey: passSignatureCenterPointKey) as? [[Double]] ?? []
    }

    var isRegisteredSignature: Bool {
        ud.object(forKey: passSignatureRegisterStateKey) as? Bool ?? false
    }

    func registerSignature(sign: [[Double]]) -> [Double] {
        if var registeredSign = ud.object(forKey: privateDirectoryAccessPassSignatureKey) as? [[[Double]]] {
            registeredSign.append(sign)
            ud.set(registeredSign, forKey: privateDirectoryAccessPassSignatureKey)
        } else {
            ud.set([sign], forKey: privateDirectoryAccessPassSignatureKey)
        }

        if var centerPoints = ud.object(forKey: passSignatureCenterPointKey) as? [[Double]] {
            if let center = medoid(sign) {
                centerPoints.append(center)
                ud.set(centerPoints, forKey: passSignatureCenterPointKey)
                return center
            }
        } else {
            if let center = medoid(sign) {
                ud.set([center], forKey: passSignatureCenterPointKey)
                return center
            }
        }
        return []
    }

    func removeSignature(index: Int) {
        if var registeredSign = ud.object(forKey: privateDirectoryAccessPassSignatureKey) as? [[[Double]]] {
            registeredSign.remove(at: index)
            ud.set(registeredSign, forKey: privateDirectoryAccessPassSignatureKey)
        }
        if var centerPoints = ud.object(forKey: passSignatureCenterPointKey) as? [[Double]] {
            centerPoints.remove(at: index)
            ud.set(centerPoints, forKey: passSignatureCenterPointKey)
        }
    }

    func verifySignature(sign: [[Double]]) -> Bool {
        let xs = sign.map { sqrt(pow($0[0], 3)) }
        let ys = sign.map { sqrt(pow($0[1], 3)) }

        if let registeredSign = ud.object(forKey: privateDirectoryAccessPassSignatureKey) as? [[[Double]]] {
            var isPassedPointSimilarity = false

            for s in registeredSign {
                let solutionX = s.map { sqrt(pow($0[0], 3)) }
                let solutionY = s.map { sqrt(pow($0[1], 3)) }

                let maxX = solutionX.max() ?? 0
                let invertedX = solutionX.map { maxX - $0 }

                let maxY = solutionY.max() ?? 0
                let invertedY = solutionY.map { maxY - $0 }

                let telx = dynamicTimeWarping(a: solutionX, b: invertedX)
                let tely = dynamicTimeWarping(a: solutionY, b: invertedY)

                let tryx = dynamicTimeWarping(a: solutionX, b: xs)
                let tryy = dynamicTimeWarping(a: solutionY, b: ys)

                let resultX = tryx / telx
                let resultY = tryy / tely

                print("\(resultX) : \(resultY)")

                if resultX <= xSimilarityPassScore, resultY <= ySimilarityPassScore {
                    isPassedPointSimilarity = true
                    break
                }
            }

            if isPassedPointSimilarity,
                let signatureSimilarity = registeredSign.map({ getSignatureSimilarity(sign: sign, s: $0) }).max()
            {
                print("signatureSimilarity : \(signatureSimilarity)")
                return signatureSimilarity >= patternSimilarityPassScore
            }
        }
        return false
    }

    func completeRegister() {
        ud.set(true, forKey: passSignatureRegisterStateKey)
    }

    func clearSignature() {
        ud.removeObject(forKey: privateDirectoryAccessPassSignatureKey)
        ud.removeObject(forKey: passSignatureRegisterStateKey)
        ud.removeObject(forKey: passSignatureCenterPointKey)

    }

    private func dynamicTimeWarping(a: [Double], b: [Double]) -> Double {
        var dp = Array(repeating: Array(repeating: Double.infinity, count: b.count + 1), count: a.count + 1)
        dp[0][0] = 0

        let n = a.count
        let m = b.count
        for i in 1...n {
            for j in 1...m {
                let dist = abs(a[i - 1] - b[j - 1])
                dp[i][j] = dist + min(dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1])
            }
        }

        var path: [Double] = []
        var i = n
        var j = m

        while i > 0 || j > 0 {
            path.append(dp[i][j])

            let top = i < n ? dp[i - 1][j] : Double.infinity
            let left = j > 0 ? dp[i][j - 1] : Double.infinity
            let topLeft = (i > 0 && j > 0) ? dp[i - 1][j - 1] : Double.infinity
            let minVal = min(top, left, topLeft)

            if minVal == topLeft {
                i -= 1
                j -= 1
            } else if minVal == top {
                i -= 1
            } else {
                j -= 1
            }
        }

        return path.reduce(0, +) / Double(path.count)
    }

    private func medoid(_ points: [[Double]]) -> [Double]? {
        guard !points.isEmpty else { return nil }
        guard points.count > 1 else { return points[0] }

        var minTotalDistance = Double.infinity
        var result: [Double]?

        for candidate in points {
            let totalDistance = points.reduce(0.0) { sum, point in
                sum + sqrt(pow(candidate[0] - point[0], 2) + pow(candidate[1] - point[1], 2))
            }
            if totalDistance < minTotalDistance {
                minTotalDistance = totalDistance
                result = candidate
            }
        }

        return result
    }

    private func getSignatureSimilarity(sign: [[Double]], s: [[Double]]) -> Double {
        var slopes: [Double] = []
        var solutionSlopes: [Double] = []

        for i in 0..<sign.count {
            let slope = differentiate(at: i, in: sign)
            if slope != .infinity && slope != -.infinity {
                slopes.append(-slope)
            }
        }

        for i in 0..<s.count {
            let sslope = differentiate(at: i, in: s)
            if sslope != .infinity && sslope != -.infinity {
                solutionSlopes.append(-sslope)
            }
        }

        slopes = savitzkyGolay(slopes, windowSize: 23, polynomialOrder: 6)
        solutionSlopes = savitzkyGolay(solutionSlopes, windowSize: 23, polynomialOrder: 6)

        let ra = linearInterpolation(slopes, to: min(slopes.count, solutionSlopes.count))
        let rb = linearInterpolation(solutionSlopes, to: min(slopes.count, solutionSlopes.count))

        return cosineSimilarity(a: ra, b: rb)
    }

    private func differentiate(at index: Int, in points: [[Double]]) -> Double {
        guard points.count > 1 else { return 0 }

        func slope(_ p0: [Double], _ p1: [Double]) -> Double {
            let dx = p1[0] - p0[0]
            let dy = p1[1] - p0[1]
            if dx == 0 {
                return dy >= 0 ? .infinity : -.infinity
            }
            return dy / dx
        }

        if index == 0 {
            return slope(points[0], points[1])
        }

        if index == points.count - 1 {
            return slope(points[index - 1], points[index])
        }

        let prev = points[index - 1]
        let next = points[index + 1]
        return slope(prev, next)
    }

    private func savitzkyGolay(_ data: [Double], windowSize: Int, polynomialOrder: Int) -> [Double] {
        let half = windowSize / 2
        let n = data.count

        func vandermonde() -> [[Double]] {
            var A = Array(
                repeating: Array(repeating: 0.0, count: polynomialOrder + 1),
                count: windowSize)

            for i in 0..<windowSize {
                let x = Double(i - half)
                var value = 1.0
                for j in 0...polynomialOrder {
                    A[i][j] = value
                    value *= x
                }
            }
            return A
        }

        func transpose(_ m: [[Double]]) -> [[Double]] {
            let rows = m.count
            let cols = m[0].count
            var result = Array(repeating: Array(repeating: 0.0, count: rows), count: cols)

            for i in 0..<rows {
                for j in 0..<cols {
                    result[j][i] = m[i][j]
                }
            }
            return result
        }

        func multiply(_ a: [[Double]], _ b: [[Double]]) -> [[Double]] {
            let rows = a.count
            let cols = b[0].count
            let inner = b.count

            var result = Array(repeating: Array(repeating: 0.0, count: cols), count: rows)

            for i in 0..<rows {
                for j in 0..<cols {
                    for k in 0..<inner {
                        result[i][j] += a[i][k] * b[k][j]
                    }
                }
            }
            return result
        }

        // 간단한 Gauss-Jordan
        func invert(_ m: [[Double]]) -> [[Double]] {
            let n = m.count
            var a = m
            var inv = Array(repeating: Array(repeating: 0.0, count: n), count: n)

            for i in 0..<n { inv[i][i] = 1 }

            for i in 0..<n {
                var diag = a[i][i]
                if diag == 0 {
                    for j in i + 1..<n {
                        if a[j][i] != 0 {
                            a.swapAt(i, j)
                            inv.swapAt(i, j)
                            diag = a[i][i]
                            break
                        }
                    }
                }

                let factor = diag
                for j in 0..<n {
                    a[i][j] /= factor
                    inv[i][j] /= factor
                }

                for k in 0..<n {
                    if k == i { continue }
                    let f = a[k][i]
                    for j in 0..<n {
                        a[k][j] -= f * a[i][j]
                        inv[k][j] -= f * inv[i][j]
                    }
                }
            }
            return inv
        }

        let A = vandermonde()
        let AT = transpose(A)
        let ATA = multiply(AT, A)
        let ATAInv = invert(ATA)
        let pseudo = multiply(ATAInv, AT)

        
        let coeffs = pseudo[0]
        var result = [Double](repeating: 0, count: n)

        for i in 0..<n {
            var sum = 0.0

            for j in 0..<windowSize {
                let idx = i + j - half

                let clampedIndex = min(max(idx, 0), n - 1)
                sum += coeffs[j] * data[clampedIndex]
            }

            result[i] = sum
        }

        return result
    }

    private func linearInterpolation(_ arr: [Double], to count: Int) -> [Double] {
        guard arr.count >= 2 else { return arr }
        guard arr.count != count else { return arr }

        if arr.count < count {
            let step = Double(arr.count - 1) / Double(count - 1)
            return (0..<count)
                .map { i in
                    let pos = Double(i) * step
                    let lo = Int(pos)
                    let hi = min(lo + 1, arr.count - 1)
                    let t = pos - Double(lo)
                    return arr[lo] * (1 - t) + arr[hi] * t
                }
        } else {
            let step = Double(arr.count - 1) / Double(count - 1)
            return (0..<count)
                .map { i in
                    let start = Int(Double(i) * step)
                    let end = min(Int(Double(i + 1) * step), arr.count - 1)
                    let slice = arr[start...end]
                    return slice.reduce(0, +) / Double(slice.count)
                }
        }
    }

    private func cosineSimilarity(a: [Double], b: [Double]) -> Double {
        guard a.count == b.count else { return -1 }
        var r: Double = 0
        var ar: Double = 0
        var br: Double = 0
        for i in 0..<a.count {
            r += a[i] * b[i]
            ar += pow(a[i], 2)
            br += pow(b[i], 2)
        }
        let denom = sqrt(ar) * sqrt(br)
        guard denom != 0 else { return 0 }
        return r / denom
    }
}
