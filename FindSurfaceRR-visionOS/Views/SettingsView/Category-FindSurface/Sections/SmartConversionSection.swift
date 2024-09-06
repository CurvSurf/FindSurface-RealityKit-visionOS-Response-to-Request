//
//  SmartConversionSection.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 8/26/24.
//

import Foundation
import SwiftUI

import FindSurface_visionOS

struct SmartConversionSection: View {
    
    @Environment(FindSurface.self) private var findSurface
    @Environment(WorldTrackingManager.self) private var worldManager
    
    @State private var allowsCylinderInsteadOfCone: Bool = false
    @State private var allowsCylinderInsteadOfTorus: Bool = false
    @State private var allowsSphereInsteadOfTorus: Bool = false
    
    var body: some View {
        @Bindable var findSurface = findSurface
        @Bindable var worldManager = worldManager
        
        Section("Smart Conversion") {
            
            Toggle(isOn: $worldManager.shouldApplyConversionWithoutPrompt.wrap { !$0 } unwrap: { !$0 }) {
                CaptionedLabel(title: "Show prompt dialog for Smart Conversion",
                               caption: "If enabled, asks whether to convert found geometries according to the conversion options below. Otherwise, applies the conversion automatically without asking (if corresponding options are set).")
            }
            
            CheckboxToggle(value: $allowsCylinderInsteadOfCone) {
                CaptionedLabel(title: "Cone to Cylinder",
                               caption: "Allows `cylinder` as a result when target feature is set to `cone`.")
            }
            .onChange(of: allowsCylinderInsteadOfCone) {
                findSurface.allowsCylinderInsteadOfCone = allowsCylinderInsteadOfCone
            }
            
            CheckboxToggle(value: $allowsCylinderInsteadOfTorus) {
                CaptionedLabel(title: "Torus to Cylinder",
                               caption: "Allows `cylinder` as a result when target feature is set to `torus`.")
            }
            .onChange(of: allowsCylinderInsteadOfTorus) {
                findSurface.allowsCylinderInsteadOfTorus = allowsCylinderInsteadOfTorus
            }
            
            CheckboxToggle(value: $allowsSphereInsteadOfTorus) {
                CaptionedLabel(title: "Torus to Sphere",
                               caption: "Allows `sphere` as a result when target feature is set to `torus`.")
            }
            .onChange(of: allowsSphereInsteadOfTorus) {
                findSurface.allowsSphereInsteadOfTorus = allowsSphereInsteadOfTorus
            }
        }
        .onAppear {
            allowsCylinderInsteadOfCone = findSurface.allowsCylinderInsteadOfCone
            allowsCylinderInsteadOfTorus = findSurface.allowsCylinderInsteadOfTorus
            allowsSphereInsteadOfTorus = findSurface.allowsSphereInsteadOfTorus
        }
    }
}
