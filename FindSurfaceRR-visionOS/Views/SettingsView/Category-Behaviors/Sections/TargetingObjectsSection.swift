//
//  TargetingObjectsSection.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 8/27/24.
//

import Foundation
import SwiftUI

struct TargetingObjectsSection: View {
    
//    @Environment(FoundTimer.self) private var timer
    @Environment(WorldTrackingManager.self) private var worldManager
    
    var body: some View {
        @Bindable var worldManager = worldManager
        Section("Targeting Objects") {
            
            let angleBinding = $worldManager.deviceDirectionVerticalBias.mapRadianToDegree()
            NumericTextField(value: angleBinding,
                             lowerbound: 0,
                             upperbound: 25) {
                SliderDialog(value: angleBinding, in: 0...25, step: 1) {
                    Text("Value: \(angleBinding.wrappedValue)°")
                } minimumValueLabel: {
                    Text("0°")
                } maximumValueLabel: {
                    Text("25°")
                }
            } label: {
                CaptionedLabel(title: "Adjust Direction Angle [°]",
                               caption: "Tilts DeviceAnchor's forward direction vertically (the positive angle tilts the forward vector to downward).")
            }
            
            HStack {
                CaptionedLabel(title: "FindSurface Invocation Frequency",
                               caption: "Adjusts the invocation frequency of FindSurface in preview mode.")
                Spacer()
                FixedSizedPicker(selection: $worldManager.previewSamplingFrequency) { rate in
                    rate.label
                }
            }
            
            Picker(selection: $worldManager.offlinePreviewTarget) {
                Text("Disabled").tag(OfflinePreviewTarget.disabled)
                Text("Device").tag(OfflinePreviewTarget.whereDeviceLooks)
                Text("User").tag(OfflinePreviewTarget.whereUserStares)
            } label: {
                let description = switch worldManager.offlinePreviewTarget {
                case .disabled: "It ignores the gesture when disabled."
                case .whereDeviceLooks: "It targets where device looks."
                case .whereUserStares: "It targets where user stares."
                }
                let caption = "Determines how to pick the seed point location when you spatial tap if `Preview mode` is disabled. \(description)"
                CaptionedLabel(title: "Targeting method in Off-line mode",
                               caption: caption)
            }
        }
    }
}
