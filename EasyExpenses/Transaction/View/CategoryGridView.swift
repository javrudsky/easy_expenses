//
//  OptionsView.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 25/09/2026.
//

import Foundation
import SwiftUI

typealias OnGridButtonSelect = (String) -> Void

struct CategoryGridView: View {
    private let items: [Category]
    private var buttons: [String: ButtonGrid] = [:]
    @State var selectedId: String
    @State var value: Category

    init(items: [Category],
         value: Category) {
        self.items = items
        self.value = value
        self._selectedId = State(initialValue: value.id)
    }
    
    var body: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            ForEach(items.chunked(into: 3), id: \.self) { row in
                GridRow {
                    ForEach(row, id: \.self) { item in
                        ButtonGrid(
                            value: item,
                            isSelected: Binding(
                                get: { selectedId == item.id },
                                set: { newValue in
                                    if newValue { selectedId = item.id }
                                    if let v = items.first(where: { $0.id == item.id }) {
                                        value = v
                                        print("Selected ")
                                    }
                                    print("New selected value \(value.name)")
                                }
                            )
                        )
                    }
                }
            }
        }
    }
}

struct ButtonGrid: View {
    var value: Category
    @Binding var isSelected: Bool
    
    init(value: Category,
         isSelected: Binding<Bool>) {
        self.value = value
        self._isSelected = isSelected
    }
    
    
    var body: some View {
        Button(value.name) {
            isSelected.toggle()
        }
        .buttonStyle(ColoredGridButtonStyle(
            normalColor: Color(.systemGray6),
            selectedColor: .blue,
            isSelected: self.isSelected
        ))
    }
}

struct ColoredGridButtonStyle: ButtonStyle {
    var normalColor: Color
    var selectedColor: Color
    var isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? selectedColor : normalColor)
                    .opacity(configuration.isPressed ? 0.85 : 1.0) // pressed effect
            )
            .foregroundStyle(isSelected ? .white : .primary)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.12), value: isSelected)
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        precondition(size > 0, "size must be greater than zero")
        var result: [[Element]] = []
        result.reserveCapacity((count + size - 1) / size)

        var index = startIndex
        while index < endIndex {
            let end = self.index(index, offsetBy: size, limitedBy: endIndex) ?? endIndex
            result.append(Array(self[index..<end]))
            index = end
        }
        return result
    }
}
