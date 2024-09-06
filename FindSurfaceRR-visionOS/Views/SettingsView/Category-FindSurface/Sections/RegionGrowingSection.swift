//
//  RegionGrowingSection.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 8/26/24.
//

import Foundation
import SwiftUI

import FindSurface_visionOS

struct RegionGrowingSection: View {
    
    @Environment(FindSurface.self) private var findSurface
    
    var body: some View {
        @Bindable var findSurface = findSurface
        
        Section("Region Growing") {
            Picker(selection: $findSurface.lateralExtension.animation()) {
                Text("Off").frame(width: 200).tag(SearchLevel.off)
                Text("Level 1 - moderate").tag(SearchLevel.lv1)
                Text("Level 2").tag(SearchLevel.lv2)
                Text("Level 3").tag(SearchLevel.lv3)
                Text("Level 4").tag(SearchLevel.lv4)
                Text("Level 5 - default").tag(SearchLevel.lv5)
                Text("Level 6").tag(SearchLevel.lv6)
                Text("Level 7").tag(SearchLevel.lv7)
                Text("Level 8").tag(SearchLevel.lv8)
                Text("Level 9").tag(SearchLevel.lv9)
                Text("Level 10 - radical").tag(SearchLevel.lv10)
            } label: {
                CaptionedLabel(title: "Lateral Extension")
            }
            
            Picker(selection: $findSurface.radialExpansion.animation()) {
                Text("Off").frame(width: 200).tag(SearchLevel.off)
                Text("Level 1 - moderate").tag(SearchLevel.lv1)
                Text("Level 2").tag(SearchLevel.lv2)
                Text("Level 3").tag(SearchLevel.lv3)
                Text("Level 4").tag(SearchLevel.lv4)
                Text("Level 5 - default").tag(SearchLevel.lv5)
                Text("Level 6").tag(SearchLevel.lv6)
                Text("Level 7").tag(SearchLevel.lv7)
                Text("Level 8").tag(SearchLevel.lv8)
                Text("Level 9").tag(SearchLevel.lv9)
                Text("Level 10 - radical").tag(SearchLevel.lv10)
            } label: {
                CaptionedLabel(title: "Radial Expansion")
            }
        }
    }
}
