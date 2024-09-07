//
//  PreviewSamplingFrequency.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 8/7/24.
//

import Foundation

enum PreviewSamplingFrequency: Int, Hashable, CaseIterable {
    case k120Hz = 120
    case k90Hz = 90
    case k60Hz = 60
    case k30Hz = 30
    
    var label: String {
        "\(rawValue) Hz"
    }
}
