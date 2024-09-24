//
//  TargetObjectSection.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 8/26/24.
//

import Foundation
import SwiftUI

import FindSurface_visionOS

struct TargetObjectSection: View {
    
    @Environment(FindSurface.self) private var findSurface
    
    var body: some View {
        @Bindable var findSurface = findSurface
        
        Section("Target Objects") {
            
            let radiusBinding = $findSurface.seedRadius.mapMeterToCentimeter()
            NumericTextField(value: radiusBinding,
                              lowerbound: 5,
                              upperbound: 1000) {
                LengthStepperDialog(value: radiusBinding,
                                    lowerbound: 5,
                                    upperbound: 1000,
                                    includeMeters: true)
            } label: {
                CaptionedLabel(title: "Seed Radius [cm]",
                               caption: "The radius of a seed region around the seed point where FindSurface starts searching for the surface. Acceptable range is from 5 (5 cm) to 1000 (10 m).")
            }
        }
    }
}
