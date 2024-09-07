//
//  FeatureTypePicker.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 7/16/24.
//

import Foundation
import SwiftUI

import FindSurface_visionOS

struct FeatureTypePicker: View {
    
    @Binding var type: FeatureType
    let allowAny: Bool
    
    init(type: Binding<FeatureType>, allowAny: Bool = false) {
        self._type = type
        self.allowAny = allowAny
    }
    
    var body: some View {
        let items = if allowAny {
            FeatureType.allCases
        } else {
            FeatureType.allCases.filter { $0 != .any }
        }
        ImageButtonPicker(items: items, selectedItem: $type)
            .allowsHitTesting(true)
    }
}

extension FeatureType: ImageButtonPickerItem {
    
    var imageName: ImageName {
        switch self {
        case .any:      return .systemName("questionmark")
        case .plane:    return .systemName("square")
        case .sphere:   return .systemName("basketball")
        case .cylinder: return .systemName("cylinder")
        case .cone:     return .systemName("cone")
        case .torus:    return .systemName("torus")
        }
    }
    
    var imageForegroundStyle: some ShapeStyle {
        Color.black
    }
    
    var buttonBackground: some View {
        switch self {
        case .any:      return Color.gray
        case .plane:    return Color.red
        case .sphere:   return Color.green
        case .cylinder: return Color.purple
        case .cone:     return Color.cyan
        case .torus:    return Color.yellow
        }
    }
    
    var accessibilityInputLabels: [String] {
        switch self {
        case .any:      return ["Any", "Anything", "Any Kind", "Auto"]
        case .plane:    return ["Plane"]
        case .sphere:   return ["Sphere", "Ball"]
        case .cylinder: return ["Cylinder"]
        case .cone:     return ["Cone"]
        case .torus:    return ["Torus", "Donut"]
        }
    }
}