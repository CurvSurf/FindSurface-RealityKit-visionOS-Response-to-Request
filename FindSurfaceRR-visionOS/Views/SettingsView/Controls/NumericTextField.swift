//
//  NumericTextField.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 8/30/24.
//

import Foundation
import SwiftUI

struct NumericTextField<Label: View, Control: View>: View {
    
    @Binding var value: Float
    let lowerbound: Float
    let upperbound: Float
    @ViewBuilder let control: () -> Control
    @ViewBuilder let label: () -> Label
    
    init(value: Binding<Float>,
         lowerbound: Float = -.infinity,
         upperbound: Float = .infinity,
         control: @escaping () -> Control,
         label: @escaping () -> Label) {
        self._value = value
        self.lowerbound = lowerbound
        self.upperbound = upperbound
        self.control = control
        self.label = label
    }
    
    @State private var showPopover: Bool = false
    
    var body: some View {
        HStack {
            label()
            
            let binding = $value
            let formatter = Formatter.decimal(1)
            TextField("", value: binding, formatter: formatter) { finished in
                if finished { validate() }
            }
            .multilineTextAlignment(.trailing)
            .textFieldStyle(.roundedBorder)
            .keyboardType(.decimalPad)
            .allowsHitTesting(true)
            .popover(isPresented: $showPopover) {
                control()
            }
            
            Button {
                withAnimation {
                    showPopover = true
                }
            } label: {
                Image(systemName: "slider.horizontal.3")
            }
            .hoverEffect()
            .clipShape(.circle)
            .buttonStyle(.bordered)
        }
    }
    
    private func validate() {
        value = min(max(value, lowerbound), upperbound)
    }
}
