//
//  String+MD5.swift
//
//  Created by Alex da Franca on 22.05.24.
//

import CryptoKit
import Foundation

extension String {
    func md5() -> String {
        return Data(utf8).md5()
    }

    func sha256() -> String {
        let digest = SHA256.hash(data: Data(utf8))
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}
