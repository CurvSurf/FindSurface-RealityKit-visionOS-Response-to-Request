//
//  PercentageStepperDialog.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 8/30/24.
//

import Foundation
import SwiftUI

struct PercentageStepperDialog: View {
    
    enum StepUnit: Hashable, CaseIterable {
        case tenths
        case ones
        case fives
        case tens
        
        var label: String {
            switch self {
            case .tenths: return "+0.1 %"
            case .ones: return "+1 %"
            case .fives: return "+5 %"
            case .tens: return "+10 %"
            }
        }
        
        var value: Float {
            switch self {
            case .tenths: return 0.1
            case .ones: return 1
            case .fives: return 5
            case .tens: return 10
            }
        }
    }
    
    @Binding var value: Float
    let lowerbound: Float
    let upperbound: Float
    @State private var step: StepUnit
    
    init(value: Binding<Float>,
         lowerbound: Float = .zero,
         upperbound: Float = 100,
         initialStep: StepUnit = .ones) {
        self._value = value
        self.lowerbound = lowerbound
        self.upperbound = upperbound
        self._step = State(initialValue: initialStep)
    }
    
    var body: some View {
        HStack {
            Stepper("", value: $value, in: lowerbound...upperbound, step: step.value)
                .labelsHidden()
                .buttonStyle(.borderedProminent)
            
            FixedSizedPicker(selection: $step) { item in
                item.label
            }
        }
        .padding()
    }
}

