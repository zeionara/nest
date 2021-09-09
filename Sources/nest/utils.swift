import Foundation
// import PcgRandom


extension DispatchGroup {
    public func enter(_ nWorkers: Int) {
        for _ in 0..<nWorkers {
            self.enter()
        }
    }
}


actor SynchronisedCollection<Item> {
    var items = [Item]()
    
    func append(_ item: Item) {
        items.append(item)
    }
}

public func concurrentMap<InputType, OutputType>(_ inputs: Array<InputType>, handler: @escaping (InputType) -> OutputType) async -> Array<OutputType> { // nWorkers: Int? = .none
    let externallyAvailableResults = SynchronisedCollection<OutputType>()

    await withTaskGroup(of: OutputType.self) { taskGroup in 
        for input in inputs {
            taskGroup.addTask {
                let result = handler(input)
                return result
            }
        }

        for await result in taskGroup {
            await externallyAvailableResults.append(result)
        }
    }

    return await externallyAvailableResults.items
}

public func concurrentMap<InputType, OutputType>(_ inputs: Array<InputType>, handler: @escaping (InputType) async -> OutputType) async -> Array<OutputType> { // nWorkers: Int? = .none
    let externallyAvailableResults = SynchronisedCollection<OutputType>()

    await withTaskGroup(of: OutputType.self) { taskGroup in 
        for input in inputs {
            taskGroup.addTask {
                let result = await handler(input)
                return result
            }
        }

        for await result in taskGroup {
            await externallyAvailableResults.append(result)
        }
    }

    return await externallyAvailableResults.items
}

public extension Array {
    static func chain(_ arrays: [[Element]]) -> [Element] {
        var chained = [Element]()
        
        for array in arrays {
            for item in array {
                chained.append(item)
            }
        }

        return chained
    }
}


// public func tryInitializeGenerator<InputGeneratorType: RandomNumberGenerator>(
//     _ generator: InputGeneratorType? = nil, seed: Int? = nil
// ) -> RandomNumberGenerator? {
//     if let _ = generator {
//         return generator
//     }
//     if let unwrappedSeed = seed {
//         return Pcg64Random(seed: UInt64(unwrappedSeed))
//     }
//     return nil
// }

// public func tryInitializeGenerator<InputGeneratorType: RandomNumberGenerator>(
//     _ generator: InputGeneratorType? = nil, seed: Int? = nil
// ) -> RandomNumberGenerator? {
//     if let _ = generator {
//         return generator
//     }
//     if let unwrappedSeed = seed {
//         return Pcg64Random(seed: UInt64(unwrappedSeed))
//     }
//     return nil
// }

// public struct GeneratorWrapper<GeneratorType: RandomNumberGenerator> {
//     public let generator: GeneratorType
// }

// public func tryInitializeGenerator<InputGeneratorType: RandomNumberGenerator>(
//     _ generator: InputGeneratorType? = nil, seed: Int? = nil
// ) -> GeneratorWrapper? {
//     if let _ = generator {
//         return GeneratorWrapper(generator: generator)
//     }
//     if let unwrappedSeed = seed {
//         return GeneratorWrapper(generator: Pcg64Random(seed: UInt64(unwrappedSeed)))
//     }
//     return nil
// }
