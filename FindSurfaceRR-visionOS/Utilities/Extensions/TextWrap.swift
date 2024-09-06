//
//  textWrap.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 8/27/24.
//

import Foundation

func wrap(_ text: String, lineLength: Int) -> String {
    var result = ""
    var currentLine = ""

    for word in text.split(separator: " ") {
        if currentLine.count + word.count + 1 > lineLength {
            result += currentLine + "\n"
            currentLine = String(word)
        } else {
            if !currentLine.isEmpty {
                currentLine += " "
            }
            currentLine += word
        }
    }

    result += currentLine
    return result
}
