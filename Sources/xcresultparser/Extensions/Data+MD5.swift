//
//  Data+MD5.swift
//
//  Created by Alex da Franca on 22.05.24.
//

import Foundation
import CryptoKit

extension Data {
    func md5() -> String {
        let digest = Insecure.MD5.hash(data: self)
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}
