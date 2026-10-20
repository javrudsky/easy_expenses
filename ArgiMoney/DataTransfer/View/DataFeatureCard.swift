//
//  DataFeatureCard.swift
//  ArgiMoney
//
//  Created by Javier Avrudsky on 20/10/2026.
//

import SwiftUI

struct DataFeatureCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 80, height: 80)
                .background(color.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 22))

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(ArgiColors.primaryText)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(ArgiColors.secondaryText)
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ArgiColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}

struct DataInfoBox: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(ArgiColors.blue)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(ArgiColors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(ArgiColors.blue.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
