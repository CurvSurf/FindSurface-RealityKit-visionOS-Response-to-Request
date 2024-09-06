//
//  ConversionPromptView.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 8/19/24.
//

import Foundation
import SwiftUI

import FindSurface_visionOS

struct ConversionPrompt {
    let id = UUID()
    let targetFeature: FeatureType
    let foundFeature: FeatureType
    let dialogLocation: simd_float3
    let continuation: CheckedContinuation<Bool, Never>
}

struct ConversionPromptView: View {
    
    @Environment(UIEntityManager.self) private var uiEntityManager
    
    let key: UUID
    let targetFeature: FeatureType
    let foundFeature: FeatureType
    let continuation: CheckedContinuation<Bool, Never>
    
    var body: some View {
        VStack {
            Text("Suggestion")
                .font(.title)
                .padding(.bottom)
            
            Text(try! AttributedString(markdown: "FindSurface has detected **\(foundFeature)** instead of **\(targetFeature)**."))
                .font(.subheadline)
            
            Text("Do you want to keep it?")
            
            HStack {
                
                Button("Keep") {
                    continuation.resume(returning: true)
                    uiEntityManager.deregisterConversionPromptViewAttachment(forKey: key)
                }
                
                Button("Discard", role: .destructive) {
                    continuation.resume(returning: false)
                    uiEntityManager.deregisterConversionPromptViewAttachment(forKey: key)
                }
            }
        }
        .padding()
    }
}

#if targetEnvironment(simulator)
struct PreviewConversionPromptView: View {
    
    let key: UUID
    let targetFeature: FeatureType
    let foundFeature: FeatureType
    
    var body: some View {
        VStack {
            Text("Suggestion")
                .font(.title)
                .padding(.bottom)
            
            Text(try! AttributedString(markdown: "FindSurface has detected **\(foundFeature)** instead of **\(targetFeature)**."))
                .font(.subheadline)
            
            Text("Do you want to keep it?")
            
            HStack {
                
                Button("Keep") {
                }
                
                Button("Discard", role: .destructive) {
                }
            }
        }
        .padding()
    }
}

#Preview(windowStyle: .plain) {

    PreviewConversionPromptView(key: .init(),
                         targetFeature: .torus,
                         foundFeature: .sphere)
        .environment(UIEntityManager())
        .glassBackgroundEffect()
}

#endif
