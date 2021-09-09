import Foundation

public enum GeneratorKind {
    case ceil
    case floor
}

public protocol Randomizable {
    associatedtype SampledValueType
    associatedtype ProbabilityType

    // static func splitInterval(from firstValue: SampledValueType, to lastValue: SampledValueType, nParts: Int) -> Array<Interval<SampledValueType>>
    static func random<GeneratorType: RandomNumberGenerator>(
        _ getValue: (SampledValueType) async -> ProbabilityType, from firstValue: SampledValueType, to lastValue: SampledValueType, precision nIntervals: Int,
        kind: IntegralKind, generatorKind: GeneratorKind, generator: GeneratorType?, seed: Int?
    ) async -> SampledValueType
    static func normalizeProbability(_ probability: ProbabilityType, _ normalizationCoefficient: ProbabilityType) -> ProbabilityType
}

public func random<InputType: Numeric, OutputType: Numeric>(
    _ getProbability: (InputType) async -> OutputType,
    from firstValue: InputType,
    to lastValue: InputType,
    step: InputType,
    zero: OutputType,
    computeSquare: (OutputType, OutputType) -> OutputType,
    generate: (InputType, InputType) -> InputType,
    base baseValue: InputType,
    generatorKind: GeneratorKind,
    identity: (InputType) -> OutputType
) async -> InputType where InputType: Comparable, OutputType: Comparable {
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
        if let rightHeightUnwrapped = rightHeight {
            leftHeight = rightHeightUnwrapped
        } else {
            leftHeight = await getProbability(leftBoundary)
        }
        nextLeftBoundary = leftBoundary + step
        rightHeight = await getProbability(nextLeftBoundary)

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
    _ getProbability: (Type) async -> Type,
    from firstValue: Type,
    to lastValue: Type,
    step: Type,
    zero: Type,
    base: Type,
    generatorKind: GeneratorKind,
    computeSquare: (Type, Type) -> Type,
    generate: (Type, Type) -> Type
) async -> Type where Type: Comparable {
    return await random(
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

public func sample<InputType: Randomizable, OutputType: Numeric, GeneratorType: RandomNumberGenerator>(
    _ getProbability: @escaping (InputType) -> OutputType, _ nSamples: Int, nParts: Int,
    from: InputType, to: InputType, precision: Int = 10000, kind: IntegralKind = .right, generatorKind: GeneratorKind = .ceil,
    generator: GeneratorType? = nil, seed: Int? = nil
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
            await sample(
                getProbability,
                nSamples,
                from: from,
                to: to,
                precision: precision,
                generator: generator,
                seed: seed
            )
            // var result = [InputType]()
            // for _ in 0...nSamples {
            //     result.append(
            //         await InputType.random(
            //             getProbability,
            //             from: from,
            //             to: to,
            //             precision: precision,
            //             kind: kind,
            //             generatorKind: generatorKind
            //         )
            //     )
            // }
            // return result
        }
    )
}

public func sample<InputType: Randomizable, OutputType: Numeric, GeneratorType: RandomNumberGenerator>(
    _ getProbability: @escaping (InputType) -> OutputType, _ nSamples: Int,
    from: InputType, to: InputType, precision: Int = 10000, kind: IntegralKind = .right, generatorKind: GeneratorKind = .ceil,
    generator: GeneratorType? = nil, seed: Int? = nil
) async -> [InputType] where InputType == InputType.SampledValueType, OutputType == InputType.ProbabilityType {
    var result = [InputType]()
    for _ in 0...nSamples {
        result.append(
            await InputType.random(
                getProbability,
                from: from,
                to: to,
                precision: precision,
                kind: kind,
                generatorKind: generatorKind,
                generator: generator,
                seed: seed
            )
        )
    }
    return result
}

public func randomizeCoordinate<InputType: Randomizable, OutputType: Numeric, GeneratorType: RandomNumberGenerator>(
    _ getProbability: ([InputType]) -> OutputType,
    from firstValue: [InputType], to lastValue: [InputType], precision nIntervals: Int = 10, kind: IntegralKind = .right, generatorKind: GeneratorKind = .ceil,
    generator: GeneratorType? = nil, seed: Int? = nil
) async -> InputType where InputType: Integrable, InputType.IntervalValueType == InputType, InputType.ResultType == OutputType,
    InputType == InputType.SampledValueType, OutputType == InputType.ProbabilityType {
    if firstValue.count == 1 {
        func getValueFixed(_ x: InputType) -> OutputType {
            return getProbability([x])
        }

        return await InputType.random(
            getValueFixed,
            from: firstValue.first!,
            to: lastValue.first!,
            precision: nIntervals,
            kind: kind,
            generatorKind: generatorKind,
            generator: generator,
            seed: seed
        )
    } else {
        func getValueFixed(_ firstDimensionValue: InputType) async -> OutputType {
            func getValueOnShortenedArray(_ lastDimensionValues: [InputType]) -> OutputType {
                return getProbability([firstDimensionValue] + lastDimensionValues)
            }
            
            return await integrate(
                getValueOnShortenedArray,
                from: Array(firstValue.dropFirst()),
                to: Array(lastValue.dropFirst()),
                precision: nIntervals,
                kind: kind
            )
        }
        
        return await InputType.random(
            getValueFixed,
            from: firstValue.first!,
            to: lastValue.first!,
            precision: nIntervals,
            kind: kind,
            generatorKind: generatorKind,
            generator: generator,
            seed: seed
        )
    }
}

