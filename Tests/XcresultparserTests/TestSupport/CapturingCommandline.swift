import Foundation
@testable import XcresultparserLib

actor CapturingCommandline: Commandline {
    let response: Data
    let error: (any Error)?
    private(set) var lastProgram = ""
    private(set) var lastArguments: [String] = []

    init(response: Data, error: (any Error)? = nil) {
        self.response = response
        self.error = error
    }

    func execute(program: String, with arguments: [String], at executionPath: URL?) async throws -> Data {
        lastProgram = program
        lastArguments = arguments
        if let error {
            throw error
        }
        return response
    }
}
