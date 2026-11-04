//
//  ColorPickerView.swift
//  ArgiMoney
//
//  Created by Javier Avrudsky on 03/11/2026.
//

import Foundation
import SwiftUI

struct ColorPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedColor: String
    let symbol: String
    var usedColorsList: [String] = []
    
    @State private var pickerColor: Color = .blue
    @State private var showPickerColor: Bool = false
    
    @State private var colors: [String] = [
        "1.00, 0.42, 0.21, 1.0", // FF6B35
        "0.29, 0.56, 0.89, 1.0", // 4A90E2
        "0.96, 0.65, 0.14, 1.0", // F5A623
        "0.49, 0.83, 0.13, 1.0", // 7ED321
        "0.82, 0.01, 0.11, 1.0", // D0021B
        "0.56, 0.07, 1.00, 1.0",  // 9013FE
        "1.0, 0.0, 0.00, 1.0",
        "0.0, 1.0, 0.00, 1.0",
        "0.0, 0.0, 1.00, 1.0"
    ]
    
    init(selectedColor: Binding<String>, symbol: String, usedColorsList: [String] = []) {
        self._selectedColor = selectedColor
        self.symbol = symbol
        self.usedColorsList = usedColorsList
    }
    
    func getUsedColors() -> [String]? {
        let unique = Array(Set(usedColorsList.filter { !$0.isEmpty }))
        let filtered = unique.filter { $0 != selectedColor }
        return filtered.isEmpty ? nil : filtered
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: symbol)
                        .foregroundStyle(.white)
                        .frame(width: 80, height: 80)
                        .background(Color(rgbaCsv: selectedColor), in: Circle())
                        .padding()
                    
                    ColorPicker("Custom Color", selection: $pickerColor, supportsOpacity: false)
                        .padding(.horizontal)
                        .onChange(of: pickerColor) { _, newValue in
                            let newColor = pickerColor.toRGBAcsv()
                            if !colors.contains(newColor) {
                                colors.insert(newColor, at: 0)
                            }
                            selectedColor = newColor
                        }
                    
                    if let usedColors = getUsedColors(), !usedColors.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Used colors")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                                ForEach(usedColors, id: \.self) { color in
                                    Button {
                                        selectedColor = color
                                    } label: {
                                        Circle()
                                            .fill(Color(rgbaCsv: color))
                                            .frame(width: 44, height: 44)
                                            .overlay {
                                                if selectedColor == color {
                                                    Circle()
                                                        .strokeBorder(.primary, lineWidth: 3)
                                                }
                                            }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        
                        Text("Suggested colors")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                            ForEach(colors, id: \.self) { color in
                                Button {
                                    selectedColor = color
                                } label: {
                                    Circle()
                                    
                                        .fill(Color(rgbaCsv: color))
                                        .frame(width: 44, height: 44)
                                        .overlay {
                                            if selectedColor == color {
                                                Circle()
                                                    .strokeBorder(.primary, lineWidth: 3)
                                            }
                                        }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom)
                }
            }
            .navigationTitle("Choose Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                pickerColor = Color(rgbaCsv: selectedColor)
            }
        }
    }
}

