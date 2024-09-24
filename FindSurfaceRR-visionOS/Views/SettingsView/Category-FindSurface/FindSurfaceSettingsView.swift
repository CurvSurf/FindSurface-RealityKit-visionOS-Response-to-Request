//
//  FindSurfaceSettingsView.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 8/26/24.
//

import Foundation
import SwiftUI

struct FindSurfaceSettingsView: View {
    
    @State private var labelWidth: CGFloat = 0
    @State private var textFieldWidth: CGFloat = .infinity
    @State private var pickerWidth: CGFloat = 0
    
    var body: some View {
        List {
            InputDataPointsSection()
            TargetObjectSection()
            RegionGrowingSection()
            SmartConversionSection()
            ExperimentalSection()
        }
        .padding(.horizontal, 25)
        .toolbar {
            ToolbarItem(placement: .secondaryAction) {
                Text("FindSurface")
                    .font(.title)
            }
        }
    }
}

