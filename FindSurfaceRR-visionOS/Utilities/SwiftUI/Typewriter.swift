//
//  TypewriterLabel.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 8/20/24.
//

import Foundation
import SwiftUI

struct TypewriterLabel: View {
    
    @State private var typewriter: Typewriter
    let image: Image
    let text: String
    
    init(image: Image, text: String, timeInterval: TimeInterval) {
        self.image = image
        self.text = text
        self._typewriter = State(initialValue: .init(timeInterval: timeInterval))
    }
    
    var body: some View {
        Text("\(image)\(typewriter.displayedText)")
            .id(text)
            .task(id: text) {
                await typewriter.type(text)
            }
    }
}

extension TypewriterLabel {
    init(systemName imageName: String, text: String, timeInterval: TimeInterval = 0.03) {
        self.init(image: Image(systemName: imageName), text: text, timeInterval: timeInterval)
    }
}

struct TypewriterText: View {
    
    @State private var typewriter: Typewriter
    let text: String
    
    init(text: String, timeInterval: TimeInterval) {
        self.text = text
        self._typewriter = State(initialValue: .init(timeInterval: timeInterval))
    }
    
    var body: some View {
        Text("\(typewriter.displayedText)")
            .id(text)
            .task(id: text) {
                await typewriter.type(text)
            }
    }
}

@Observable
final class Typewriter {
    private(set) var displayedText: AttributedString = ""
    private let timeInterval: TimeInterval
    
    private struct Word {
        let text: String
        let bold: Bool
    }
    
    init(timeInterval: TimeInterval) {
        self.timeInterval = timeInterval
    }
    
    func type(_ text: String) async {
        do {
            let words = parseBoldText(from: text)
            var currentText = AttributedString()
            
            for word in words {
                for char in word.text {
                    try await Task.sleep(nanoseconds: UInt64(timeInterval * 1_000_000_000))
                    var attr = AttributedString(String(char))
                    if word.bold {
                        attr.font = .body.bold()
                    }
                    currentText.append(attr)
                    displayedText = currentText
                }
            }
        } catch {}
    }
    
    private func parseBoldText(from input: String) -> [Word] {
        
        let components = input.components(separatedBy: "**")
        var words: [Word] = []
        
        for (index, text) in components.enumerated() {
            if index == components.count - 2 && components.count % 2 == 0 {
                let combinedText = text + "**" + components[index + 1]
                words.append(Word(text: combinedText, bold: false))
                break
            } else {
                let isBold = (index % 2 == 1)
                words.append(Word(text: text, bold: isBold))
            }
        }
        
        return words
    }
}
