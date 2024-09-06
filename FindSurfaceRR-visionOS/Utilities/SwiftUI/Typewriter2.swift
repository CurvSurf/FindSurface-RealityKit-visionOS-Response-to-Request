//
//  Typewriter2.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 8/28/24.
//

import Foundation
import SwiftUI

@Observable
final class Typewriter2 {
    
    private(set) var displayedText: AttributedString = ""
    private let timeInterval: TimeInterval
    
    init(timeInterval: TimeInterval) {
        self.timeInterval = timeInterval
    }
    
    func type(_ text: AttributedString) async {
        do {
            displayedText = ""
            var currentIndex = text.startIndex
            while currentIndex <= text.endIndex {
                try await Task.sleep(nanoseconds: UInt64(timeInterval * 1_000_000_000))
                
                let nextIndex = text.index(afterCharacter: currentIndex)
                let characterRange = currentIndex..<nextIndex
                let characterAttributedString = text[characterRange]
                
                displayedText.append(characterAttributedString)
                currentIndex = nextIndex
            }
        } catch {}
    }
}

struct TypewriterText2: View {
    
    @State private var typewriter: Typewriter2
    let text: AttributedString
    
    init(text: AttributedString, timeInterval: TimeInterval) {
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

extension AttributedString {
    
    mutating func bold() -> AttributedString {
        self.font = self.font?.bold()
        return self
    }
    
}


extension String {
    var attr: AttributedString {
        return AttributedString(self)
    }
}
