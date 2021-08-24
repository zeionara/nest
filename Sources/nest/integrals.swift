import Foundation

// public func integrate<InputType: Numeric, OutputType: Numeric>(_ getValue: (InputType) -> OutputType, from firstValue: InputType, to lastValue: InputType) -> OutputType {
//     var isInverseOrderBounds = false
//     if lastValue > firstValue {
//         (lastValue, firstValue) = (firstValue, lastValue)
//         isInverseOrderBounds = true
//     }
    
//     return (lastValue - firstValue) * getValue(firstValue)
// }

public func integrate<InputType: Numeric, OutputType: Numeric>(
    _ getValue: (InputType) -> OutputType,
    from firstValue: InputType, to lastValue: InputType,
    step: InputType, zero: OutputType,
    computeSquare: (OutputType, OutputType) -> OutputType,
    identity: (InputType) -> OutputType
) -> OutputType where InputType: Comparable {
    var isInverseOrderBounds = false
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
        leftHeight = leftHeight ?? getValue(leftBoundary)
        leftBoundary += step
        rightHeight = getValue(leftBoundary)

        result += computeSquare(leftHeight!, rightHeight!)

        // print(leftBoundary)
    } while leftBoundary <= rightBoundary

    // let step = (rightBoundary - leftBoundary) / nIntervals
    
    return result // identity(lastValue - firstValue) * getValue(firstValue)
}

public func integrate<Type: Numeric>(
    _ getValue: (Type) -> Type,
    from firstValue: Type, to lastValue: Type, step: Type, zero: Type, computeSquare: (Type, Type) -> Type
) -> Type where Type: Comparable {
    return integrate(
        getValue, from: firstValue, to: lastValue, step: step, zero: zero, computeSquare: computeSquare
    ) {
        $0
    }
}

public func integrate(
    _ getValue: (Double) -> Double,
    from firstValue: Double, to lastValue: Double, precision nIntervals: Int = 10
) -> Double {
    let step = abs(lastValue - firstValue) / Double(nIntervals)
    // print(step)
    return integrate(
        getValue, from: firstValue, to: lastValue, step: step, zero: 0.0
    ) { leftHeight, rightHeight in
        return rightHeight * step
        // return ((leftHeight * step) + (rightHeight * step)) / 2.0
    }
}
