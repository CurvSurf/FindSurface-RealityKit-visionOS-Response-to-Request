//
//  LabeledToggle.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 8/26/24.
//

import Foundation
import SwiftUI

struct CheckboxToggle<Label: View>: View {
    
    @Binding var value: Bool
    @ViewBuilder let label: () -> Label
    
    init(value: Binding<Bool>,
         label: @escaping () -> Label) {
        self._value = value
        self.label = label
    }
    
    var body: some View {
        Button {
            withAnimation {
                value.toggle()
            }
        } label: {
            SwiftUI.Label {
                label()
            } icon: {
                Image(systemName: "checkmark")
                    .opacity(value ? 1 : 0)
                    .fontWeight(.semibold)
            }
        }
    }
}
