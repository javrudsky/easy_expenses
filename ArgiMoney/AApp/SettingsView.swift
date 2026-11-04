//
//  SettingsView.swift
//  ArgiMoney
//
//  Created by Javier Avrudsky on 04/11/2026.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    @AppStorage("transactionGrouping")
    private var transactionGrouping: TransactionGrouping = .day
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Transactions") {
                    Picker("Group transactions", selection: $transactionGrouping) {
                        ForEach(TransactionGrouping.allCases) { grouping in
                            Text(grouping.title).tag(grouping)
                        }
                    }
                }
            }
        }
        .navigationTitle("Settings")
    }
}
