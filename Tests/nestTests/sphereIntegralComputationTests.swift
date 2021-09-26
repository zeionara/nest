import XCTest
@testable import nest

private let skipHeavyComputations = true
private let skipHeavyComputationsMessage = "Skipping cases which involve heavy computation to avoid enormous execution time"

private func computeElementarySphereSquare(_ r: Double, x: Double, precision: Int = 10000, kind: IntegralKind = .right) async -> Double {
    let partialSum: Double = await Double.integrate( { (y: Double) -> Double in
            let value = r*r - (x*x + y*y)
            return value > 0 ? value.squareRoot() : 0.0 
        },
        from: 0,
        to: r,
        precision: precision,
        kind: kind
    )
    return 2.0 * partialSum
}

private func computeSphereVolumeUsingCartesianSystem(_ r: Double, precision: Int = 10000, kind: IntegralKind = .right) async -> Double {
    let partialSum: Double = await Double.integrate( { (x: Double) -> Double in
            return await computeElementarySphereSquare(
                r,
                x: x,
                precision: precision,
                kind: kind
            )
        },
        from: 0,
        to: r,
        precision: precision,
        kind: kind
    )
    return 4.0 * partialSum
}

public func computeSphereVolumeUsingCartesianSystemWithConcurrency(_ r: Double, precision: Int = 10000, kind: IntegralKind = .right, nParts: Int = 10) async -> Double {
    return await 4.0 * integrate( { (x: Double) -> Double in
        return await computeElementarySphereSquare(
            r,
            x: x,
            precision: precision,
            kind: kind
        )
    },
    from: 0,
    to: r,
    precision: precision,
    kind: kind,
    nParts: nParts
    )
}

public func computeSphereVolumeViaExplicitMultivariateIntegration(_ r: Double, precision: Int = 10000, kind: IntegralKind = .right, nParts: Int = 10) async -> Double {
    let partialSum = await integrate(
        { (x: [Double]) -> Double in
            let squaredValue = r*r - (x.first!*x.first! + x.last!*x.last!)
            return squaredValue > 0 ? squaredValue.squareRoot() : 0.0 
        },
        from: [0.0, 0.0],
        to: [r, r],
        precision: precision,
        kind: kind,
        nParts: nParts
    )
    return 8 * partialSum
}

final class sphereIntegralComputationTest: XCTestCase {
    func testSphereIntegration() throws {
        try XCTSkipIf(skipHeavyComputations, skipHeavyComputationsMessage)
        BlockingTask {
            let integrationResult = await computeSphereVolumeUsingCartesianSystem(
                5.0
            )
            XCTAssertEqual(integrationResult, 523.59878, accuracy: 0.1)
        }
    }

    func testSphereIntegrationWithConcurrency() throws {
        try XCTSkipIf(skipHeavyComputations, skipHeavyComputationsMessage)
        BlockingTask {
            let integrationResult = await computeSphereVolumeUsingCartesianSystemWithConcurrency(
                5.0,
                nParts: 4
            )
            XCTAssertEqual(integrationResult, 523.59878, accuracy: 0.1)
        }
    }

    func testSphereIntegrationWithConcurrencyAndExplicitMultivariateIntegration() throws {
        try XCTSkipIf(skipHeavyComputations, skipHeavyComputationsMessage)
        BlockingTask {
            let integrationResult = await computeSphereVolumeViaExplicitMultivariateIntegration(
                5.0,
                nParts: 4
            )
            XCTAssertEqual(integrationResult, 523.59878, accuracy: 0.1)
        }
    }
}

