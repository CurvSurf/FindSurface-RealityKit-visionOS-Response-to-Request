//
//  GraphicsHandSection.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 8/26/24.
//

import Foundation
import SwiftUI

struct GraphicsHandSection: View {
    
    @Environment(UIEntityManager.self) private var uiEntityManager
    
    var body: some View {
        @Bindable var uiManager = uiEntityManager
        Section("Hand Tracking") {
            
            Toggle(isOn: $uiManager.showHands) {
                CaptionedLabel(title: "Enable Hand Joints Entities",
                               caption: "Renders visual indicators for joints of hand skeleton tracked by ARKit.")
            }
            
            if uiManager.showHands {
                Picker(selection: $uiManager.handsVisibility) {
                    Text("Both hands").tag(HandsVisibility.both)
                    Text("Left only").tag(HandsVisibility.left)
                    Text("Right only").tag(HandsVisibility.right)
                    Text("None").tag(HandsVisibility.none)
                } label: {
                    CaptionedLabel(title: "Visible Hands")
                }

            }
        }
    }
}
