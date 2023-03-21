struct Heap<Element: Comparable> {
    private var storage: [Element]
    private static var root: Array.Index { 0 }
    private static var leftMax: Array.Index { 1 }
    private static var rightMax: Array.Index { 2 }
    
    var isEmpty: Bool { storage.isEmpty }
    
    var count: Int { storage.count }
    
    var unordered: [Element] { storage }
    
    init() {
        storage = []
    }
    
    init<S: Sequence>(_ elements: S) where S.Element == Element {
        storage = Array(elements)
        
        for index in (0 ..< storage.count).reversed() {
            trickleDown(index)
        }
    }
    
    mutating func insert(_ element: Element) {
        storage.append(element)
        bubbleUp(storage.count - 1)
    }
    
    mutating func insert<S: Sequence>(contentsOf newElements: S) where S.Element == Element {
        guard !storage.isEmpty else {
            self = Self(newElements)
            return
        }
        
        newElements.forEach { insert($0) }
    }
    
    func min() -> Element? { storage.first }
    
    func max() -> Element? {
        guard storage.count > 2 else { return storage.last }
        
        return Swift.max(storage[Heap.leftMax], storage[Heap.rightMax])
    }
    
    mutating func popMin() -> Element? {
        guard var removed = storage.popLast() else { return nil }
        
        if !storage.isEmpty {
            swap(&storage[Heap.root], &removed)
            trickleDown(Heap.root)
        }
        
        return removed
    }
    
    mutating func popMax() -> Element? {
        guard var removed = storage.popLast() else { return nil }
        
        if storage.count == 2 {
            if storage[Heap.leftMax] > removed {
                swap(&storage[Heap.leftMax], &removed)
            }
        } else if storage.count > 2 {
            let max = storage[Heap.leftMax] >= storage[Heap.rightMax] ? Heap.leftMax : Heap.rightMax
            swap(&storage[max], &removed)
            trickleDown(max)
        }
        
        return removed
    }
    
    mutating func replaceMin(with replacement: Element) -> Element? {
        guard !storage.isEmpty else { return nil }
        
        var removed = replacement
        swap(&storage[Heap.root], &removed)
        trickleDown(Heap.root)
        
        return removed
    }
    
    mutating func replaceMax(with replacement: Element) -> Element? {
        guard !storage.isEmpty else { return nil }
        
        var removed = replacement
        
        if storage.count == 1 {
            swap(&storage[Heap.root], &removed)
        } else if storage.count == 2 {
            swap(&storage[Heap.leftMax], &removed)
            bubbleUp(Heap.leftMax)
        } else if storage.count > 2 {
            let max = storage[Heap.leftMax] >= storage[Heap.rightMax] ? Heap.leftMax : Heap.rightMax
            swap(&storage[max], &removed)
            bubbleUp(max)
            trickleDown(max)
        }
        
        return removed
    }
    
    private mutating func bubbleUp(_ index: Array.Index) {
        guard let parent = parent(of: index) else { return }
        
        if isMinLevel(forIndex: index) {
            if storage[index] > storage[parent] {
                storage.swapAt(index, parent)
                bubbleUp(parent, by: >)
            } else {
                bubbleUp(index, by: <)
            }
        } else {
            if storage[index] < storage[parent] {
                storage.swapAt(index, parent)
                bubbleUp(parent, by: <)
            } else {
                bubbleUp(index, by: >)
            }
        }
    }
    
    private mutating func bubbleUp(_ index: Array.Index,
                                   by areInIncreasingOrder: (Element, Element) -> Bool) {
        var index = index
        while let grandparent = grandparent(of: index),
              areInIncreasingOrder(storage[index], storage[grandparent]) {
            storage.swapAt(index, grandparent)
            index = grandparent
        }
    }
    
    private mutating func trickleDown(_ index: Array.Index) {
        if isMinLevel(forIndex: index) {
            trickleDown(index, by: <)
        } else {
            trickleDown(index, by: >)
        }
    }
    
    private mutating func trickleDown(_ index: Array.Index,
                                      by areInIncreasingOrder: (Element, Element) -> Bool) {
        var index = index
        while let minDescendant = minDescendant(of: index, by: areInIncreasingOrder),
              areInIncreasingOrder(storage[minDescendant], storage[index]) {
            storage.swapAt(minDescendant, index)
            guard firstGrandchild(of: index) <= minDescendant,
                  minDescendant <= lastGrandchild(of: index) else { break }
            
            if let parent = parent(of: minDescendant),
               areInIncreasingOrder(storage[parent], storage[minDescendant]) {
                storage.swapAt(minDescendant, parent)
            }
            
            index = minDescendant
        }
    }
    
    private func isMinLevel(forIndex index: Array.Index) -> Bool {
        let level = Int(log2(Float(index + 1)))
        return level % 2 == 0
    }
    
    private func parent(of index: Array.Index) -> Array.Index? {
        guard index > 0 else { return nil }
        
        return (index - 1) / 2
    }
    
    private func grandparent(of index: Array.Index) -> Array.Index? {
        guard index > 2 else { return nil }
        
        return (index - 3) / 4
    }
    
    private func firstGrandchild(of index: Array.Index) -> Array.Index {
        return index * 4 + 3
    }
    
    private func lastGrandchild(of index: Array.Index) -> Array.Index {
        return index * 4 + 6
    }
    
    private func minDescendant(of index: Array.Index,
                               by areInIncreasingOrder: (Element, Element) -> Bool) -> Array.Index? {
        let leftChild = index * 2 + 1
        guard leftChild < storage.count else { return nil }
        
        let rightChild = index * 2 + 2
        guard rightChild < storage.count else { return leftChild }
        
        var minDescendant = areInIncreasingOrder(storage[rightChild], storage[leftChild]) ? rightChild : leftChild
        for grandchild in firstGrandchild(of: index)...lastGrandchild(of: index) where grandchild < storage.count {
            if areInIncreasingOrder(storage[grandchild], storage[minDescendant]) {
                minDescendant = grandchild
            }
        }
        
        return minDescendant
    }
}

extension Heap: ExpressibleByArrayLiteral {
    init(arrayLiteral elements: Element...) {
        self.init(elements)
    }
}
