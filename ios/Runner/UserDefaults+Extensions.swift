//
//  UserDefaults+Extensions.swift
//  Runner
//
//  Created by Jay Zisch on 2026/04/21.
//
import Foundation

extension UserDefaults {
    static let jsxAppGroup: UserDefaults = .init(suiteName: Constants.appGroupID)!
}
