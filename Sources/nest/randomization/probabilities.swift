import Foundation

public enum GeneratorKind {
    case ceil
    case floor
}

public protocol Randomizable {
    associatedtype SampledValueType
    associatedtype ProbabilityType

    static func splitInterval(from firstValue: SampledValueType, to lastValue: SampledValueType, nParts: Int) -> Array<Interval<SampledValueType>>
    static func random(
        _ getValue: (SampledValueType) -> ProbabilityType, from firstValue: SampledValueType, to lastValue: SampledValueType, precision nIntervals: Int,
        kind: IntegralKind, generatorKind: GeneratorKind
    ) async -> SampledValueType
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

    repeat {
        leftBoundary = nextLeftBoundary
        leftHeight = rightHeight ?? getProbability(leftBoundary)
        nextLeftBoundary = leftBoundary + step
        rightHeight = getProbability(nextLeftBoundary)

        let nextTotalProbability = totalProbability + computeSquare(leftHeight!, rightHeight!)
        
        if (
            ((generatorKind == .ceil) && (baseValueAsProbability > totalProbability) && (baseValueAsProbability <= nextTotalProbability)) || 
            ((generatorKind == .floor) && (baseValueAsProbability >= totalProbability) && (baseValueAsProbability < nextTotalProbability))
         ) {
            return generate(leftBoundary, nextLeftBoundary)
        }
        
        totalProbability = nextTotalProbability
    } while leftBoundary <= rightBoundary
    
    return generatorKind == .floor ? generate(leftBoundary, nextLeftBoundary) : generate(firstValue, firstValue + step) // If wasn't able to generate earlier
}

public func _random<Type: Numeric>(
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

// public func random<InputType: Randomizable, OutputType: Numeric>(
//     _ getValue: @escaping (InputType) async -> OutputType,
//     from firstValue: InputType, to lastValue: InputType, precision nIntervals: Int = 10, kind: IntegralKind = .right, nParts: Int
// ) async -> OutputType where InputType.IntervalValueType == InputType, InputType.ResultType == OutputType {
//     let results = await concurrentMap(
//         InputType.splitInterval(from: firstValue, to: lastValue, nParts: nParts)
//     ) { interval async -> OutputType in
//         let result = await InputType.integrate( getValue,
//             from: interval.from,
//             to: interval.to,
//             precision: nIntervals / nParts + 1,
//             kind: kind
//         )
//         return result
//     }
    
//     return results.reduce(0, +)
// }

public func sample<InputType: Randomizable, OutputType: Numeric>(
    _ getProbability: @escaping (InputType) -> OutputType, _ nSamples: Int, nParts: Int,
    from: InputType, to: InputType, precision: Int = 10000, kind: IntegralKind = .right, generatorKind: GeneratorKind = .ceil
) async -> [InputType] where InputType == InputType.SampledValueType, OutputType == InputType.ProbabilityType {
    assert(nParts > 1)
    
    var inputs = [Int]()
    let nSamplesPerPart = nSamples / nParts
    for _ in 0..<nParts - 1 {
        inputs.append(nSamplesPerPart)
    }
    inputs.append(nSamplesPerPart + (nSamples - nSamplesPerPart * nParts))

    return Array.chain(
        await concurrentMap(
            inputs
        ) { (nSamples: Int) in
            var result = [InputType]()
            for _ in 0...nSamples {
                result.append(
                    await InputType.random(
                        getProbability,
                        from: from,
                        to: to,
                        precision: precision,
                        kind: kind,
                        generatorKind: generatorKind
                    )
                )
            }
            return result
            // (0..<nSamples).map{x in
            //     return await InputType.random(
            //         getProbability,
            //         from: from,
            //         to: to,
            //         precision: precision,
            //         kind: kind,
            //         generatorKind: generatorKind
            //     )
            // }
        }
    )
}