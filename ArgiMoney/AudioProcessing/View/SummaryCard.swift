//
//  SummaryCard.swift
//  ArgiMoney
//
//  Created by Javier Avrudsky on 07/10/2026.
//

import Foundation
import SwiftUI

struct SummaryCard: View {
    var income: Double
    var expenses: Double
    var result: Double { income - expenses }
    var widthFraction: CGFloat = 1.0
    var heightFraction: CGFloat? = nil

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width * widthFraction
            let h = heightFraction.map { proxy.size.height * $0 }
            let base = min(proxy.size.width, proxy.size.height)
            let spacing = max(8, base * 0.02)
            let padding = max(12, base * 0.03)
            let headerFontSize: CGFloat = max(16, base * 0.045)
            let subtitleFontSize: CGFloat = max(12, base * 0.032)
            let valueFontSize: CGFloat = max(18, base * 0.06)
            let iconFontSize: CGFloat = max(12, base * 0.035)

            VStack(spacing: spacing) {
                // Header
                HStack {
                    Text("This month")
                        .font(.system(size: headerFontSize, weight: .semibold))
                    Spacer()
                    // Use a Menu if you want it actionable
                    Image(systemName: "chevron.down")
                        .font(.system(size: subtitleFontSize))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }

                // Stats
                HStack(spacing: 0) {
                    StatColumn(
                        icon: "arrow.up.right.circle.fill",
                        iconColor: .green,
                        title: "Income",
                        value: income,
                        valueColor: .primary,
                        titleFontSize: subtitleFontSize,
                        valueFontSize: valueFontSize,
                        iconFontSize: iconFontSize
                    )
                    Divider().padding(.vertical, 6)
                    StatColumn(
                        icon: "arrow.down.right.circle.fill",
                        iconColor: .red,
                        title: "Expenses",
                        value: expenses,
                        valueColor: .primary,
                        titleFontSize: subtitleFontSize,
                        valueFontSize: valueFontSize,
                        iconFontSize: iconFontSize
                    )
                    Divider().padding(.vertical, 6)
                    StatColumn(
                        icon: "equal.circle.fill",
                        iconColor: result >= 0 ? .green : .red,
                        title: "Result",
                        value: result,
                        valueColor: result >= 0 ? .green : .red,
                        titleFontSize: subtitleFontSize,
                        valueFontSize: valueFontSize,
                        iconFontSize: iconFontSize
                    )
                }
            }
            .padding(padding)
            .frame(width: w, height: h, alignment: .center)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.white))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color(.separator), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // position inside GeometryReader
        }
    }
}

private struct StatColumn: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: Double
    let valueColor: Color
    let titleFontSize: CGFloat
    let valueFontSize: CGFloat
    let iconFontSize: CGFloat

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: iconFontSize, weight: .semibold))
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.system(size: titleFontSize))
                    .foregroundStyle(.secondary)
            }
            Text(value, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                .font(.system(size: valueFontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(valueColor)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 4)
    }
}
