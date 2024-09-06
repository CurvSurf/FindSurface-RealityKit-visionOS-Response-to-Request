//
//  LogMessageListItemView.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 9/3/24.
//

import Foundation
import SwiftUI

struct LogMessageListItemView: View {
    
    @AppStorage("display-message-level-icons") private var displayMessageLevelIcons: Bool = true
    @AppStorage("omit-info-message-icons") private var omitInfoMessageIcons: Bool = true
    @AppStorage("typewriter-interval") private var typewriterInterval: TimeInterval = 0.03
    @AppStorage("typewriter-expiration-time") private var typewriterExpirationTime: TimeInterval = 10.0
    
    @Environment(Logger.self) private var logger
    
    let message: Logger.Message
    
    var body: some View {
        HStack(alignment: .top) {
            
            if displayMessageLevelIcons {
                Text(message.level.label)
                    .opacity(omitInfoMessageIcons && message.level == .info ? 0 : 1)
            }
            Text("\(message.time)")
                .font(.subheadline.bold().monospaced())
            
            if let lastMessage = logger.messages.last,
               message == lastMessage,
               Date.now.timeIntervalSince(message.timestamp) < typewriterExpirationTime {
                TypewriterText2(text: message.content, timeInterval: typewriterInterval)
                    .font(.subheadline.bold().monospaced())
            } else {
                Text("\(message.content)")
                    .font(.subheadline.bold().monospaced())
            }
        }
    }
}
