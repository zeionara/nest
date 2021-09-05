public typealias Interval<Value> = (from: Value, to: Value)

public protocol Integrable {
    associatedtype IntervalValueType
    associatedtype ResultType

    static func splitInterval(from firstValue: IntervalValueType, to lastValue: IntervalValueType, nParts: Int) -> Array<Interval<IntervalValueType>>
    static func integrate(_ getValue: (IntervalValueType) async -> ResultType, from firstValue: IntervalValueType, to lastValue: IntervalValueType, precision nIntervals: Int, kind: IntegralKind) async -> ResultType
}

extension Double: Integrable {
    public static func splitInterval(from firstValue: Self, to lastValue: Self, nParts: Int) -> Array<Interval<Self>> {
        let step = (lastValue - firstValue) / Self(nParts)
        var results = [Interval<Self>]()
        var currentValue = firstValue

        for _ in 0..<nParts {
            let nextValue = currentValue + step
            results.append(Interval(from: currentValue, to: nextValue))
            currentValue = nextValue
        }

        return results
    }

    public static func integrate(_ getValue: (Double) async -> Double, from firstValue: Double, to lastValue: Double, precision nIntervals: Int = 10, kind: IntegralKind = .right) async -> Double {
        let step = abs(lastValue - firstValue) / Double(nIntervals)
        
        let result = await integrated(
            getValue, from: firstValue, to: lastValue, step: step, zero: 0.0
        ) { (leftHeight: Double, rightHeight: Double) in
            if kind == .right {
                return rightHeight * step
            } else if kind == .left {
                return leftHeight * step
            } else {
                return (leftHeight + rightHeight) / 2.0 * step
            }
        }

        return result.isPositive ? result.value : -result.value
    }
}

// public func splitInterval(from firstValue: Double, to lastValue: Double, nParts: Int) -> Array<Interval<Double>> {
//     let step = (lastValue - firstValue) / Double(nParts)
//     var results = [Interval<Double>]()
//     var currentValue = firstValue

//     for _ in 0..<nParts {
//         let nextValue = currentValue + step
//         results.append(Interval(from: currentValue, to: nextValue))
//         currentValue = nextValue
//     }

//     return results
// }