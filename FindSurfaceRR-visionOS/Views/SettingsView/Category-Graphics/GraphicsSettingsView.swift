//
//  GraphicsSettingsView.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 8/26/24.
//

import Foundation
import SwiftUI

struct GraphicsSettingsView: View {
    var body: some View {
        List {
            GraphicsSceneReconstructionSection()
            GraphicsGeometrySection()
            GraphicsHandSection()
            GraphicsUIAnchorSection()
        }
        .padding(.horizontal, 25)
        .toolbar {
            ToolbarItem(placement: .secondaryAction) {
                Text("Graphics & Rendering")
                    .font(.title)
            }
        }
    }
    
    struct Title: View {
        var body: some View {
            Label("Graphics & Rendering", systemImage: "slider.horizontal.below.square.filled.and.square")
        }
    }
}
