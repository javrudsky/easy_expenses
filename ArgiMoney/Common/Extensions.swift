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
    
    init(rgbaCsv: String) {
        
        func dbl(_ v: String) -> Double {
           return  Double(v.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0.0
        }
        
        let vals = rgbaCsv.split(separator: ",")
        if vals.count != 4 {
            self.init(UIColor.magenta)
            return
        }
        let red = dbl(vals[0].str)
        let green = dbl(vals[1].str)
        let blue = dbl(vals[2].str)
        let alpha = dbl(vals[3].str)
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
    
    func toRGBAcsv(in environment: EnvironmentValues = EnvironmentValues()) -> String {
         let resolved = self.resolve(in: environment)
        
        // 2. Extract normalized red, green, blue, and alpha components
        let r = resolved.red
        let g = resolved.green
        let b = resolved.blue
        let a = resolved.opacity
        let rgb = "\(r), \(g), \(b), \(a)"
        return rgb
   
    }
    
    func toHex(in environment: EnvironmentValues = EnvironmentValues()) -> String {
        // 1. Resolve the color within the provided environment context
        let resolved = self.resolve(in: environment)
        
        // 2. Extract normalized red, green, blue, and alpha components
        let r = resolved.linearRed
        let g = resolved.linearGreen
        let b = resolved.linearBlue
        
        // 3. Convert floating point values (0.0 - 1.0) into integers (0 - 255)
        let redInt = Int(clamping: Int(r * 255))
        let greenInt = Int(clamping: Int(g * 255))
        let blueInt = Int(clamping: Int(b * 255))
        
        // 4. Format into a 6-character hexadecimal string
        return String(format: "#%02X%02X%02X", redInt, greenInt, blueInt)
    }
}

extension Substring {
    var str: String {
        return String(self)
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
