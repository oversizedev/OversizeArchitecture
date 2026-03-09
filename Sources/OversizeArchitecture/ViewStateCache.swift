//
// Copyright © 2025 Alexander Romanov
// ViewStateCache.swift, created on 09.12.2025
//

import Foundation

@MainActor
public final class ViewStateCache {
    public static let shared = ViewStateCache()
    private var cache: [String: AnyObject] = [:]

    private init() {}

    public func getOrCreate<ViewState: ViewStateProtocol>(
        key: String,
        create: () -> ViewState
    ) -> ViewState {
        if let cached = cache[key] as? ViewState {
            return cached
        }
        let newState = create()
        cache[key] = newState as AnyObject
        return newState
    }

    public func invalidate(key: String) {
        cache.removeValue(forKey: key)
    }

    public func invalidateAll() {
        cache.removeAll()
    }
}
