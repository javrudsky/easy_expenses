//
//  TransactionTypeToggle.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 25/09/2026.
//

import Foundation
import SwiftUI

struct TransactionTypeToggle: View {
    @Binding var type: TransactionType

    private let inactiveCircleGray = Color.gray.opacity(0.35) // mid–dark gray for inactive icon bg

    var body: some View {
        HStack(spacing: 0) {
            Button {
                type = .expense
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, type == .expense ? .red : inactiveCircleGray)
                    Text("Expense")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(type == .expense ? Color.red.opacity(0.15) : Color.clear)
                .foregroundStyle(type == .expense ? .red : .secondary)
            }
            .buttonStyle(.plain)

            Button {
                type = .income
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, type == .income ? .green : inactiveCircleGray)
                    Text("Income")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(type == .income ? Color.green.opacity(0.15) : Color.clear)
                .foregroundStyle(type == .income ? .green : .secondary)
            }
            .buttonStyle(.plain)
        }
        .background(.thinMaterial) // or Color(.systemBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.15), value: type)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Transaction type")
        .accessibilityValue(type == .expense ? "Expense" : "Income")
    }
}

#Preview("TransactionTypeToggle") {
    @Previewable @State var type: TransactionType = .expense
    return VStack {
        TransactionTypeToggle(type: $type)
            .padding()
    }
}
