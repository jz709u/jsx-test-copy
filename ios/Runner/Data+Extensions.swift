//
//  Data+Extensions.swift
//  Runner
//
//  Created by Jay Zisch on 2026/04/22.
//
import Foundation

extension Data {
    func asHex() -> String {
        map { String(format: "%02x", $0) }.joined()
    }
}
