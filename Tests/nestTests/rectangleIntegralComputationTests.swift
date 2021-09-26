import XCTest
@testable import nest

private func computeConstantFunctionIntegral(constant: Double, from firstValue: Double, to lastValue: Double, precision: Int = 10000, kind: IntegralKind = .right) async -> Double {
    func constantFunction(_ x: Double) -> Double {
        return constant
    }

    return await Double.integrate(constantFunction, from: firstValue, to: lastValue, precision: precision, kind: kind)
}

final class rectangleIntegralComputationTest: XCTestCase {
    func testRectangleIntegration() throws {
        BlockingTask {
            let integrationResult = await computeConstantFunctionIntegral(
                constant: 5.0,
                from: 1.0,
                to: 3.0
            )
            XCTAssertEqual(integrationResult, 10.0, accuracy: 0.001)
        }
    }

    func testRectangleIntegrationWithSwappedBoundaries() throws {
        BlockingTask {
            let integrationResult = await computeConstantFunctionIntegral(
                constant: 5.0,
                from: 3.0,
                to: 1.0
            )
            XCTAssertEqual(integrationResult, -10.0, accuracy: 0.001)
        }
    }

    func testRectangleIntegrationWithNegativeFunctionValues() throws {
        BlockingTask {
            let integrationResult = await computeConstantFunctionIntegral(
                constant: -5.0,
                from: 1.0,
                to: 3.0
            )
            XCTAssertEqual(integrationResult, -10.0, accuracy: 0.001)
        }
    }

    func testRectangleIntegrationWithNegativeFunctionValuesAndSwappedBoundaries() throws {
        BlockingTask {
            let integrationResult = await computeConstantFunctionIntegral(
                constant: -5.0,
                from: 3.0,
                to: 1.0
            )
            XCTAssertEqual(integrationResult, 10.0, accuracy: 0.001)
        }
    }
}
