import Foundation

extension UserDefaults {
    static let demoModeKey = "isDemoMode"
    static let refreshIntervalKey = "refreshInterval"
    static let sortNewestFirstKey = "sortNewestFirst"
    static let filterDraftsKey = "filterDrafts"
    static let groupByRepoKey = "groupByRepo"
    static let excludedLabelsKey = "excludedLabels"

    var isDemoMode: Bool {
        get { bool(forKey: Self.demoModeKey) }
        set { set(newValue, forKey: Self.demoModeKey) }
    }

    var refreshInterval: TimeInterval {
        get {
            let value = double(forKey: Self.refreshIntervalKey)
            return value > 0 ? value : 600 // Default to 10 minutes
        }
        set { set(newValue, forKey: Self.refreshIntervalKey) }
    }

    var sortNewestFirst: Bool {
        get {
            object(forKey: Self.sortNewestFirstKey) as? Bool ?? true // Default to newest first
        }
        set { set(newValue, forKey: Self.sortNewestFirstKey) }
    }

    var filterDrafts: Bool {
        get { bool(forKey: Self.filterDraftsKey) }
        set { set(newValue, forKey: Self.filterDraftsKey) }
    }

    var groupByRepo: Bool {
        get { bool(forKey: Self.groupByRepoKey) }
        set { set(newValue, forKey: Self.groupByRepoKey) }
    }

    var excludedLabels: String {
        get { string(forKey: Self.excludedLabelsKey) ?? "" }
        set { set(newValue, forKey: Self.excludedLabelsKey) }
    }
}
