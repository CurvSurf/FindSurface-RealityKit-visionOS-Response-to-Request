//
//  ControlView.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 7/16/24.
//

import Foundation
import SwiftUI

import FindSurface_visionOS

#if targetEnvironment(simulator)
fileprivate struct PreviewShouldShowConfirmDialogEnvironmentKey: EnvironmentKey {
    static var defaultValue: Bool = false
}

extension EnvironmentValues {
    fileprivate var previewShouldShowConfirmDialog: Bool {
        get { self[PreviewShouldShowConfirmDialogEnvironmentKey.self] }
        set { self[PreviewShouldShowConfirmDialogEnvironmentKey.self] = newValue }
    }
}
#endif

struct ControlView: View {
    
    #if targetEnvironment(simulator)
    @Environment(\.previewShouldShowConfirmDialog) private var previewShouldShowConfirmDialog
    #endif
    
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    @Environment(ScenePhaseTracker.self) private var scenePhaseTracker
    @Environment(SceneReconstructionManager.self) private var sceneManager
    @Environment(WorldTrackingManager.self) private var worldManager
    @Environment(UIEntityManager.self) private var uiEntityManager
    @Environment(FindSurface.self) private var findSurface
    @Environment(FoundTimer.self) private var timer
    
    @AppStorage("allow-feature-type-any")
    private var allowFeatureTypeAny: Bool = false
    
    var body: some View {
        @Bindable var findSurface = findSurface
        @Bindable var sceneManager = sceneManager
        @Bindable var worldManager = worldManager
        @Bindable var uiManager = uiEntityManager
        
        #if targetEnvironment(simulator)
        let showConfirmDialog = previewShouldShowConfirmDialog
        #else
        let showConfirmDialog = uiManager.shouldShowConfirmDialog
        #endif
        
        VStack {
            Section {
                VStack(alignment: .leading) {
                    FeatureTypePicker(type: $findSurface.targetFeature)
                        .onChange(of: allowFeatureTypeAny) {
                            if !allowFeatureTypeAny && findSurface.targetFeature == .any {
                                findSurface.targetFeature = .plane
                            }
                        }
                    
                    if uiEntityManager.statusPosition == .control {
                        StatusView()
                    }
                    
                    InspectorWindowToggleButton()
                    SettingsWindowToggleButton()
                    MeshVisibilityToggleButton()
                    PreviewToggleButton()
                    ExportUSDAButton()
                    ClearButton()
                }
            } header: {
                HStack {
                    Text("Controls")
                        .font(.title.monospaced())
                    Spacer()
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8).stroke(.white, lineWidth: 1))
        .frame(width: allowFeatureTypeAny ? 380 : 320)
        .disabled(showConfirmDialog)
        .blur(radius: showConfirmDialog ? 3.0 : 0.0)
        .broadcastStringMaxLength()
    }
}

#Preview("ControlView", windowStyle: .plain) {
    ControlView()
        .environment(ScenePhaseTracker())
        .environment(SceneReconstructionManager())
        .environment(WorldTrackingManager())
        .environment(UIEntityManager())
        .environment(FoundTimer(eventsCount: 5))
        .environment(FindSurface.instance.defaultLoaded)
    #if targetEnvironment(simulator)
        .environment(\.previewShouldShowConfirmDialog, false)
    #endif
}

#Preview("ControlView(blur)", windowStyle: .plain) {
    ControlView()
        .environment(ScenePhaseTracker())
        .environment(SceneReconstructionManager())
        .environment(WorldTrackingManager())
        .environment(UIEntityManager())
        .environment(FoundTimer(eventsCount: 5))
        .environment(FindSurface.instance.defaultLoaded)
#if targetEnvironment(simulator)
    .environment(\.previewShouldShowConfirmDialog, true)
#endif
}
