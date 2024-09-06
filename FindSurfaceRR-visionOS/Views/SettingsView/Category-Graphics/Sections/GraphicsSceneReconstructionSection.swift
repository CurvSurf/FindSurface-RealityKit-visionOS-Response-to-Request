//
//  MeshSection.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 8/26/24.
//

import Foundation
import SwiftUI

struct GraphicsSceneReconstructionSection: View {
    
    @Environment(SceneReconstructionManager.self) private var sceneManager
    
    var body: some View {
        @Bindable var sceneManager = sceneManager
        Section("Scene Reconstruction") {
            
            Toggle(isOn: $sceneManager.shouldShowUpdateAnimation) {
                CaptionedLabel(title: "Show animation effect for mesh updates",
                               caption: "Plays flashing animation effect whenever meshes get updated.")
                Text("⚠️ WARNING: This option is debug purpose only and may trigger seizures for people with photosensitive epilepsy.")
                    .font(.caption.bold())
                    .frame(width: 500, alignment: .leading)
            }
        }
    }
}
