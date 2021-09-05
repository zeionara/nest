import Foundation

public enum IntegralKind {
    case left
    case right
    case mean
}

public typealias IntegrationResult<ValueType> = (value: ValueType, isPositive: Bool)

public typealias Interval<Value> = (from: Value, to: Value)

public protocol Integrable {
    associatedtype IntervalValueType
    associatedtype ResultType

    static func splitInterval(from firstValue: IntervalValueType, to lastValue: IntervalValueType, nParts: Int) -> Array<Interval<IntervalValueType>>
    static func integrate(
        _ getValue: (IntervalValueType) async -> ResultType,
        from firstValue: IntervalValueType, to lastValue: IntervalValueType, precision nIntervals: Int, kind: IntegralKind
    ) async -> ResultType
}

public func integrate<InputType: Numeric, OutputType: Numeric>(
    _ getValue: (InputType) async -> OutputType,
    from firstValue: InputType, to lastValue: InputType,
    step: InputType, zero: OutputType,
    computeSquare: (OutputType, OutputType) -> OutputType,
    identity: (InputType) -> OutputType
) async -> IntegrationResult<OutputType> where InputType: Comparable {
    var isInverseOrderBounds = false // TODO: is not used
    var leftBoundary = firstValue
    var rightBoundary = lastValue
    if rightBoundary < leftBoundary {
        (leftBoundary, rightBoundary) = (rightBoundary, leftBoundary)
        isInverseOrderBounds = true
    }

    // print(leftBoundary, rightBoundary)

    var result = zero

    // leftBoundary -= step // To include the left boundary value as well as the right one
    var leftHeight: OutputType? = .none
    var rightHeight: OutputType? = .none
    repeat {
        if let rightHeightUnwrapped = rightHeight {
            leftHeight = rightHeightUnwrapped
        } else {
            leftHeight = await getValue(leftBoundary)    
        }
        // leftHeight = rightHeight ?? getValue(leftBoundary)
        leftBoundary += step
        rightHeight = await getValue(leftBoundary)

        result += computeSquare(leftHeight!, rightHeight!)

        // print(leftBoundary)
    } while leftBoundary <= rightBoundary

    // let step = (rightBoundary - leftBoundary) / nIntervals
    
    return IntegrationResult(value: result, isPositive: !isInverseOrderBounds) // identity(lastValue - firstValue) * getValue(firstValue)
}

public func _integrate<Type: Numeric>(
    _ getValue: (Type) async -> Type,
    from firstValue: Type, to lastValue: Type, step: Type, zero: Type, computeSquare: (Type, Type) -> Type
) async -> IntegrationResult<Type> where Type: Comparable {
    return await integrate(
        getValue, from: firstValue, to: lastValue, step: step, zero: zero, computeSquare: computeSquare
    ) {
        $0
    }
}

public func integrate<InputType: Integrable, OutputType: Numeric>(
    _ getValue: @escaping (InputType) async -> OutputType,
    from firstValue: InputType, to lastValue: InputType, precision nIntervals: Int = 10, kind: IntegralKind = .right, nParts: Int
) async -> OutputType where InputType.IntervalValueType == InputType, InputType.ResultType == OutputType {
    let results = await concurrentMap(
        InputType.splitInterval(from: firstValue, to: lastValue, nParts: nParts)
    ) { interval async -> OutputType in
        let result = await InputType.integrate( getValue,
            from: interval.from,
            to: interval.to,
            precision: nIntervals / nParts + 1,
            kind: kind
        )
        return result
    }
    
    return results.reduce(0, +)
}

public func integrate<InputType: Integrable, OutputType: Numeric>(
    _ getValue: ([InputType]) -> OutputType,
    from firstValue: [InputType], to lastValue: [InputType], precision nIntervals: Int = 10, kind: IntegralKind = .right
) async -> OutputType where InputType.IntervalValueType == InputType, InputType.ResultType == OutputType {
    if firstValue.count == 1 {
        func getValueFixed(_ x: InputType) -> OutputType {
            return getValue([x])
        }
        
        return await InputType.integrate(
            getValueFixed,
            from: firstValue.first!,
            to: lastValue.first!,
            precision: nIntervals,
            kind: kind
        )
    }

    func getValueFixed(_ firstDimensionValue: InputType) async -> OutputType {
        func getValueOnShortenedArray(_ lastDimensionValues: [InputType]) -> OutputType {
            return getValue([firstDimensionValue] + lastDimensionValues)
        }
        
        return await integrate(
            getValueOnShortenedArray,
            from: Array(firstValue.dropFirst()),
            to: Array(lastValue.dropFirst()),
            precision: nIntervals,
            kind: kind
        )
    }
    
    return await InputType.integrate(
        getValueFixed,
        from: firstValue.first!,
        to: lastValue.first!,
        precision: nIntervals,
        kind: kind
    )
}

public func integrate<InputType: Integrable, OutputType: Numeric>(
    _ getValue: @escaping ([InputType]) -> OutputType,
    from firstValue: [InputType], to lastValue: [InputType], precision nIntervals: Int = 10, kind: IntegralKind = .right, nParts: Int
) async -> OutputType where InputType.IntervalValueType == InputType, InputType.ResultType == OutputType {
    if firstValue.count == 1 {
        func getValueFixed(_ x: InputType) -> OutputType {
            return getValue([x])
        }
        
        return await integrate(
            getValueFixed,
            from: firstValue.first!,
            to: lastValue.first!,
            precision: nIntervals,
            kind: kind,
            nParts: nParts
        )
    }

    func getValueFixed(_ firstDimensionValue: InputType) async -> OutputType {
        func getValueOnShortenedArray(_ lastDimensionValues: [InputType]) -> OutputType {
            return getValue([firstDimensionValue] + lastDimensionValues)
        }
        
        return await integrate(
            getValueOnShortenedArray,
            from: Array(firstValue.dropFirst()),
            to: Array(lastValue.dropFirst()),
            precision: nIntervals,
            kind: kind,
            nParts: nParts
        )
    }
    
    return await integrate(
        getValueFixed,
        from: firstValue.first!,
        to: lastValue.first!,
        precision: nIntervals,
        kind: kind,
        nParts: nParts
    )
}
