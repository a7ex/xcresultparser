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
}
