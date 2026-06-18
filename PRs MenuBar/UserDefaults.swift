import Foundation

extension UserDefaults {
    // Immutable Sendable constants: keep them nonisolated so non-MainActor callers
    // (e.g. test helpers) can reference them under the project's MainActor-by-default isolation.
    nonisolated static let demoModeKey = "isDemoMode"
    nonisolated static let refreshIntervalKey = "refreshInterval"
    nonisolated static let sortNewestFirstKey = "sortNewestFirst"
    nonisolated static let filterDraftsKey = "filterDrafts"
    nonisolated static let groupByRepoKey = "groupByRepo"
    nonisolated static let excludedLabelsKey = "excludedLabels"

    /// UserDefaults is thread-safe, so these accessors carry no MainActor state and stay
    /// nonisolated — usable from any context despite the project's MainActor-by-default isolation.
    nonisolated var isDemoMode: Bool {
        get { bool(forKey: Self.demoModeKey) }
        set { set(newValue, forKey: Self.demoModeKey) }
    }

    nonisolated var refreshInterval: TimeInterval {
        get {
            let value = double(forKey: Self.refreshIntervalKey)
            return value > 0 ? value : 600
        }
        set { set(newValue, forKey: Self.refreshIntervalKey) }
    }

    nonisolated var sortNewestFirst: Bool {
        get {
            object(forKey: Self.sortNewestFirstKey) as? Bool ?? true
        }
        set { set(newValue, forKey: Self.sortNewestFirstKey) }
    }

    nonisolated var filterDrafts: Bool {
        get { bool(forKey: Self.filterDraftsKey) }
        set { set(newValue, forKey: Self.filterDraftsKey) }
    }

    nonisolated var groupByRepo: Bool {
        get { bool(forKey: Self.groupByRepoKey) }
        set { set(newValue, forKey: Self.groupByRepoKey) }
    }

    nonisolated var excludedLabels: String {
        get { string(forKey: Self.excludedLabelsKey) ?? "" }
        set { set(newValue, forKey: Self.excludedLabelsKey) }
    }
}
