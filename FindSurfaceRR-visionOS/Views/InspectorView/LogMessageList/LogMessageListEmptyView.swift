//
//  LogMessageListEmptyView.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 9/3/24.
//

import Foundation
import SwiftUI

struct LogMessageListEmptyView: View {
    var body: some View {
        Text("No event has been occurred yet.")
            .font(.title2)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity,
                   maxHeight: .infinity,
                   alignment: .center)
            .background(.white.opacity(0.05))
            .clipShape(.rect(cornerRadius: 8))
            .padding()
    }
}
