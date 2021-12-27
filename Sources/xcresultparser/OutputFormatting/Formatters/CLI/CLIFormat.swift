//
//  CLIFormat.swift
//  xcresult2text
//
//  Created by Alex da Franca on 01.06.21.
//

import Foundation

struct CLIFormat {
    let reset  = "\u{001B}[0m"
    
    let red    = "\u{001B}[31m"
    let green  = "\u{001B}[32m"
    let yellow = "\u{001B}[33m"
    
    let bold   = "\u{001B}[1m"
    let italic = "\u{001B}[3m"
    let underline = "\u{001B}[4m"
    
    // // Colors:
    // // Foreground color
    //    Black    30
    //    Red      31
    //    Green    32
    //    Yellow   33
    //    Blue     34
    //    Magenta  35
    //    Cyan     36
    //    White    37
    // // Background color
    //    black    40
    //    red      41
    //    green    42
    //    yellow   43
    //    blue     44
    //    magenta  45
    //    cyan     46
    //    white    47
    
    // // Format:
    //    Normal     0 (Default Terminal colors)
    //    Bold       1
    //    Dim        2
    //    Italic     3
    //    Underline  4
    //    Flash      5
    
}
