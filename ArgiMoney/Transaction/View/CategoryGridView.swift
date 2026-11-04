//
//  OptionsView.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 25/09/2026.
//

import Foundation
import SwiftUI

typealias OnGridButtonSelect = (String) -> Void

fileprivate struct GridCfg {
    static let buttonFontSize = 14.0
}

struct CategoryGridView: View {
    
    @Environment(\.theme) private var theme
    @State var allItems: [Category]
    @State var items: [Category]
    @State var moreItems: [Category]

    private var buttons: [String: ButtonGrid] = [:]
    static private let itemCount: Int = 8
    @State var showCatList: Bool = false
    
    @Binding var value: Category

    private static func arrangeItems(value: Category, items: [Category]) -> ([Category], [Category]) {
        // Returns a tuple of (categories in buttons, categories in more list)
        if items.count < itemCount { return (items, [])}
        var ordItems: [Category] = [value]
        ordItems.append(contentsOf: items.filter { $0 != value })
        return (Array(ordItems[..<itemCount]), Array(ordItems.suffix(from: itemCount)))
    }
    
    init(items: [Category],
         value: Binding<Category>) {
        self._value = value
        self.allItems = items
        
        // let tp = Self.arrangeItems(value: value.wrappedValue, items: items)
        (self.items, self.moreItems) = Self.arrangeItems(value: value.wrappedValue, items: items)
    }
    
    var body: some View {
            let rows = items
            Grid(horizontalSpacing: 5, verticalSpacing: 5) {
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
                            
                            if moreItems.count > 0 && item == items.last {
                                
                                Button {
                                    showCatList = true
                                } label: {
                                    
                                    ButtonGridLabel(label: "More", imageName: "ellipsis.circle", rgbColor: "FFFFFF")
                                    .popover(isPresented: $showCatList) {
                                        
                                        ListOfValuesView(values: moreItems.map { LovValue(id: $0.id, name: $0.name)},
                                                         name: \LovValue.name) { selCat in
                                            value = moreItems.first { $0.id == selCat.id } ?? item
                                            (items, moreItems) = Self.arrangeItems(value: value, items: allItems)
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

            }
            .buttonStyle(ColoredGridButtonStyle(
                normalColor: Color(.systemGray6),
                selectedColor: .accentColor,
                isSelected: false
            ))
        }
    }
    
    func process(categories: [Category], selected: Category?) -> [Category] {
        let cSel = selected ?? categories[0]
        var gc = [cSel]
        let max = min(categories.count - 1, 8)
        if max > 0 {
            gc.append(contentsOf: categories.filter {$0.id != cSel.id}[..<max])
        }
        return gc
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
        Button {
            isSelected = true
        } label: {
            ButtonGridLabel(label: value.name, imageName: value.imageName, rgbColor: value.rgbColor)
        }
        .buttonStyle(ColoredGridButtonStyle(
            normalColor: Color(.systemGray6),
            selectedColor: .accentColor,
            isSelected: self.isSelected
        ))
    }
}

struct ButtonGridLabel: View {
    private let label: String
    private let imageName: String
    private let rgbColor: String
    
    init(label: String,
         imageName: String,
         rgbColor: String) {
        self.label = label
        self.imageName = imageName
        self.rgbColor = rgbColor
    }
    
    var body: some View {
        VStack(alignment: .center) {
            Text(label)
                .multilineTextAlignment(.center)
                .font(.system(size: GridCfg.buttonFontSize, weight: .regular))
                .minimumScaleFactor(0.7)
            Image(systemName: imageName)
                .foregroundStyle(Color.white)
                .frame(width: 36, height: 36)
                .background(Color(rgbaCsv: rgbColor),
                            in: Circle()
                )
        }
    }

}

struct ColoredGridButtonStyle: ButtonStyle {
    var normalColor: Color
    var selectedColor: Color
    var isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, minHeight: 100)
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
