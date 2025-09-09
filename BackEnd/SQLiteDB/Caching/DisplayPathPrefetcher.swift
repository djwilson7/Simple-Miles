import Foundation
import CoreLocation

final class DisplayPathPrefetcher {
    init(store: TripStoreSQLite, cacheCapacity: Int = 32) {
        self.store = store
        self.cache = LRU(capacity: max(8, cacheCapacity))
    }

    func cancel() { generation &+= 1 }

    func loadCurrentAndPrefetch(ids: [String],
                                index: Int,
                                neighborRadius: Int = 1,
                                onCurrent: @escaping ([CLLocationCoordinate2D]) -> Void) {
        let gen = generation
        guard ids.indices.contains(index) else { return }
        let currentID = ids[index]

        if let cached = cache.get(currentID) {
            DispatchQueue.main.async { if gen == self.generation { onCurrent(cached) } }
        } else {
            Self.bg.async { [weak self] in
                guard let self = self else { return }
                let genLocal = gen
                let coords = (try? self.store.fetchDisplayPath(id: currentID)) ?? []
                if genLocal == self.generation { self.cache.set(currentID, value: coords) }
                DispatchQueue.main.async { if genLocal == self.generation { onCurrent(coords) } }
            }
        }

        guard neighborRadius > 0 else { return }
        let neighbors = neighborIDs(around: index, in: ids, radius: neighborRadius)
        for nid in neighbors {
            if cache.get(nid) != nil { continue }
            Self.bg.async { [weak self] in
                guard let self = self else { return }
                let genLocal = gen
                if genLocal != self.generation { return }
                let coords = (try? self.store.fetchDisplayPath(id: nid)) ?? []
                if genLocal == self.generation { self.cache.set(nid, value: coords) }
            }
        }
    }

    private let store: TripStoreSQLite
    private var generation: Int = 0
    private let cache: LRU<String, [CLLocationCoordinate2D]>
    private static let bg = DispatchQueue(label: "com.simplemiles.prefetch", qos: .utility)

    private func neighborIDs(around index: Int, in ids: [String], radius: Int) -> [String] {
        var out: [String] = []
        let lower = max(0, index - radius)
        let upper = min(ids.count - 1, index + radius)
        for i in lower...upper where i != index { out.append(ids[i]) }
        return out
        }
}

private final class LRU<Key: Hashable, Value> {
    private let capacity: Int
    private var dict: [Key: Node] = [:]
    private var head: Node? = nil
    private var tail: Node? = nil

    init(capacity: Int) { self.capacity = capacity }

    func get(_ key: Key) -> Value? {
        guard let node = dict[key] else { return nil }
        moveToHead(node)
        return node.value
    }

    func set(_ key: Key, value: Value) {
        if let node = dict[key] {
            node.value = value
            moveToHead(node)
        } else {
            let node = Node(key: key, value: value)
            dict[key] = node
            addToHead(node)
            if dict.count > capacity { removeTailIfNeeded() }
        }
    }

    private final class Node {
        let key: Key
        var value: Value
        var prev: Node?
        var next: Node?
        init(key: Key, value: Value) { self.key = key; self.value = value }
    }

    private func addToHead(_ node: Node) {
        node.prev = nil
        node.next = head
        head?.prev = node
        head = node
        if tail == nil { tail = node }
    }

    private func moveToHead(_ node: Node) {
        guard head !== node else { return }
        node.prev?.next = node.next
        node.next?.prev = node.prev
        if tail === node { tail = node.prev }
        node.prev = nil
        node.next = head
        head?.prev = node
        head = node
    }

    private func removeTailIfNeeded() {
        guard let t = tail else { return }
        dict.removeValue(forKey: t.key)
        tail = t.prev
        tail?.next = nil
        if head === t { head = nil }
    }
}
