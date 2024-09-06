//
//  ExperimentalSection.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 8/29/24.
//

import Foundation
import SwiftUI

import FindSurface_visionOS

struct ExperimentalSection: View {
    
    @Environment(FindSurface.self) private var findSurface
    
    @AppStorage("allow-feature-type-any") private var allowFeatureTypeAny: Bool = false
    
    var body: some View {
        Section("Experimental") {
            
            Toggle(isOn: $allowFeatureTypeAny) {
                CaptionedLabel(title: "Allow Auto (Any) Feature Type",
                               caption: "Adds an option to the Control Panel that allows to automatically detect the appropriate geometry without specifying a feature type in advance. This feature is disabled by default because it cannot operate correctly with the limited data available in visionOS (i.e., vertices from MeshAnchor.)")
            }
        }
    }
}
