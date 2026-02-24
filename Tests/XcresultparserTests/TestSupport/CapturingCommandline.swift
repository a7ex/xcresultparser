import Foundation
@testable import XcresultparserLib

final class CapturingCommandline: Commandline {
    let response: Data
    let error: Error?
    var lastProgram: String = ""
    var lastArguments: [String] = []

    init(response: Data, error: Error? = nil) {
        self.response = response
        self.error = error
    }

    func execute(program: String, with arguments: [String], at executionPath: URL?) throws -> Data {
        lastProgram = program
        lastArguments = arguments
        if let error {
            throw error
        }
        return response
    }
}
