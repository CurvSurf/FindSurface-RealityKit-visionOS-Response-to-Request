//
//  GraphicsGeometrySection.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 8/26/24.
//

import Foundation
import SwiftUI

struct GraphicsGeometrySection: View {
    
    @Environment(WorldTrackingManager.self) private var worldManager
    
    var body: some View {
        @Bindable var worldManager = worldManager
        Section("Geometry") {
            
            Toggle(isOn: $worldManager.isGeometryOutlineVisible) {
                CaptionedLabel(title: "Show geometry outline")
            }
            
            Toggle(isOn: $worldManager.areInlierPointVisible) {
                CaptionedLabel(title: "Show inlier points",
                               caption: "Renders points considered to be included in geometries. This feature significantly impacts performance, so it is recommended to disable it.")
            }
        }
    }
}
