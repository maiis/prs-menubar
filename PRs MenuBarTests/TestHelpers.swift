import Foundation
@testable import PRs_MenuBar

enum TestHelpers {
    /// Clean up all UserDefaults keys used in tests
    /// Call this in each test suite's init() method
    static func cleanupUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: UserDefaults.refreshIntervalKey)
        defaults.removeObject(forKey: UserDefaults.sortNewestFirstKey)
        defaults.removeObject(forKey: UserDefaults.filterDraftsKey)
        defaults.removeObject(forKey: UserDefaults.groupByRepoKey)
        defaults.removeObject(forKey: UserDefaults.demoModeKey)
        defaults.removeObject(forKey: UserDefaults.excludedLabelsKey)
    }
}
