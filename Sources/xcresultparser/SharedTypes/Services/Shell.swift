//
//  Shell.swift
//
//
//  Created by Alex da Franca on 03.04.22.
//

import Foundation
import Subprocess
import System

protocol Commandline: Sendable {
    /// Runs the program and returns its standard output.
    ///
    /// If the calling task is cancelled, the program is sent `SIGTERM` (and `SIGKILL` if it
    /// doesn't exit in time), and the call throws `CancellationError`.
    func execute(program: String, with arguments: [String], at executionPath: URL?) async throws -> Data
}

extension Commandline {
    func execute(program: String, with arguments: [String]) async throws -> Data {
        try await execute(program: program, with: arguments, at: nil)
    }
}

struct Shell: Commandline {
    /// How long a program gets to exit after `SIGTERM` before it is killed.
    private static let gracefulShutDownDuration: Duration = .seconds(5)

    func execute(
        program: String,
        with arguments: [String],
        at executionPath: URL? = nil
    ) async throws -> Data {
        try Task.checkCancellation()
        var platformOptions = PlatformOptions()
        platformOptions.teardownSequence = [
            .gracefulShutDown(allowedDurationToNextStep: Self.gracefulShutDownDuration)
        ]
        let result: ExecutionResult<Void, DataOutput, StringOutput<UTF8>>
        do {
            // Standard output and standard error are read concurrently, so a program that writes a
            // lot to either one can't block on a full pipe.
            result = try await run(
                .path(FilePath(program)),
                arguments: Arguments(arguments),
                workingDirectory: executionPath.map { FilePath($0.path) },
                platformOptions: platformOptions,
                output: .data(limit: .max),
                error: .string(limit: .max)
            )
        } catch {
            try Task.checkCancellation()
            throw error
        }
        try Task.checkCancellation()
        guard result.terminationStatus.isSuccess else {
            throw CLIError.executionError(
                code: Int(result.terminationStatus.code),
                message: result.standardError
            )
        }
        return result.standardOutput
    }

    enum CLIError: Error {
        case executionError(code: Int, message: String)
    }
}

private extension TerminationStatus {
    /// The exit code, or the signal number if the program was terminated by a signal.
    var code: Code {
        switch self {
        case let .exited(code), let .signaled(code):
            code
        }
    }
}
