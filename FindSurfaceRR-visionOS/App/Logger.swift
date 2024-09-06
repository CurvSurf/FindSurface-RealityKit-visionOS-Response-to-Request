//
//  Logger.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 8/28/24.
//

import Foundation
import SwiftUI

let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter
}()

@Observable
final class Logger {
    
    struct Message: Hashable {
        
        enum Level {
            case info
            case warning
            case error
            
            var label: String {
                switch self {
                case .info: return "ℹ️"
                case .warning: return "⚠️"
                case .error: return "⛔️"
                }
            }
        }
        
        let timestamp: Date = .now
        let level: Level
        let content: AttributedString
        
        init(level: Level = .info, content: AttributedString) {
            self.level = level
            self.content = content
        }
        
        var time: String {
            return timeFormatter.string(from: timestamp)
        }
    }
    
    private(set) var messages: [Message] = []
    
    init() {
        
    }
    
    func clear() {
        messages.removeAll()
    }
    
    func add(level: Message.Level = .info, _ message: String) {
        messages.append(.init(level: level, content: AttributedString(message)))
    }
    
    func add(level: Message.Level = .info, _ message: AttributedString) {
        messages.append(.init(level: level, content: message))
    }
}
