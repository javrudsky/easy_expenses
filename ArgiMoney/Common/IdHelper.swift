//
//  IdHelper.swift
//  ArgiMoney
//
//  Created by Javier Avrudsky on 12/11/2026.
//

import Foundation
import CryptoKit

struct IdHelper {
    // MARK: - Deterministic IDs

    static func categoryKey(name: String, type: TransactionType) -> String {
        "\(name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())|\(type.rawValue)"
    }

    static func accountKey(name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// Stable category ID derived from the normalized name and transaction type.
    static func categoryId(name: String, type: TransactionType) -> UUID {
        deterministicID(namespace: "argi.category", values: [categoryKey(name: name, type: type)])
    }

    /// Stable account ID derived from the normalized name.
    static func accountId(name: String) -> UUID {
        deterministicID(namespace: "argi.account", values: [accountKey(name: name)])
    }

    static func deterministicID(namespace: String, values: [String]) -> UUID {
        let input = ([namespace] + values).joined(separator: "|")
        let digest = SHA256.hash(data: Data(input.utf8))
        var bytes = Array(digest.prefix(16))

        // Mark the value as a name-based (version 5) UUID with the RFC 4122 variant.
        bytes[6] = (bytes[6] & 0x0F) | 0x50
        bytes[8] = (bytes[8] & 0x3F) | 0x80

        return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3],
                           bytes[4], bytes[5], bytes[6], bytes[7],
                           bytes[8], bytes[9], bytes[10], bytes[11],
                           bytes[12], bytes[13], bytes[14], bytes[15]))
    }
}
