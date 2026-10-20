//
//  OptionsView.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 25/09/2026.
//

import Foundation
import SwiftUI

typealias OnGridButtonSelect = (String) -> Void

typealias OnMore = () -> Void
struct CategoryGridView: View {
    
    @Environment(\.theme) private var theme
    private let items: [Category]
    private var buttons: [String: ButtonGrid] = [:]
    private var itemCount: Int = 8
    private var onMore: OnMore?
    @State var showCatList: Bool = false
    
    @Binding var value: Category

    init(items: [Category],
         value: Binding<Category>,
         onMore: OnMore? = nil) {
        self.items = items
        self._value = value
        self.onMore = onMore
    }
    
    func itemCount(_ count: Int) -> Self {
        var copy = self
        copy.itemCount = count
        return copy
    }
    
    var body: some View {
            let rows = Array(items.prefix(itemCount))
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                ForEach(rows.chunked(into: 3), id: \.self) { row in
                    GridRow {
                        ForEach(row, id: \.self) { item in
                            ButtonGrid(
                                value: item,
                                isSelected: Binding(
                                    get: { item.id == value.id },
                                    set: { newValue in
                                        if newValue {
                                            value = item
                                        }
                                    }
                                )
                            )
                            if item == items[itemCount - 1] {
                                Button("More") {
                                    //onMore?()
                                    showCatList = true
                                }
                                        .aspectRatio(1, contentMode: .fit)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))

                                .popover(isPresented: $showCatList) {
                                    
                                    ListOfValuesView(values: items.map { LovValue(id: $0.id, name: $0.name)},
                                                     name: \LovValue.name) { selCat in
                                        value = items.first { $0.id == selCat.id } ?? item
                                        withAnimation(.easeInOut) {
                                            showCatList = false
                                        }
                                    }
                                                     .containerRelativeFrame([.horizontal, .vertical])
                                                     .presentationCompactAdaptation(.popover)
                                                     .padding()
                                    
                                }
                            }
                            
                        }
                    }

            }
            .buttonStyle(ColoredGridButtonStyle(
                normalColor: Color(.systemGray6),
                selectedColor: .accentColor,
                isSelected: false
            ))
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
            isSelected = true
        }
        .buttonStyle(ColoredGridButtonStyle(
            normalColor: Color(.systemGray6),
            selectedColor: .accentColor,
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
            .frame(maxWidth: .infinity, minHeight: 80)
            .aspectRatio(1, contentMode: .fit)
        // .background(.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

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
