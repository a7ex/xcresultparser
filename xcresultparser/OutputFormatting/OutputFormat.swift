//
//  OutputFormat.swift
//  xcresult2text
//
//  Created by Alex da Franca on 03.06.21.
//

import Foundation

enum OutputFormat: String {
    case txt, cli, html
    
    init(string: String?) {
        if let input = string,
           let fmt = OutputFormat(rawValue: input) {
            self = fmt
        } else {
            self = .cli
        }
    }
}
