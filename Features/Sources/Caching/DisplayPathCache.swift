//
//  DisplayPathCache.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 8/19/25.
//


//
//  DisplayPathCache.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 8/19/25.
//

import Foundation
import CoreLocation

/// Count-limited LRU cache for decoded DISPLAY polylines (by tripID).
/// Thread-safe via a private serial queue; main-safe to call from VMs.
final class DisplayPathCache {
    typealias Key = String
    typealias Value = [CLLocationCoordinate2D]

    private let capacity: Int
    private var dict: [Key: Node] = [:]
    private var head: Node? = nil
    private var tail: Node? = nil
    private let q = DispatchQueue(label: "com.simplemiles.displaypathcache", qos: .userInitiated)

    init(capacity: Int = 32) {
        self.capacity = max(8, capacity)
    }

    /// Fetch a cached path if present; promotes it to MRU.
    func get(_ key: Key) -> Value? {
        return q.sync {
            guard let node = dict[key] else { return nil }
            moveToHead(node)
            return node.value
        }
    }

    /// Insert or update a cached path; evicts LRU when over capacity.
    func set(_ key: Key, value: Value) {
        q.sync {
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
    }

    /// Remove a single key from the cache.
    func remove(_ key: Key) {
        q.sync {
            guard let node = dict.removeValue(forKey: key) else { return }
            detach(node)
        }
    }

    /// Clear all cached items.
    func removeAll() {
        q.sync {
            dict.removeAll(keepingCapacity: false)
            head = nil
            tail = nil
        }
    }

    // MARK: - Doubly-linked list internals

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
        detach(node)
        addToHead(node)
    }

    private func detach(_ node: Node) {
        let p = node.prev
        let n = node.next
        p?.next = n
        n?.prev = p
        if tail === node { tail = p }
        if head === node { head = n }
        node.prev = nil
        node.next = nil
    }

    private func removeTailIfNeeded() {
        guard let t = tail else { return }
        dict.removeValue(forKey: t.key)
        detach(t)
    }
}
