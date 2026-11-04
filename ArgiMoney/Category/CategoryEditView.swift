//
//  CategoryEditView.swift
//  ArgiMoney
//
//  Created by OpenCode
//

import SwiftUI


import SwiftUI

struct CategoryEditView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var imageName: String
    @State private var rgbColor: String

    @State private var showSymbolPicker = false
    @State private var showColorPicker = false

    private let transactionType: TransactionType
    private let category: Category?
    private let onSave: (Category) -> Void
    private let usedColors: [String]

    init(
        category: Category? = nil,
        transactionType: TransactionType,
        usedColors: [String] = [],
        onSave: @escaping (Category) -> Void
    ) {
        self.category = category
        self.transactionType = transactionType
        self.usedColors = usedColors
        self.onSave = onSave

        _name = State(
            initialValue: category?.name ?? ""
        )
        _imageName = State(
            initialValue: category?.imageName ??
                (transactionType == .expense
                 ? "cart.fill"
                 : "dollarsign.circle.fill")
        )
        _rgbColor = State(
            initialValue: category?.rgbColor ?? AppDefaults.defaultCategoryColor
        )
    }

    private var categoryColor: Color {
        Color(rgbaCsv: rgbColor)
    }

    private var isValid: Bool {
        !name.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    categoryCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(
                Color(uiColor: .systemGroupedBackground)
            )
            .navigationTitle(
                category == nil
                    ? "New Category"
                    : "Edit Category"
            )
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        saveCategory()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .disabled(!isValid)
                    .accessibilityLabel("Save")
                }
            }
            .sheet(isPresented: $showSymbolPicker) {
                SymbolPickerView(
                    selectedSymbol: $imageName,
                    color: rgbColor
                )
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showColorPicker) {
                ColorPickerView(
                    selectedColor: $rgbColor,
                    symbol: imageName,
                    usedColorsList: usedColors
                )
                .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: - Main Card

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 28) {

            HStack(alignment: .center, spacing: 16) {

                categoryPreview

                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.subheadline.weight(.medium))

                    TextField("Category name", text: $name)
                        .font(.body)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                        .padding(.horizontal, 12)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(
                                    Color.gray.opacity(0.25)
                                )
                        )
                }
            }

            VStack(alignment: .leading, spacing: 20) {

                selectionRow(
                    title: "Icon",
                    action: {
                        showSymbolPicker = true
                    }
                ) {
                    Image(systemName: imageName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(categoryColor)
                        .frame(width: 36, height: 36)
                }

                selectionRow(
                    title: "Color",
                    action: {
                        showColorPicker = true
                    }
                ) {
                    Circle()
                        .fill(categoryColor)
                        .frame(width: 30, height: 30)
                        .frame(width: 36, height: 36)
                }
            }
        }
        .padding(20)
        .background(
            .white,
            in: RoundedRectangle(cornerRadius: 22)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(
                    Color.gray.opacity(0.07)
                )
        }
    }

    // MARK: - Category Preview

    private var categoryPreview: some View {
        Image(systemName: imageName)
            .font(.system(size: 32, weight: .medium))
            .foregroundStyle(categoryColor)
            .frame(width: 76, height: 76)
            .background(
                categoryColor.opacity(0.11),
                in: RoundedRectangle(cornerRadius: 20)
            )
            .accessibilityLabel("Category preview")
    }

    // MARK: - Selection Row

    private func selectionRow<Content: View>(
        title: String,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {

            Text(title)
                .font(.subheadline.weight(.medium))

            Button(action: action) {
                HStack {
                    content()

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            Color.gray.opacity(0.25)
                        )
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Choose \(title.lowercased())")
        }
    }

    // MARK: - Save

    private func saveCategory() {
        guard isValid else { return }

        let newCategory = Category(
            id: category?.id ?? UUID(),
            name: name.trimmingCharacters(
                in: .whitespacesAndNewlines
            ),
            transactionType: transactionType,
            imageName: imageName,
            rgbColor: rgbColor
        )

        onSave(newCategory)
        dismiss()
    }
}


struct SymbolPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedSymbol: String
    let color: String
    
    @State private var searchText: String = ""
    
    let symbols: [String] = [
        "cart.fill", "house.fill", "bolt.fill", "car.fill", "cross.case.fill",
        "fork.knife", "bag.fill", "repeat.circle.fill", "book.fill", "airplane",
        "doc.text.fill", "fuelpump.fill", "gift.fill", "heart.fill", "stethoscope",
        "gamecontroller.fill", "music.note", "ticket.fill", "briefcase.fill",
        "laptopcomputer", "banknote.fill", "chart.line.uptrend.xyaxis",
        "dollarsign.circle.fill", "creditcard.fill", "phone.fill", "wifi",
        "bus.fill", "tram.fill", "bicycle", "figure.walk", "ellipsis.circle",
        "cup.and.saucer.fill", "takeoutbag.and.cup.and.straw.fill", "pawprint.fill",
        "dog.fill", "cat.fill", "leaf.fill", "tree.fill", "sun.max.fill",
        "moon.fill", "cloud.fill", "snowflake", "drop.fill", "flame.fill"
    ]
    
    var filteredSymbols: [String] {
        if searchText.isEmpty {
            return symbols
        }
        return symbols.filter { $0.localizedCaseInsensitiveContains(searchText.replacingOccurrences(of: ".fill", with: "")) }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 16) {
                    ForEach(filteredSymbols, id: \.self) { symbol in
                        Button {
                            selectedSymbol = symbol
                            dismiss()
                        } label: {
                            Image(systemName: symbol)
                                .foregroundStyle(.white)
                                .frame(width: 50, height: 50)
                                .background(Color(rgbaCsv: color), in: Circle())
                                .overlay {
                                    if selectedSymbol == symbol {
                                        Circle()
                                            .strokeBorder(.primary, lineWidth: 3)
                                    }
                                }
                        }
                    }
                }
                .padding()
            }
            .searchable(text: $searchText, prompt: "Search symbols")
            .navigationTitle("Choose Symbol")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CategoryEditView(category: nil, transactionType: .expense) { _ in }
}
