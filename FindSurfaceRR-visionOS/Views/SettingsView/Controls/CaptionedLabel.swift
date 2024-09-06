//
//  CaptionedLabel.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 8/29/24.
//

import Foundation
import SwiftUI

struct CaptionedLabel: View {
    
    let title: String
    let caption: String?
    let wrapLength: Int
    
    init(title: String, caption: String? = nil, wrapLength: Int = 80) {
        self.title = title
        self.caption = caption
        self.wrapLength = wrapLength
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .lineLimit(1)
                
            if let caption {
                Text(caption)
                    .padding(.trailing)
                    .frame(width: 500, alignment: .leading)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .minimumScaleFactor(0.5)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

