//
//  Data+MD5.swift
//
//  Created by Alex da Franca on 22.05.24.
//

import CryptoKit
import Foundation

extension Data {
    func md5() -> String {
        let digest = Insecure.MD5.hash(data: self)
        return digest.hexString
    }
}

extension Sequence<UInt8> {
    /// The bytes as lowercase hexadecimal, two digits per byte.
    ///
    /// Neither Foundation nor CryptoKit has public API for this, and `String(format:)` is unsafe under strict
    /// memory safety.
    var hexString: String {
        let digits = Array("0123456789abcdef")
        var result = ""
        for byte in self {
            result.append(digits[Int(byte >> 4)])
            result.append(digits[Int(byte & 0x0F)])
        }
        return result
    }
}
