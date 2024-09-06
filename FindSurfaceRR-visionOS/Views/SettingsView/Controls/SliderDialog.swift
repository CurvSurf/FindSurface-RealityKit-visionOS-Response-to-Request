//
//  SliderDialog.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 9/5/24.
//

import Foundation
import SwiftUI

struct SliderDialog<Label: View, ValueLabel: View>: View {
    
    @Binding var value: Float
    let range: ClosedRange<Float>
    let step: Float?
    let label: () -> Label
    let minimumValueLabel: () -> ValueLabel
    let maximumValueLabel: () -> ValueLabel
    
    init(value: Binding<Float>, 
         in range: ClosedRange<Float>,
         step: Float? = nil,
         label: @escaping () -> Label,
         minimumValueLabel: @escaping () -> ValueLabel,
         maximumValueLabel: @escaping () -> ValueLabel) {
        self._value = value
        self.range = range
        self.step = step
        self.label = label
        self.minimumValueLabel = minimumValueLabel
        self.maximumValueLabel = maximumValueLabel
    }
    
    var body: some View {
        Group {
            if let step {
                Slider(value: $value, in: range, step: step) {
                    label()
                } minimumValueLabel: {
                    minimumValueLabel().lineLimit(1).fixedSize()
                } maximumValueLabel: {
                    maximumValueLabel().lineLimit(1).fixedSize()
                }
            } else {
                Slider(value: $value, in: range) {
                    label()
                } minimumValueLabel: {
                    minimumValueLabel().lineLimit(1).fixedSize()
                } maximumValueLabel: {
                    maximumValueLabel().lineLimit(1).fixedSize()
                }
            }
        }
        .padding()
        .frame(width: 500)
    }
}
