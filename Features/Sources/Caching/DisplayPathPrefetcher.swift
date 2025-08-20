//  DisplayPathPrefetcher.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 8/19/25.
//

import Foundation
import CoreLocation

/// Prefetches small DISPLAY polylines to keep swipes hitch-free.
///
/// Usage:
///   let prefetcher = DisplayPathPrefetcher(store: store)
///   prefetcher.loadCurrentAndPrefetch(ids: pageIDs, index: i) { coords in
///       // render current
///   }
///   // on selection change:
///   prefetcher.loadCurrentAndPrefetch(ids: pageIDs, index: newIndex, neighborRadius: 1) { ... }
///
/// Threading: IO/decoding on a background queue; callbacks dispatched to main.
final class DisplayPathPrefetcher {
    // MARK: - Public API

    init(store: TripStoreSQLite, cacheCapacity: Int = 32) {
        self.store = store
        self.cache = LRU(capacity: max(8, cacheCapacity))
    }

    /// Cancel any in-flight work (e.g., when list is replaced).
    func cancel() { generation &+= 1 }

    /// Ensure the current index is loaded and neighbors (±radius) are prefetched.
    /// - Parameters:
    ///   - ids: Ordered trip IDs for the current list/page.
    ///   - index: Selected index into `ids`.
    ///   - neighborRadius: How many on each side to prefetch (default 1).
    ///   - onCurrent: Called on main with the decoded DISPLAY coordinates for the current id.
    func loadCurrentAndPrefetch(ids: [String],
                                index: Int,
                                neighborRadius: Int = 1,
                                onCurrent: @escaping ([CLLocationCoordinate2D]) -> Void) {
        let gen = generation
        guard ids.indices.contains(index) else { return }
        let currentID = ids[index]

        // 1) Load current (use cache or fetch)
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

        // 2) Prefetch neighbors (±radius)
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

    // MARK: - Internals

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

// MARK: - Tiny LRU cache for decoded display paths (count-limited)
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

    // Doubly-linked list nodes
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
        // Detach
        node.prev?.next = node.next
        node.next?.prev = node.prev
        if tail === node { tail = node.prev }
        // Move to head
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
