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

public typealias Interval = (from: Double, to: Double)

public func splitInterval(from firstValue: Double, to lastValue: Double, nParts: Int) -> Array<Interval> {
    let step = (lastValue - firstValue) / Double(nParts)
    var results = [Interval]()
    var currentValue = firstValue

    for _ in 0..<nParts {
        let nextValue = currentValue + step
        results.append(Interval(from: currentValue, to: nextValue))
        currentValue = nextValue
    }

    return results
}
