//
//  FindSurfaceRR_visionOSApp.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 6/12/24.
//

import SwiftUI

import FindSurface_visionOS

@main
@MainActor
struct FindSurfaceRR_visionOSApp: App {
    
    @State private var sessionManager = SessionManager()
    @State private var sceneReconstructionManager = SceneReconstructionManager()
    @State private var worldTrackingManager = WorldTrackingManager()
    @State private var uiEntityManager = UIEntityManager()
    @State private var findSurface = FindSurface.instance
    @State private var scenePhaseTracker = ScenePhaseTracker()
    @State private var timer: FoundTimer
    @State private var logger = Logger()
    
    init() {
        let previewFrequency: PreviewSamplingFrequency = UserDefaults.Adapter<WorldTrackingManager.DefaultKey>().enum(forKey: .previewSamplingFrequency) ?? .k90Hz
        let eventsCount = if case .unlimited = previewFrequency {
            15
        } else {
            (previewFrequency.rawValue / 10) + 1
        }
        let timer = FoundTimer(eventsCount: eventsCount)
        self._timer = State(initialValue: timer)
    }
    
    var body: some Scene {
        
        WindowGroup(sceneID: SceneID.startup, for: SceneID.self) { _ in
            StartupView()
                .environment(sessionManager)
                .trackingScenePhase(by: scenePhaseTracker, sceneID: .startup)
                .glassBackgroundEffect()
        }
        .windowResizability(.contentSize)
        .windowStyle(.plain)

        ImmersiveSpace(sceneID: SceneID.immersiveSpace) {
            ImmersiveView()
                .environment(sceneReconstructionManager)
                .environment(worldTrackingManager)
                .environment(uiEntityManager)
                .environment(findSurface)
                .environment(sessionManager)
                .environment(scenePhaseTracker)
                .environment(timer)
                .environment(logger)
                .trackingScenePhase(by: scenePhaseTracker, sceneID: .immersiveSpace)
                .onChange(of: worldTrackingManager.previewSamplingFrequency) { oldValue, newValue in
                    if oldValue != newValue {
                        let eventsCount = if case .unlimited = newValue {
                            15
                        } else {
                            (newValue.rawValue / 10) + 1
                        }
                        timer.resize(eventsCount: eventsCount)
                    }
                }
        }
        
        WindowGroup(sceneID: SceneID.settings, for: SceneID.self) { _ in
            SettingsView()
                .environment(sessionManager)
                .environment(findSurface)
                .environment(sceneReconstructionManager)
                .environment(worldTrackingManager)
                .environment(uiEntityManager)
                .environment(scenePhaseTracker)
                .environment(timer)
                .trackingScenePhase(by: scenePhaseTracker, sceneID: .settings)
        }
        .windowResizability(.contentSize)
        .windowStyle(.plain)
        
        WindowGroup(sceneID: SceneID.inspector, for: SceneID.self) { _ in
            InspectorView()
                .environment(worldTrackingManager)
                .environment(logger)
                .environment(scenePhaseTracker)
                .trackingScenePhase(by: scenePhaseTracker, sceneID: .inspector)
        }
        .windowStyle(.plain)
        .windowResizability(.automatic)
        .defaultSize(width: 1000, height: 668)
        
        WindowGroup(sceneID: SceneID.userGuide, for: SceneID.self) { _ in
            UserGuideView()
                .environment(scenePhaseTracker)
                .trackingScenePhase(by: scenePhaseTracker, sceneID: .userGuide)
                .glassBackgroundEffect()
        }
        .windowResizability(.contentSize)
        .windowStyle(.plain)
        
        WindowGroup(sceneID: SceneID.error, for: ErrorCode.self) { errorCode in
            if let errorCode = errorCode.wrappedValue {
                ErrorView(errorCode: errorCode)
                    .trackingScenePhase(by: scenePhaseTracker, sceneID: .error)
                    .glassBackgroundEffect()
            }
        }
        .windowResizability(.contentSize)
        .windowStyle(.plain)
        
        WindowGroup(sceneID: SceneID.share, for: URL.self) { url in
            if let url = url.wrappedValue {
                ShareView(url: url) {
                    logger.add("\(worldTrackingManager.geometryKeys.count) objects has been exported as .usda.")
                }
                .environment(scenePhaseTracker)
                .trackingScenePhase(by: scenePhaseTracker, sceneID: .share)
                .frame(width: 600, height: 420)
                .frame(minWidth: 600, maxWidth: 600, minHeight: 420, maxHeight: 420)
                .glassBackgroundEffect()
            }
        }
        .windowResizability(.contentSize)
        .windowStyle(.plain)
    }
}
