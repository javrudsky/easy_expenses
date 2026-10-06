//
//  AudioAnalysis.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 14/09/2026.
//

import Foundation

struct AudioTranscriberResult {
    let text: String
    let isFinal: Bool
    
    init(text: String, isFinal: Bool) {
        self.text = text
        self.isFinal = isFinal
    }
    
    init(text: AttributedString, isFinal: Bool) {
        self.text = String(text.characters[...])
        self.isFinal = isFinal
    }
}
protocol AudioTranscriber {
    
    func start() async throws -> AsyncStream<AudioTranscriberResult>?
    func stop() async
}
