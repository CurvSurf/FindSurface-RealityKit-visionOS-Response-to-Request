//
//  ConversionBehaviorSection.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 8/27/24.
//

import Foundation
import SwiftUI

struct ConversionBehaviorSection: View {
    
    @Environment(\.widthMinMax) private var widthMinMax
    
    @Environment(WorldTrackingManager.self) private var worldManager
    
    var body: some View {
        @Bindable var worldManager = worldManager
        Section("Conversion (App-specific)") {
            
            Toggle(isOn: $worldManager.enableFullTorusConversion.animation()) {
                CaptionedLabel(title: "Complete partial torus",
                               caption: "Converts the torus segment into a full torus when the angle exceeds a threshold.")
            }
            
            if worldManager.enableFullTorusConversion {
             
                let binding = $worldManager.fullTorusAngleThreshold.mapRadianToDegree()
                NumericTextField(value: binding,
                                  lowerbound: 0,
                                  upperbound: 360) {
                    AngleStepperDialog(value: binding,
                                       lowerbound: 0,
                                       upperbound: 360)
                } label: {
                    CaptionedLabel(title: "Threshold [°]")
                }
            }
            
            Toggle(isOn: $worldManager.enableFullConeConversion.animation()) {
                CaptionedLabel(title: "Cap conical frustum",
                               caption: "Adds a vertex point to the conical frustum if the ratio of the top radius to the bottom radius is less than \(percentage: worldManager.fullConeRadiiRatioThreshold).")
            }
            
            if worldManager.enableFullConeConversion {
                
                let binding = $worldManager.fullConeRadiiRatioThreshold.mapNumberToPercent()
                NumericTextField(value: binding,
                                  lowerbound: 0.1,
                                  upperbound: 100) {
                    PercentageStepperDialog(value: binding)
                } label: {
                    CaptionedLabel(title: "Threshold [percentage]")
                }
            }
        }
    }
}
