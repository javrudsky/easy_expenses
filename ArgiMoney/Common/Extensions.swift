//
//  Extensions.swift
//  ArgiMoney
//
//  Created by Javier Avrudsky on 21/10/2026.
//

import Foundation

extension Date {
    var uiFormat: String {
        return self.formatted(
            .dateTime
                .day(.twoDigits)
                .month(.abbreviated)
                .year(.extended())
        )
    }

}
