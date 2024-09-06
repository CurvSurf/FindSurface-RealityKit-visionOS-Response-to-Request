//
//  InspectorView.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 8/7/24.
//

import Foundation
import SwiftUI

#if targetEnvironment(simulator)
fileprivate struct PreviewActiveTabEnvironmentKey: EnvironmentKey {
    static var defaultValue: ActiveTab = .inspector
}

fileprivate extension EnvironmentValues {
    var previewActiveTab: ActiveTab {
        get { self[PreviewActiveTabEnvironmentKey.self] }
        set { self[PreviewActiveTabEnvironmentKey.self] = newValue }
    }
}
#endif

enum ActiveTab: Int, CaseIterable {
    case inspector = 0
    case logger
}

private struct CurrentDateEnvironmentKey: EnvironmentKey {
    static let defaultValue: Date = .now
}

extension EnvironmentValues {
    var currentDate: Date {
        get { self[CurrentDateEnvironmentKey.self] }
        set { self[CurrentDateEnvironmentKey.self] = newValue }
    }
}

struct InspectorView: View {
    
    #if targetEnvironment(simulator)
    @Environment(\.previewActiveTab) private var previewActiveTab
    #endif
    
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) private var dismiss
    
    @Environment(ScenePhaseTracker.self) private var scenePhaseTracker
    @Environment(WorldTrackingManager.self) private var worldManager
    
    @AppStorage("active-tab") private var activeTab: ActiveTab = .inspector
    
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var currentDate: Date = .now
    
    var body: some View {
        #if targetEnvironment(simulator)
        @Binding(get: { previewActiveTab }, set: { _ in }) var activeTab
        #endif
        VStack(alignment: .leading) {
            TabView(selection: $activeTab) {
                GeometryListView()
                    .tabItem {
                        GeometryListView.Title()
                    }
                    .tag(ActiveTab.inspector)
                
                LogMessageListView()
                    .tabItem {
                        LogMessageListView.Title()
                    }
                    .tag(ActiveTab.logger)
            }
            .tabViewStyle(.automatic)
        }
        .padding()
        .background(.clear.opacity(0))
        .border(Color.white)
        .onReceive(timer) { _ in
            self.currentDate = .now
        }
        .environment(\.currentDate, currentDate)
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

#Preview("GeometryList", windowStyle: .plain) {
    InspectorView()
        .environment(ScenePhaseTracker())
        .environment(WorldTrackingManager.preview)
        .environment(Logger())
}

#Preview("GeometryList(empty)", windowStyle: .plain) {
    InspectorView()
        .environment(ScenePhaseTracker())
        .environment(WorldTrackingManager())
        .environment(Logger())
}

#Preview("MessageList", windowStyle: .plain) {
    InspectorView()
        .environment(ScenePhaseTracker())
        .environment(WorldTrackingManager.preview)
        .environment({
            let logger = Logger()
            let plane = PersistentObject.plane("Plane1", .init(width: 0, height: 0, extrinsics: .init()), [], 0)
            let sphere = PersistentObject.sphere("Sphere2", .init(radius: 0, extrinsics: .init()), [], 0)
            let cylinder = PersistentObject.cylinder("Cylinder3", .init(height: 0, radius: 0, extrinsics: .init()), [], 0)
            let cone = PersistentObject.cone("Cone4", .init(height: 0, topRadius: 0, bottomRadius: 0, extrinsics: .init()), [], 0)
            let torus = PersistentObject.torus("Torus5", .init(meanRadius: 0, tubeRadius: 0, extrinsics: .init()), [], 0, 0, 0)
            logger.add(plane.attr + " has been detected, which is from the previous session.".attr)
            logger.add(sphere.attr + " has been detected, which is from the previous session.".attr)
            logger.add(cylinder.attr + " has been captured by FindSurface.".attr)
            logger.add(cone.attr + " has been captured by FindSurface.".attr)
            logger.add(torus.attr + " has been captured by FindSurface.".attr)
            logger.add(plane.attr + " has been removed.".attr)
            logger.add(sphere.attr + " has been removed.".attr)
            logger.add(cylinder.attr + " has been removed.".attr)
            logger.add(cone.attr + " has been removed.".attr)
            logger.add(torus.attr + " has been removed.".attr)
            return logger
        }())
        #if targetEnvironment(simulator)
        .environment(\.previewActiveTab, .logger)
        #endif
}

#Preview("MessageList(empty)", windowStyle: .plain) {
    InspectorView()
        .environment(ScenePhaseTracker())
        .environment(WorldTrackingManager())
        .environment(Logger())
        #if targetEnvironment(simulator)
        .environment(\.previewActiveTab, .logger)
        #endif
}
