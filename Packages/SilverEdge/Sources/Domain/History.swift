/// The last `capacity` values, oldest first. A ring: appending never reallocates once full.
package struct History<Element: Sendable>: Sendable {
    package let capacity: Int
    private var storage: [Element] = []
    private var start = 0

    package init(capacity: Int) {
        self.capacity = capacity
        storage.reserveCapacity(capacity)
    }

    package mutating func append(_ element: Element) {
        if storage.count < capacity {
            storage.append(element)
        } else {
            storage[start] = element
            start = (start + 1) % capacity
        }
    }

    package var values: [Element] {
        Array(storage[start...] + storage[..<start])
    }
}
