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

    public static func makeIntegratingClosure(step: Self, kind: IntegralKind) -> (Self, Self) -> Self {
        func integrateOnRightSide(leftHeight: Self, rightHeight: Self) -> Self {
            rightHeight * step
        }

        func integrateOnLeftSide(leftHeight: Self, rightHeight: Self) -> Self {
            leftHeight * step
        }

        func integrateOnMiddle(leftHeight: Self, rightHeight: Self) -> Self {
            (leftHeight + rightHeight) / 2.0 * step
        }

        if kind == .right {
            return integrateOnRightSide
        } else if kind == .left {
            return integrateOnLeftSide
        } else {
            return integrateOnMiddle
        }
    }

    public static func integrate (
        _ getValue: (Self) async -> Self,
        from firstValue: Self, to lastValue: Self, precision nIntervals: Int = 10, kind: IntegralKind = .right
    ) async -> Self {
        let step = abs(lastValue - firstValue) / Self(nIntervals)
        
        let result = await _integrate(
            getValue, from: firstValue, to: lastValue, step: step, zero: 0.0, computeSquare: Self.makeIntegratingClosure(step: step, kind: kind)
        )

        return result.isPositive ? result.value : -result.value
    }

    public static func integrate (
        _ getValue: (Self) async -> Self,
        from firstValue: Self, to lastValue: Self, precision nIntervals: Int = 10, kind: IntegralKind = .right
    ) async -> IntegrationResult<Self> {
        let step = abs(lastValue - firstValue) / Self(nIntervals)
        
        return await _integrate(
            getValue, from: firstValue, to: lastValue, step: step, zero: 0.0, computeSquare: Self.makeIntegratingClosure(step: step, kind: kind)
        )
    }
}
