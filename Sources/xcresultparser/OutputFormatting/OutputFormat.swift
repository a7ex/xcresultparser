//
//  OutputFormat.swift
//  xcresult2text
//
//  Created by Alex da Franca on 03.06.21.
//

import Foundation

public enum OutputFormat: String {
    case txt, cli, html, xml, cobertura, md
    
    public init(string: String?) {
        if let input = string?.lowercased(),
           let fmt = OutputFormat(rawValue: input) {
            self = fmt
        } else {
            self = .cli
        }
    }
}