public func randomize<InputType: Randomizable, OutputType: Numeric, GeneratorType: RandomNumberGenerator>(
    _ getProbability: ([InputType]) -> OutputType,
    from firstValue: [InputType], to lastValue: [InputType], precision nIntervals: Int = 10, kind: IntegralKind = .right, generatorKind: GeneratorKind = .ceil,
    generator: GeneratorType? = nil, seed: Int? = nil
) async -> [InputType] where InputType: Integrable, InputType.IntervalValueType == InputType, InputType.ResultType == OutputType,
    InputType == InputType.SampledValueType, OutputType == InputType.ProbabilityType {
    var currentCoordinates = [InputType]()
    for i in 0..<firstValue.count {
        func getValueFixed(_ args: [InputType]) -> OutputType {
            return getProbability(currentCoordinates + args)
        }

        let normalizationCoefficient = await integrate(
            getValueFixed,
            from: Array(firstValue[i..<firstValue.count]),
            to: Array(lastValue[i..<firstValue.count]),
            precision: nIntervals,
            kind: kind
        )

        let newCoordinate = await randomizeCoordinate(
            { args in 
                return InputType.normalizeProbability(
                    getValueFixed(args),
                    normalizationCoefficient
                )
            },
            from: Array(firstValue[i..<firstValue.count]),
            to: Array(lastValue[i..<firstValue.count]),
            precision: nIntervals,
            kind: kind,
            generatorKind: generatorKind,
            generator: generator,
            seed: seed
        )

        currentCoordinates.append(newCoordinate)
    }

    return currentCoordinates
    
    // InputType == InputType.SampledValueType, OutputType == InputType.ProbabilityType {
    // func getValueFixed(_ firstDimensionValue: InputType) async -> OutputType {
    //     func getValueOnShortenedArray(_ lastDimensionValues: [InputType]) -> OutputType {
    //         return getProbability([firstDimensionValue] + lastDimensionValues)
    //     }
        
    //     return await integrate(
    //         getValueOnShortenedArray,
    //         from: Array(firstValue.dropFirst()),
    //         to: Array(lastValue.dropFirst()),
    //         precision: nIntervals,
    //         kind: kind
    //     )
    // }
    
    // return await InputType.random(
    //     getValueFixed,
    //     from: firstValue.first!,
    //     to: lastValue.first!,
    //     precision: nIntervals,
    //     kind: kind,
    //     generatorKind: generatorKind
    // )
}

public func sample<InputType: Randomizable, OutputType: Numeric, GeneratorType: RandomNumberGenerator>(
    _ getProbability: @escaping ([InputType]) -> OutputType, _ nSamples: Int,
    from: [InputType], to: [InputType], precision: Int = 10000, kind: IntegralKind = .right, generatorKind: GeneratorKind = .ceil,
    generator: GeneratorType? = nil, seed: Int? = nil
) async -> [[InputType]] where InputType: Integrable, InputType.IntervalValueType == InputType, InputType.ResultType == OutputType,
    InputType == InputType.SampledValueType, OutputType == InputType.ProbabilityType {
    var result = [[InputType]]()
    for i in 0..<nSamples {
        print("Generated \(i) / \(nSamples) samples")
        result.append(
            await randomize(
                getProbability,
                from: from,
                to: to,
                precision: precision,
                kind: kind,
                generatorKind: generatorKind,
                generator: generator,
                seed: seed
            )
        )
    }
    return result
}

public func sample<InputType: Randomizable, OutputType: Numeric, GeneratorType: RandomNumberGenerator>(
    _ getProbability: @escaping ([InputType]) -> OutputType, _ nSamples: Int, nParts: Int,
    from: [InputType], to: [InputType], precision: Int = 10000, kind: IntegralKind = .right, generatorKind: GeneratorKind = .ceil,
    generator: GeneratorType? = nil, seed: Int? = nil
) async -> [[InputType]] where InputType: Integrable, InputType.IntervalValueType == InputType, InputType.ResultType == OutputType,
    InputType == InputType.SampledValueType, OutputType == InputType.ProbabilityType {
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
            await sample(
                getProbability,
                nSamples,
                from: from,
                to: to,
                precision: precision,
                generator: generator,
                seed: seed
            )
        }
    )
}
