//
//  Extensions.swift
//  ArgiMoney
//
//  Created by Javier Avrudsky on 21/10/2026.
//

import Foundation
import SwiftUI

extension Date {
    var uiFormat: String {
        return self.formatted(
            .dateTime
                .day(.twoDigits)
                .month(.abbreviated)
                .year(.extended())
        )
    }

}

extension Color {
    init(rgb: String) {
        if rgb.count != 6 {
            self.init(red: 0.0, green: 0.0, blue: 0.0)
            return
        }
        let color = Array(rgb)
        let red = (Double(String(color[..<2])) ?? 0.0) / 255.0
        let green = (Double(String(color[2..<4])) ?? 0.0) / 255.0
        let blue = (Double(String(color[3..<5])) ?? 0.0) / 255.0
        self.init(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue))
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
