//
//  GraphicsUIAnchorSection.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 9/2/24.
//

import Foundation
import SwiftUI

struct GraphicsUIAnchorSection: View {
    
    @Environment(UIEntityManager.self) private var uiEntityManager
    
    var body: some View {
        @Bindable var uiManager = uiEntityManager
        Section("UI Anchor") {
            
            HStack {
                let description: String = switch uiManager.statusPosition {
                case .control: "Status view will be included in the Controls window."
                case .device: "Status view will stay in your sight."
                case .wrist: "Status view will follow the wrist of your left hand."
                }
                CaptionedLabel(title: "Real-time Status View Position",
                               caption: "Determines the position of the status view that displays FPS and the number of input points. \(description)")
                
                Spacer()
                FixedSizedPicker(selection: $uiManager.statusPosition) { status in
                    switch status {
                    case .control: return "Control"
                    case .device: return "Device"
                    case .wrist: return "Wrist (Left Hand)"
                    }
                }
                .onChange(of: uiManager.statusPosition, initial: true) {
                    uiManager.statusEntity?.isEnabled = uiManager.statusPosition != .control
                }
            }
            
            if uiManager.statusPosition == .device {
                
                HStack {
                    CaptionedLabel(title: "Reset to default values",
                                   caption: "Sets the offset to the recommended default values.")
                    Spacer()
                    
                    Button("Reset") {
                        uiManager.statusDeviceAnchorOffset = .init(0.15, -0.04, 0.03)
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                let xBinding = $uiManager.statusDeviceAnchorOffset.x.mapMeterToCentimeter()
                NumericTextField(value: xBinding) {
                    LengthStepperDialog(value: xBinding)
                } label: {
                    CaptionedLabel(title: "Device Anchor Offset X [cm]")
                }
                
                let yBinding = $uiManager.statusDeviceAnchorOffset.y.mapMeterToCentimeter()
                NumericTextField(value: yBinding) {
                    LengthStepperDialog(value: yBinding)
                } label: {
                    CaptionedLabel(title: "Device Anchor Offset Y [cm]")
                }
                
                let zBinding = $uiManager.statusDeviceAnchorOffset.z.mapMeterToCentimeter()
                NumericTextField(value: zBinding) {
                    LengthStepperDialog(value: zBinding)
                } label: {
                    CaptionedLabel(title: "Device Anchor Offset Z [cm]")
                }
            }
            
            if uiManager.statusPosition == .wrist {
                
                HStack {
                    CaptionedLabel(title: "Reset to default values",
                                   caption: "Sets the offset to the recommended default values.")
                    Spacer()
                    
                    Button("Reset") {
                        uiManager.statusWristAnchorOffset = .init(0, 0.10, 0)
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Toggle(isOn: $uiManager.showAxisIndicator) {
                    CaptionedLabel(title: "Show Axis Indicator (Left hand wrist)",
                                   caption: "Show axis indicator over the wrist of your left hand.")
                }
                
                let xBinding = $uiManager.statusWristAnchorOffset.x.mapMeterToCentimeter()
                NumericTextField(value: xBinding,
                                  lowerbound: -20,
                                  upperbound: 20) {
                    SliderDialog(value: xBinding, in: -20...20, step: 0.1) {
                        Text("Value: \(xBinding.wrappedValue) cm")
                    } minimumValueLabel: {
                        Text("-20 cm")
                    } maximumValueLabel: {
                        Text("20 cm")
                    }

                } label: {
                    CaptionedLabel(title: "Wrist Anchor Offset X [cm]",
                                   caption: "Moves status view along the red arrow in the axis indicator.")
                }
                
                let yBinding = $uiManager.statusWristAnchorOffset.y.mapMeterToCentimeter()
                NumericTextField(value: yBinding,
                                  lowerbound: 0,
                                  upperbound: 20) {
                    SliderDialog(value: yBinding, in: 0...20, step: 0.1) {
                        Text("Value: \(yBinding.wrappedValue) cm")
                    } minimumValueLabel: {
                        Text("0 cm")
                    } maximumValueLabel: {
                        Text("20 cm")
                    }

                } label: {
                    CaptionedLabel(title: "Wrist Anchor Offset Y [cm]",
                                   caption: "Moves status view along the green arrow in the axis indicator.")
                }
                
                let zBinding = $uiManager.statusWristAnchorOffset.z.mapMeterToCentimeter()
                NumericTextField(value: zBinding,
                                  lowerbound: -100,
                                  upperbound: 0) {
                    SliderDialog(value: zBinding, in: -100...0, step: 0.1) {
                        Text("Value: \(zBinding.wrappedValue) cm")
                    } minimumValueLabel: {
                        Text("-100 cm")
                    } maximumValueLabel: {
                        Text("0 cm")
                    }

                } label: {
                    CaptionedLabel(title: "Wrist Anchor Offset Z [cm]",
                                   caption: "Moves status view along the blue arrow in the axis indicator.")
                }
            }
        }
    }
}
