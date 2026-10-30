//
//  TransactionGrouping.swift
//  ArgiMoney
//
//  Created by Javier Avrudsky on 29/10/2026.
//

import Foundation
import SwiftUI

enum TransactionGrouping: String, CaseIterable, Identifiable {
    case day
    case month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .day: "By day"
        case .month: "By month"
        }
    }
}
