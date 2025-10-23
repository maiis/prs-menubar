import Foundation
import Testing
@testable import PRs_MenuBar

// MARK: - Models Tests

struct ModelsTests {

  @Test func pullRequestDecoding() async throws {
    let json = """
    {
        "id": 123,
        "number": 456,
        "title": "Test PR",
        "html_url": "https://github.com/test/repo/pull/456",
        "state": "open",
        "user": {
            "login": "testuser",
            "avatar_url": "https://example.com/avatar.png"
        },
        "created_at": "2025-01-01T00:00:00Z",
        "updated_at": "2025-01-02T00:00:00Z"
    }
    """.data(using: .utf8)!

    let decoder = JSONDecoder()
    let pr = try decoder.decode(PullRequest.self, from: json)

    #expect(pr.id == 123)
    #expect(pr.number == 456)
    #expect(pr.title == "Test PR")
    #expect(pr.htmlURL == "https://github.com/test/repo/pull/456")
    #expect(pr.state == "open")
    #expect(pr.user.login == "testuser")
    #expect(pr.repositoryName == "test/repo")
    #expect(pr.updatedDate != nil)
    #expect(pr.truncatedTitle == "Test PR")
  }

  @Test func pullRequestTitleTruncation() async throws {
    let shortPR = PullRequest(
      id: 1,
      number: 1,
      title: "Short title",
      htmlURL: "https://github.com/test/repo/pull/1",
      state: "open",
      user: User(login: "test", avatarURL: "https://example.com/avatar.png"),
      createdAt: "2025-01-01T00:00:00Z",
      updatedAt: "2025-01-01T00:00:00Z"
    )
    #expect(shortPR.truncatedTitle == "Short title")

    let longPR = PullRequest(
      id: 2,
      number: 2,
      title: "This is a very long pull request title that exceeds thirty-five characters",
      htmlURL: "https://github.com/test/repo/pull/2",
      state: "open",
      user: User(login: "test", avatarURL: "https://example.com/avatar.png"),
      createdAt: "2025-01-01T00:00:00Z",
      updatedAt: "2025-01-01T00:00:00Z"
    )
    #expect(longPR.truncatedTitle == "This is a very long pull request ti…")
  }

  @Test func repositoryNameInvalidURL() async throws {
    let pr = PullRequest(
      id: 99,
      number: 99,
      title: "Bad URL PR",
      htmlURL: "not-a-url",
      state: "open",
      user: User(login: "u", avatarURL: "https://example.com/a.png"),
      createdAt: "2025-01-01T00:00:00Z",
      updatedAt: "2025-01-01T00:00:00Z"
    )
    #expect(pr.repositoryName == "")
  }
}

// MARK: - Mock GitHubService

final class MockGitHubService: GitHubServiceProtocol {
  let mockPRs: [PullRequest]
  let shouldThrowError: Bool

  init(mockPRs: [PullRequest] = [], shouldThrowError: Bool = false) {
    self.mockPRs = mockPRs
    self.shouldThrowError = shouldThrowError
  }

  func fetchReviewRequestedPRs() async throws -> [PullRequest] {
    if shouldThrowError {
      throw GitHubError.invalidResponse
    }
    return mockPRs
  }
}

extension MockGitHubService: Sendable {}

// MARK: - AppState Tests

@MainActor
struct AppStateTests {

  @Test func initialState() async throws {
    let mockService = MockGitHubService(mockPRs: [])
    let appState = AppState(githubService: mockService)

    #expect(appState.prs.isEmpty)
    #expect(appState.prCount == 0)
    #expect(appState.isRefreshing == false)
    #expect(appState.lastError == nil)
    #expect(appState.lastUpdated == nil)
  }

  @Test func prCountComputedProperty() async throws {
    let mockPRs = [
      PullRequest(
        id: 1,
        number: 100,
        title: "Test PR 1",
        htmlURL: "https://github.com/test/repo/pull/100",
        state: "open",
        user: User(login: "testuser", avatarURL: "https://example.com/avatar.png"),
        createdAt: "2025-01-01T00:00:00Z",
        updatedAt: "2025-01-02T00:00:00Z"
      ),
      PullRequest(
        id: 2,
        number: 200,
        title: "Test PR 2",
        htmlURL: "https://github.com/test/repo/pull/200",
        state: "open",
        user: User(login: "testuser2", avatarURL: "https://example.com/avatar2.png"),
        createdAt: "2025-01-01T00:00:00Z",
        updatedAt: "2025-01-02T00:00:00Z"
      )
    ]

    let mockService = MockGitHubService(mockPRs: mockPRs)
    let appState = AppState(githubService: mockService)

    await appState.refreshPRCount()

    #expect(appState.prCount == 2)
    #expect(appState.prs.count == 2)
  }
}
