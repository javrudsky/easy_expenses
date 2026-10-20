//
//  ViewModifiers.swift
//  ArgiMoney
//
//  Created by Javier Avrudsky on 17/10/2026.
//

import SwiftUI

struct ThemedTextField: ViewModifier {
    
    @Environment(\.theme) var theme: Theme
    
    func body(content: Content) -> some View {
        content
            .safeAreaPadding(5)
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(theme.inputFieldBorder)
            }
        
    }
}

extension View {
    func themedTextField() -> some View {
        self.modifier(ThemedTextField())
    }
}
