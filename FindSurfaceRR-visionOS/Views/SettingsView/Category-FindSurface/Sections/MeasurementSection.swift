//
//  MeasurementSection.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 8/26/24.
//

import Foundation
import SwiftUI

import FindSurface_visionOS

struct MeasurementSection: View {
    
    @Environment(FindSurface.self) private var findSurface
    
    var body: some View {
        @Bindable var findSurface = findSurface
        Section("Measurement") {
            
            let accuracyBinding = $findSurface.measurementAccuracy.mapMeterToCentimeter()
            NumericTextField(value: accuracyBinding,
                              lowerbound: 0.3,
                              upperbound: 10) {
                LengthStepperDialog(value: accuracyBinding,
                                    lowerbound: 0.3,
                                    upperbound: 10,
                                    initialStep: .millimeter)
            } label: {
                CaptionedLabel(title: "Measurement Accuaracy [cm]",
                               caption: "The a priori root-mean-squared error of the measurement points.\nAcceptable range is from 0.3 (3 mm) to 10 (10 cm).")
            }
            
            let distanceBinding = $findSurface.meanDistance.mapMeterToCentimeter()
            NumericTextField(value: distanceBinding,
                              lowerbound: 1,
                              upperbound: 50) {
                LengthStepperDialog(value: distanceBinding,
                                    lowerbound: 1,
                                    upperbound: 50)
            } label: {
                CaptionedLabel(title: "Mean Distance [cm]",
                               caption: "An average distance between points.\nAcceptable range is from 1 (1 cm) to 50 (50 cm)")
            }
        }
    }
}
