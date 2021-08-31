import Foundation

public enum GeneratorKind {
    case ceil
    case floor
}

public func random<InputType: Numeric, OutputType: Numeric>(
    _ getProbability: (InputType) -> OutputType,
    from firstValue: InputType,
    to lastValue: InputType,
    step: InputType,
    zero: OutputType,
    computeSquare: (OutputType, OutputType) -> OutputType,
    generate: (InputType, InputType) -> InputType,
    base baseValue: InputType,
    generatorKind: GeneratorKind,
    identity: (InputType) -> OutputType
) -> InputType where InputType: Comparable, OutputType: Comparable {
    var leftBoundary = firstValue
    var nextLeftBoundary = leftBoundary
    var rightBoundary = lastValue
    if rightBoundary < leftBoundary {
        (leftBoundary, rightBoundary) = (rightBoundary, leftBoundary)
    }

    var totalProbability = zero
    let baseValueAsProbability = identity(baseValue)

    var leftHeight: OutputType? = .none
    var rightHeight: OutputType? = .none
    
    // print("base = \(baseValue)")
    // print("step = \(step)")

    repeat {
        // print("from \(leftBoundary) to \(nextLeftBoundary) prob is \(totalProbability)")
        leftBoundary = nextLeftBoundary
        leftHeight = leftHeight ?? getProbability(leftBoundary)
        nextLeftBoundary = leftBoundary + step
        rightHeight = getProbability(nextLeftBoundary)

        let nextTotalProbability = totalProbability + computeSquare(leftHeight!, rightHeight!)
        // print("next tp = \(nextTotalProbability)")
        
        if (
            ((generatorKind == .ceil) && (baseValueAsProbability > totalProbability) && (baseValueAsProbability <= nextTotalProbability)) || 
            ((generatorKind == .floor) && (baseValueAsProbability >= totalProbability) && (baseValueAsProbability < nextTotalProbability))
         ) {
            return generate(leftBoundary, nextLeftBoundary)
        }
        
        totalProbability = nextTotalProbability
    } while leftBoundary <= rightBoundary

    // print("left = \(leftBoundary), right = \(rightBoundary)")
    
    return generatorKind == .floor ? generate(leftBoundary, nextLeftBoundary) : generate(firstValue, firstValue + step) // If wasn't able to generate earlier
}

public func random<Type: Numeric>(
    _ getProbability: (Type) -> Type,
    from firstValue: Type,
    to lastValue: Type,
    step: Type,
    zero: Type,
    base: Type,
    generatorKind: GeneratorKind,
    computeSquare: (Type, Type) -> Type,
    generate: (Type, Type) -> Type
) -> Type where Type: Comparable {
    return random(
        getProbability, from: firstValue, to: lastValue, step: step, zero: zero, computeSquare: computeSquare, generate: generate, base: base, generatorKind: generatorKind
    ) {
        $0
    }
}

public func random(
    _ getValue: (Double) -> Double,
    from firstValue: Double,
    to lastValue: Double,
    precision nIntervals: Int = 10,
    kind: IntegralKind = .right,
    generatorKind: GeneratorKind = .ceil
) -> Double {
    let step = abs(lastValue - firstValue) / Double(nIntervals)
    
    let result = random(
        getValue, from: firstValue, to: lastValue, step: step, zero: 0.0,
        base: generatorKind == .ceil ? Double.random(in: 0...1) : Double.random(in: 0..<1),
        generatorKind: generatorKind
    ) { (leftHeight: Double, rightHeight: Double) in
        if kind == .right {
            return rightHeight * step
        } else if kind == .left {
            return leftHeight * step
        } else {
            // return Double(rightHeight + leftHeight) * step / 2.0
            return (leftHeight + rightHeight) / 2.0 * step
        }
    } generate: { (leftBound: Double, rightBound: Double) in
        return (leftBound + rightBound) / 2.0
    }

    return result
}

// public func integrate(
//     _ getValue: @escaping (Double) -> Double,
//     from firstValue: Double, to lastValue: Double, precision nIntervals: Int = 10, kind: IntegralKind = .right, nParts: Int
// ) async -> Double {
//     let results = await concurrentMap(
//         splitInterval(from: firstValue, to: lastValue, nParts: nParts)
//     ) { interval -> Double in
//         let result = integrate( getValue,
//             from: interval.from,
//             to: interval.to,
//             precision: nIntervals / nParts + 1,
//             kind: kind
//         )
//         return result
//     }
    
//     return results.reduce(0, +)
// }
