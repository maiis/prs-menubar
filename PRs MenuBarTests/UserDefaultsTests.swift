import Foundation
import Testing
@testable import PRs_MenuBar

@Suite(.serialized)
struct UserDefaultsTests {

    init() {
        TestHelpers.cleanupUserDefaults()
    }

    @Test func refreshIntervalDefaultValue() async throws {
        let defaults = UserDefaults.standard
        #expect(defaults.refreshInterval == 600.0)
    }

    @Test func sortNewestFirstDefaultValue() async throws {
        let defaults = UserDefaults.standard
        #expect(defaults.sortNewestFirst == true)
    }

    @Test func filterDraftsDefaultValue() async throws {
        let defaults = UserDefaults.standard
        #expect(defaults.filterDrafts == false)
    }

    @Test func groupByRepoDefaultValue() async throws {
        let defaults = UserDefaults.standard
        #expect(defaults.groupByRepo == false)
    }

    @Test func refreshIntervalSetAndGet() async throws {
        let defaults = UserDefaults.standard
        defaults.refreshInterval = 300.0
        #expect(defaults.refreshInterval == 300.0)
    }

    @Test func sortNewestFirstSetAndGet() async throws {
        let defaults = UserDefaults.standard
        defaults.sortNewestFirst = false
        #expect(defaults.sortNewestFirst == false)
    }

    @Test func filterDraftsSetAndGet() async throws {
        let defaults = UserDefaults.standard
        defaults.filterDrafts = true
        #expect(defaults.filterDrafts == true)
    }

    @Test func groupByRepoSetAndGet() async throws {
        let defaults = UserDefaults.standard
        defaults.groupByRepo = true
        #expect(defaults.groupByRepo == true)
    }
}
