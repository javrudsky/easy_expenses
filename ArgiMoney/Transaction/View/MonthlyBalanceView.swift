//
//  BalanceHeaderView.swift
//  ArgiMoney
//
//  Created by Javier Avrudsky on 16/11/2026.
//

import Foundation
import SwiftUI

struct MonthlyBalanceView: View {
    
    var incomeAmount: Decimal
    var expensesAmount: Decimal
    var resultAmount: Decimal
    @State var showingDetail = false
    
    var body: some View {
        VStack {
            HStack {
                collapsedMonthlyBalanceCard
                Spacer()
                Button {
                    showingDetail.toggle()
                } label: {
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(showingDetail ? 0 : -90))
                        .animation(.easeInOut(duration: 0.2), value: showingDetail)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.gray)
                        .frame(width: 10, height: 10)
                }
                .frame(minWidth: 30, minHeight: 10)
            }
            
            Spacer()
            
            if showingDetail {
                HStack(spacing: 12) {
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 1)
                    
                    
                    VStack(spacing: 0) {
                        
                        summaryItem(
                            title: "Income",
                            amount: incomeAmount,
                            symbol: "arrow.up",
                            color: .green
                        )
                        
                        Divider()
                        
                        summaryItem(
                            title: "Expenses",
                            amount: expensesAmount,
                            symbol: "arrow.down",
                            color: .red
                        )
                        
                        Divider()
                        
                    }
                }
            }
            
        }
        .frame(height: showingDetail ? 140 : 30)
        // Animate the frame change
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showingDetail)
        .padding(8)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.gray.opacity(0.08))
        }
    }
    
    private var collapsedMonthlyBalanceCard: some View {
        
        HStack {
            HStack(alignment: .center, spacing: 8) {
                Text(headerTitle)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.secondary)
                
                Spacer(minLength: 8)
                
                Text(String.currency(resultAmount))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        resultAmount >= 0 ? .green : .red
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .contentTransition(.numericText())
                    .layoutPriority(1)
            }
        }
        .padding(.horizontal, 15)
        .padding(.top, 2)
    }
    
    private func summaryItem(
        title: String,
        amount: Decimal,
        symbol: String,
        color: Color
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 30, height: 30)
                .background(
                    color.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 10)
                )
                        
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer(minLength: 4)
            
            Text(String.currency(amount))
                .font(.system(
                    size: 15,
                ))
                .foregroundStyle(
                    title == "Result" ? color : .primary
                )
            
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText())
                .layoutPriority(1)
        }
        .frame(minHeight: 35)
    }
    
    private var month: String {
        return Date.now.formatted(.dateTime.month(.abbreviated))
    }
    
    private var year: String {
        return Date.now.formatted(.dateTime.year())
    }

    private var headerTitle: String {
        return "\(month) \(year)"
    }

}
