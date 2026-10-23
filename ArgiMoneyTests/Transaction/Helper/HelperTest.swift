//
//  HelperTest.swift
//  ArgiMoneyTests
//
//  Created by Javier Avrudsky on 23/10/2026.
//

import Testing

struct HelperTest {

    @Test
    func printUUID() async throws {
        _ = TransactionTestsHelper.getUUIDStr("A")
        _ = TransactionTestsHelper.getUUIDStr("B")
        _ = TransactionTestsHelper.getUUIDStr("C")
    }

}
