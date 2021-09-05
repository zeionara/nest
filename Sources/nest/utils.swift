import Foundation

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
