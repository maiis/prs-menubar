import Foundation
import Testing
@testable import PRs_MenuBar

@Suite(.serialized)
struct UserDefaultsTests {

    init() {
        TestHelpers.cleanupUserDefaults()
    }

    @Test func refreshIntervalDefaultValue() {
        let defaults = UserDefaults.standard
        #expect(defaults.refreshInterval == 600.0)
    }

    @Test func sortNewestFirstDefaultValue() {
        let defaults = UserDefaults.standard
        #expect(defaults.sortNewestFirst)
    }

    @Test func filterDraftsDefaultValue() {
        let defaults = UserDefaults.standard
        #expect(!defaults.filterDrafts)
    }

    @Test func groupByRepoDefaultValue() {
        let defaults = UserDefaults.standard
        #expect(!defaults.groupByRepo)
    }

    @Test func refreshIntervalSetAndGet() {
        let defaults = UserDefaults.standard
        defaults.refreshInterval = 300.0
        #expect(defaults.refreshInterval == 300.0)
    }

    @Test func sortNewestFirstSetAndGet() {
        let defaults = UserDefaults.standard
        defaults.sortNewestFirst = false
        #expect(!defaults.sortNewestFirst)
    }

    @Test func filterDraftsSetAndGet() {
        let defaults = UserDefaults.standard
        defaults.filterDrafts = true
        #expect(defaults.filterDrafts)
    }

    @Test func groupByRepoSetAndGet() {
        let defaults = UserDefaults.standard
        defaults.groupByRepo = true
        #expect(defaults.groupByRepo)
    }
}
