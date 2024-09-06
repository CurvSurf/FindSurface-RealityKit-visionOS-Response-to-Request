//
//  SettingsView.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 8/26/24.
//

import Foundation
import SwiftUI

#if targetEnvironment(simulator)
fileprivate struct PreviewActiveCategoryEnvironmentKey: EnvironmentKey {
    static var defaultValue: SettingsView.Category = .findSurface
}

fileprivate extension EnvironmentValues {
    var previewActiveCategory: SettingsView.Category {
        get { self[PreviewActiveCategoryEnvironmentKey.self] }
        set { self[PreviewActiveCategoryEnvironmentKey.self] = newValue }
    }
}
#endif

@MainActor
struct SettingsView: View {
    
    #if targetEnvironment(simulator)
    @Environment(\.previewActiveCategory) private var previewActiveCategory
    #endif
    
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) private var dismiss
    @Environment(ScenePhaseTracker.self) private var scenePhaseTracker
    
    enum Category: Int, CaseIterable, Hashable, Identifiable {
        
        case findSurface = 0
        case behaviors
        case graphics
        
        var id: Self { return self }
        
        @ViewBuilder
        var label: some View {
            switch self {
            case .findSurface: Label("FindSurface", systemImage: "questionmark")
            case .behaviors: BehaviorSettingsView.Title()
            case .graphics: GraphicsSettingsView.Title()
            }
        }
    }

    @AppStorage("active-category") private var activeCategory: Category?
    
    var body: some View {
        #if targetEnvironment(simulator)
        @Binding(get: { previewActiveCategory }, set: { _ in }) var activeCategory: Category?
        #endif
        NavigationSplitView {
            List(Category.allCases, selection: $activeCategory) { category in
                NavigationLink(value: category) {
                    category.label
                }
            }
            .navigationTitle("Settings")
        } detail: {
            if let activeCategory {
                switch activeCategory {
                case .findSurface:
                    FindSurfaceSettingsView()
                case .behaviors:
                    BehaviorSettingsView()
                case .graphics:
                    GraphicsSettingsView()
                }
            }
        }
        .frame(width: 1280)
        .frame(minWidth: 1280, maxWidth: 1280)
        .onAppear {
            #if !targetEnvironment(simulator)
            if scenePhaseTracker.activeScene.contains(.immersiveSpace) == false {
                openWindow(sceneID: SceneID.startup, value: SceneID.startup)
                dismiss()
            }
            #endif
        }
    }
}

import FindSurface_visionOS

#Preview("Settings(FindSurface)") {
    SettingsView()
        .environment(FindSurface.instance.defaultLoaded)
        .environment(SceneReconstructionManager())
        .environment(WorldTrackingManager())
        .environment(UIEntityManager())
        .environment(ScenePhaseTracker())
}

#Preview("Settings(Behaviors)") {
    SettingsView()
        .environment(FindSurface.instance.defaultLoaded)
        .environment(SceneReconstructionManager())
        .environment(WorldTrackingManager())
        .environment(UIEntityManager())
        .environment(ScenePhaseTracker())
    #if targetEnvironment(simulator)
        .environment(\.previewActiveCategory, .behaviors)
    #endif
}

#Preview("Settings(Graphics)") {
    SettingsView()
        .environment(FindSurface.instance.defaultLoaded)
        .environment(SceneReconstructionManager())
        .environment(WorldTrackingManager())
        .environment(UIEntityManager())
        .environment(ScenePhaseTracker())
    #if targetEnvironment(simulator)
        .environment(\.previewActiveCategory, .graphics)
    #endif
}
