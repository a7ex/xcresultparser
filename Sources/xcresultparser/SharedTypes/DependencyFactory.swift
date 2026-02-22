//
//  DependencyFactory.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 01.12.24.
//

class DependencyFactory {
    static var createShell: () -> Commandline = {
        Shell()
    }

    static var createXCResultToolClient: (Commandline) -> XCResultToolProviding = { shell in
        XCResultToolClient(shell: shell)
    }

    static var createXCCovClient: (Commandline) -> XCCovProviding = { shell in
        XCCovClient(shell: shell)
    }
}
