//
//  FindSurfaceRR_visionOSApp.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 9/5/24.
//

import SwiftUI

@main
struct FindSurfaceRR_visionOSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }
    }
}
