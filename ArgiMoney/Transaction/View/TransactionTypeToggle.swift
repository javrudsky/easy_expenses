//
//  TransactionTypeToggle.swift
//  ArgiMoney
//
//  Created by Javier Avrudsky on 25/09/2026.
//

import Foundation
import SwiftUI

struct TransactionTypeToggle: View {
    
    @Environment(\.theme) var theme: Theme
    
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
                        .foregroundStyle(.white, type == .expense ? theme.accentLightNegative : inactiveCircleGray)
                    Text("Expense")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(type == .expense ? theme.brandPrimary.opacity(0.15) : Color.clear)
                .foregroundStyle(type == .expense ? theme.brandPrimary : .secondary)
            }
            .buttonStyle(.plain)

            Button {
                type = .income
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, type == .income ? theme.accentLightPositive : inactiveCircleGray)
                    Text("Income")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(type == .income ? theme.brandPrimary.opacity(0.15) : Color.clear)
                .foregroundStyle(type == .income ? theme.brandPrimary : .secondary)
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

