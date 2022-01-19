//
//  CLConfiguration.swift
//  Launcher
//
//  Created by Kai on 1/19/22.
//

import Foundation


enum CLConfiguration {
    enum Error: Swift.Error {
        case missingKey, invalidValue
    }

    private static func value<T>(for key: String) throws -> T where T: LosslessStringConvertible {
        guard let object = Bundle.main.object(forInfoDictionaryKey:key) else {
            throw Error.missingKey
        }

        switch object {
        case let value as T:
            return value
        case let string as String:
            guard let value = T(string) else { fallthrough }
            return value
        default:
            throw Error.invalidValue
        }
    }

    static var bundlePrefix: String {
        let prefix: String
        do {
            prefix = try Self.value(for: "ORGANIZATION_IDENTIFIER_PREFIX")
        } catch {
            prefix = ""
        }
        return prefix
    }
}
