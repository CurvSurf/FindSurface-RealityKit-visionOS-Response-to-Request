//
//  BehaviorSettingsView.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 8/26/24.
//

import Foundation
import SwiftUI

struct BehaviorSettingsView: View {
    
    @State private var labelWidth: CGFloat = 0
    @State private var textFieldWidth: CGFloat = .infinity
    @State private var pickerWidth: CGFloat = 0
    
    var body: some View {
        List {
            ConversionBehaviorSection()
            TargetingObjectsSection()
        }
        .padding(.horizontal, 25)
        .toolbar {
            ToolbarItem(placement: .secondaryAction) {
                Text("Behaviors")
                    .font(.title)
            }
        }
    }
    
    struct Title: View {
        var body: some View {
            Label("Behaviors", systemImage: "flowchart")
        }
    }
}
