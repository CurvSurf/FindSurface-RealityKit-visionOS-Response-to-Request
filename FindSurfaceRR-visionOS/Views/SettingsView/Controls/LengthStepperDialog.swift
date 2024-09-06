//
//  LengthStepperDialog.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 8/30/24.
//

import Foundation
import SwiftUI

struct LengthStepperDialog: View {
    
    enum StepUnit: Hashable, CaseIterable {
        case millimeter
        case centimeter
        case tenCentimeter
        case meter

        var label: String {
            switch self {
            case .millimeter: return "+1 mm"
            case .centimeter: return "+1 cm"
            case .tenCentimeter: return "+10 cm"
            case .meter: return "+1 m"
            }
        }

        var value: Float {
            switch self {
            case .millimeter: return 0.1
            case .centimeter: return 1
            case .tenCentimeter: return 10
            case .meter: return 100
            }
        }
    }
    
    @Binding var value: Float
    let lowerbound: Float
    let upperbound: Float
    @State private var step: StepUnit
    private let includeMeters: Bool
    
    init(value: Binding<Float>,
         lowerbound: Float = -.infinity,
         upperbound: Float = .infinity,
         initialStep: StepUnit = .centimeter,
         includeMeters: Bool = false) {
        self._value = value
        self.lowerbound = lowerbound
        self.upperbound = upperbound
        self._step = State(initialValue: initialStep)
        self.includeMeters = includeMeters
    }
    
    var body: some View {
        HStack {
            Stepper("", value: $value, in: lowerbound...upperbound, step: step.value)
                .labelsHidden()
                .buttonStyle(.borderedProminent)
            
            FixedSizedPicker(items: includeMeters ? StepUnit.allCases : StepUnit.allCases.filter { $0 != .meter },
                             selection: $step) { item in
                item.label
            }
        }
        .padding()
    }
}
