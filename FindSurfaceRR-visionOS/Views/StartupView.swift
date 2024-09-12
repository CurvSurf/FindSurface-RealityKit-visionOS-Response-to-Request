//
//  StartupView.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 6/12/24.
//

import SwiftUI
import RealityKit

struct StartupView: View {

    @Environment(SessionManager.self) private var sessionManager
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack {
            AppTitle()
            IntroductionText()
            Proclaimer()
            
            HStack {
                OpenUserGuideButton()
                EnterImmersiveSpaceButton()
            }
            .padding(.top, 10)
        }
        .padding(.vertical, 24)
        .fixedSize()
        .onChange(of: scenePhase, initial: true) {
            if scenePhase == .active {
                Task {
                    await sessionManager.queryRequiredAuthorizations()
                }
            }
        }
        .task {
            if sessionManager.allRequiredProvidersAreSupported {
                await sessionManager.requestRequiredAuthorizations()
            }
        }
        .task {
            await sessionManager.monitorSessionEvents { error in
                openWindow(sceneID: SceneID.error, value: ErrorCode.sessionErrorOccurred(.init(from: error)))
            }
        }
    }
}

fileprivate struct AppTitle: View {
    var body: some View {
        Text("FindSurfaceRR for visionOS")
            .font(.title)
            .padding(.bottom, 10)
    }
}

fileprivate struct IntroductionText: View {
    var body: some View {
        
        Text("Find and measure 3D surface geometries in your physical environment with continuous preview.")
            .font(.subheadline)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 30)
            .frame(width: 400)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, 16)
    }
}

fileprivate struct Proclaimer: View {
    var body: some View {
        
        Text("PROCLAIMER")
            .font(.footnote.bold())
        
        Text("This app uses the vertex data extracted from MeshAnchor, so it may not detect or accurately detect objects with a size (approximate diameter or width) less than 1 meter.")
            .font(.caption)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 30)
            .frame(width: 400)
            .fixedSize(horizontal: false, vertical: true)
    }
}

fileprivate struct OpenUserGuideButton: View {
    
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        Button("User Guide") {
            openWindow(sceneID: SceneID.userGuide, value: SceneID.userGuide)
        }
    }
}

fileprivate struct EnterImmersiveSpaceButton: View {
    
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Button("Enter") {
            Task { await tryEnterImmersiveSpace() }
        }
    }
    
    @MainActor
    private func tryEnterImmersiveSpace() async {
        switch await openImmersiveSpace(sceneID: SceneID.immersiveSpace) {
        case .opened: dismiss()
        case .error:
            await dismissImmersiveSpace()
            openWindow(sceneID: SceneID.error, value: ErrorCode.openImmersiveSpaceFailed)
        case .userCancelled: fallthrough
        @unknown default:
            await dismissImmersiveSpace()
        }
    }
}

#Preview(windowStyle: .plain) {
    StartupView()
        .environment(SessionManager())
        .glassBackgroundEffect()
}
