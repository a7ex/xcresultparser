//
//  ConcurrentToolCalls.swift
//  Xcresultparser
//

extension Result where Failure == any Error {
    #if compiler(<6.4)
    /// Runs `body` and captures its value or error, so concurrent tool calls can all finish before any is retried.
    init(catching body: () async throws -> Success) async {
        do {
            self = .success(try await body())
        } catch {
            self = .failure(error)
        }
    }
    #endif

    /// The value, or the result of running `body` again if this attempt failed.
    ///
    /// xcresulttool upgrades a bundle written by an older Xcode the first time it reads it, and only one of
    /// several concurrent first reads succeeds. Once they have all finished the bundle is upgraded, so a
    /// call that failed is run again on its own.
    func valueOrRetrying(_ body: () async throws -> Success) async throws -> Success {
        switch self {
        case let .success(value):
            value
        case .failure:
            try await body()
        }
    }
}
