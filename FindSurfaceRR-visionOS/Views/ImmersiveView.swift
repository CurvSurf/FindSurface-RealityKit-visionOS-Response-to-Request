//
//  ImmersiveView.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 6/12/24.
//

import ARKit
import SwiftUI
import RealityKit
import AVKit
import simd

import Combine

import FindSurface_visionOS

@Observable
final class ImmersiveState {
    
    var shouldTakeNextPreviewAsResult: Bool = false
    private var previewTask: Task<(), Never>? = nil
    
    unowned var findSurface: FindSurface!
    unowned var worldManager: WorldTrackingManager!
    unowned var sceneManager: SceneReconstructionManager!
    unowned var uiEntityManager: UIEntityManager!
    unowned var timer: FoundTimer!
    
    init() {
        
    }
    
    private func updatePreview() async {
        while Task.isCancelled == false {
            await performFindSurfaceForPreview()
        }
    }
    
    func restartPreviewUpdateLoop(refreshRate: PreviewSamplingFrequency) {
        if let previewTask {
            previewTask.cancel()
        }
        previewTask = if case .unlimited = refreshRate {
            Task {
                await updatePreview()
            }
        } else {
            Task {
                await run(withFrequency: UInt64(refreshRate.rawValue)) { [self] in
                    await performFindSurfaceForPreview()
                }
            }
        }
    }
    
    private func performFindSurfaceForPreview() async {
        
        let findSurface = FindSurface.instance
        guard let devicePosition = worldManager.devicePosition,
              let deviceDirection = worldManager.deviceDirection else { return }
            
        let targetFeature = findSurface.targetFeature
        
        let origin = devicePosition
        let direction = deviceDirection
        
        guard let hit = await sceneManager.raycast(origin: origin, direction: direction),
              let points = await sceneManager.pickNearestTriangleVertices(hit) else {
            await worldManager.updatePreviewEntity(.none(0),
                                                   location: origin + direction)
            timer.record(found: false)
            return
        }
        
        // TODO: display triangle highlight
        await uiEntityManager.triangleHighlighter.updateTriangle(points.0, points.1, points.2)
        
        let location = hit.position
        
        guard worldManager.previewEnabled else {
            await worldManager.updatePreviewEntity(.none(0),
                                                   location: location)
            return
        }
  
        let result = try? await findSurface.perform {
            let meshPoints = sceneManager.meshPoints
            guard let index = meshPoints.firstIndex(of: points.0) else { return nil }
            return (meshPoints, index)
        }

//        guard let location = await sceneManager.raycast(origin: origin,
//                                                        direction: direction)?.position else {
//            await worldManager.updatePreviewEntity(.none(0),
//                                                   location: origin + direction)
//            timer.record(found: false)
//            return
//        }
//        
//        let result = try? await findSurface.perform {
//            return ([location] + sceneManager.meshPoints, 0)
//        }
        
        
        guard var result else {
            return
        }
        
        result.alignGeometryAndTransformInliers(devicePosition: origin,
                                                worldManager.enableFullConeConversion,
                                                worldManager.fullConeRadiiRatioThreshold)
        
        if case .none = result {
            timer.record(found: false)
        } else {
            timer.record(found: true)
        }
        
        if shouldTakeNextPreviewAsResult {
            shouldTakeNextPreviewAsResult = false
            
            if targetFeature == .any {}
            else if case .foundCylinder = result {
                let coneToCylinder = targetFeature == .cone && findSurface.allowsCylinderInsteadOfCone
                let torusToCylinder = targetFeature == .torus && findSurface.allowsCylinderInsteadOfTorus
                if coneToCylinder || torusToCylinder {
                    guard await userGrantedToApplyConversion(targetFeature: targetFeature,
                                                             foundFeature: .cylinder,
                                                             location: location) else {
                        AudioServicesPlaySystemSound(1053)
                        return
                    }
                }
            } else if case .foundSphere = result {
                let torusToSphere = targetFeature == .torus && findSurface.allowsSphereInsteadOfTorus
                if torusToSphere {
                    guard await userGrantedToApplyConversion(targetFeature: targetFeature,
                                                             foundFeature: .sphere,
                                                             location: location) else {
                        AudioServicesPlaySystemSound(1053)
                        return
                    }
                }
            } else if case .none = result {
                AudioServicesPlaySystemSound(1053)
                return
            }
            
            AudioServicesPlaySystemSound(1100)
            
            await worldManager.addPendingObject(result)
        } else {
            await worldManager.updatePreviewEntity(result, location: location)
        }
    }
    
    func handleSpatialTap(_ location: simd_float3, _ entity: Entity) async throws {
        
        let targetFeature = findSurface.targetFeature
        
        guard let devicePosition = worldManager.devicePosition,
              let deviceDirection = worldManager.deviceDirection,
              worldManager.offlinePreviewTarget != .disabled else { return }
        
        let origin = devicePosition
        let direction = worldManager.offlinePreviewTarget == .whereUserStares ? normalize(location - origin) : deviceDirection
        
        guard let hit = await sceneManager.raycast(origin: origin, direction: direction),
              let points = await sceneManager.pickNearestTriangleVertices(hit) else {
            AudioServicesPlaySystemSound(1053)
            return
        }
        
//        switch worldManager.offlinePreviewTarget {
//        case .whereUserStares:
//            hitPosition = location
//            hitNormal = await sceneManager.raycast(origin: origin,
//                                                   direction: normalize(location - origin))?.normal
//        case .whereDeviceLooks:
//            let hit = await sceneManager.raycast(origin: origin,
//                                                 direction: direction)
//            hitPosition = hit?.position
//            hitNormal = hit?.normal
//            
//        default: fatalError()
//        }
        
        let result = try await findSurface.perform {
            
            await uiEntityManager.flashSeedAreaIndicator(at: hit.position,
                                                         withNormal: hit.normal,
                                                         seedRadius: findSurface.seedRadius)
            
            await uiEntityManager.flashGesturePointIndicator(at: hit.position)
            // TODO: show pointcloud (optional)
            let meshPoints = sceneManager.meshPoints
            guard let index = meshPoints.firstIndex(of: points.0) else { return nil }
            return (meshPoints, index)
        }
        
        guard var result else {
            // TODO: show busy effect
            AudioServicesPlaySystemSound(1053)
            return
        }
        
        if case .none = result {
            AudioServicesPlaySystemSound(1053)
            return
        }
        
        result.alignGeometryAndTransformInliers(devicePosition: origin,
                                                worldManager.enableFullConeConversion,
                                                worldManager.fullConeRadiiRatioThreshold)
        
        if targetFeature == .any {}
        else if case .foundCylinder = result {
            let coneToCylinder = targetFeature == .cone && findSurface.allowsCylinderInsteadOfCone
            let torusToCylinder = targetFeature == .torus && findSurface.allowsCylinderInsteadOfTorus
            if coneToCylinder || torusToCylinder {
                guard await userGrantedToApplyConversion(targetFeature: targetFeature,
                                                         foundFeature: .cylinder,
                                                         location: location) else {
                    AudioServicesPlaySystemSound(1053)
                    return
                }
            }
        } else if case .foundSphere = result {
            let torusToSphere = targetFeature == .torus && findSurface.allowsSphereInsteadOfTorus
            if torusToSphere {
                guard await userGrantedToApplyConversion(targetFeature: targetFeature,
                                                         foundFeature: .sphere,
                                                         location: location) else {
                    AudioServicesPlaySystemSound(1053)
                    return
                }
            }
        } else if case .none = result {
            AudioServicesPlaySystemSound(1053)
            return
        }
        
        AudioServicesPlaySystemSound(1100)
        
        await worldManager.addPendingObject(result)
    }
    
    private func userGrantedToApplyConversion(targetFeature: FeatureType,
                                            foundFeature: FeatureType,
                                            location: simd_float3) async -> Bool {
        
        if worldManager.shouldApplyConversionWithoutPrompt {
            return true
        }
        
        return await uiEntityManager.promptUserForApplyingConversion(targetFeature: targetFeature,
                                                                     foundFeature: foundFeature,
                                                                     location: location)
    }
    
    private var isProcessingGesture = false
    private var initialRadius: Float = 0.01
    
    @MainActor
    var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { [self] value in
                
                if !isProcessingGesture {
                    isProcessingGesture = true
                    initialRadius = findSurface.seedRadius
                    
                    if let devicePosition = worldManager.devicePosition,
                       let deviceDirection = worldManager.deviceDirection {
                        
                        let leftPosition = uiEntityManager.leftHand.jointPosition(.indexFingerTip)
                        let rightPosition = uiEntityManager.rightHand.jointPosition(.indexFingerTip)
                        let indicatorPosition = if let leftPosition,
                            let rightPosition {
                                (leftPosition + rightPosition) * 0.5
                            } else {
                                devicePosition + deviceDirection * 0.5
                            }
                        let position = indicatorPosition + 0.50 * normalize(indicatorPosition - devicePosition)
                        uiEntityManager.seedAreaControl.position = position
                    }
                }
                uiEntityManager.seedAreaControl.isEnabled = true
                
                if let devicePosition = worldManager.devicePosition {
                    let indicator = uiEntityManager.seedAreaControl
                    indicator.look(at: devicePosition,
                                   from: indicator.position,
                                   relativeTo: nil,
                                   forward: .positiveZ)
                    let radius = min(max(initialRadius * Float(value.magnification), 0.05), 10)
                    findSurface.seedRadius = radius
                    uiEntityManager.seedAreaIndicator.radius = radius
                    uiEntityManager.seedAreaControl.radius = radius
                }
            }
            .onEnded { [self] value in
                uiEntityManager.seedAreaControl.isEnabled = false
                isProcessingGesture = false
            }
    }
}

@MainActor
struct ImmersiveView: View {
    
    private enum Attachments: Hashable {
        case control
        case radius
        case result(UUID)
        case warning
        case status
        case confirm
    }
    
    @State private var state = ImmersiveState()
    
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.scenePhase) private var scenePhase
    
    @Environment(SceneReconstructionManager.self) private var sceneManager
    @Environment(WorldTrackingManager.self) private var worldManager
    @Environment(UIEntityManager.self) private var uiEntityManager
    @Environment(FindSurface.self) private var findSurface
    @Environment(SessionManager.self) private var sessionManager
    @Environment(ScenePhaseTracker.self) private var scenePhaseTracker
    @Environment(FoundTimer.self) private var timer
    @Environment(Logger.self) private var logger
    
    init() {
        AnimationSystem.registerSystem()
        AnimationComponent.registerComponent()
    }
    
    private func make(_ content: inout RealityViewContent, _ attachments: RealityViewAttachments) async {
        content.add(sceneManager.rootEntity)
        content.add(worldManager.rootEntity)
        content.add(uiEntityManager.rootEntity)
        
        if let control = attachments.entity(for: Attachments.control) {
            uiEntityManager.controlEntity = control
        }
        
        if let radiusLabel = attachments.entity(for: Attachments.radius) {
            uiEntityManager.seedAreaControl.label = radiusLabel
        }
        
        if let status = attachments.entity(for: Attachments.status) {
            uiEntityManager.statusEntity = status
        }
        
        if let confirm = attachments.entity(for: Attachments.confirm) {
            confirm.isEnabled = false
            uiEntityManager.confirmEntity = confirm
        }
        
        Task {
            await sessionManager.run(with: [sceneManager.sceneReconstruction,
                                            worldManager.worldTracking,
                                            uiEntityManager.handTracking])
        }
    }
    
    private func update(_ content: inout RealityViewContent, _ attachments: RealityViewAttachments) {
        
        for key in uiEntityManager.conversionPrompts.keys {
            guard let attachment = attachments.entity(for: key) else { continue }
            uiEntityManager.registerConversionPromptViewAttachment(attachment, forKey: key)
        }
    }
    
    @AttachmentContentBuilder
    private func attachments() -> some AttachmentContent {
        
        Attachment(id: Attachments.control) {
            ControlView()
                .environment(scenePhaseTracker)
                .environment(sceneManager)
                .environment(worldManager)
                .environment(uiEntityManager)
                .environment(timer)
                .environment(findSurface)
        }
        
        if !uiEntityManager.conversionPrompts.isEmpty {
            ForEach(Array(uiEntityManager.conversionPrompts), id: \.key) { key, prompt in
                Attachment(id: key) {
                    ConversionPromptView(key: key,
                                         targetFeature: prompt.targetFeature,
                                         foundFeature: prompt.foundFeature,
                                         continuation: prompt.continuation)
                    .environment(uiEntityManager)
                    .glassBackgroundEffect()
                }
            }
        }
        
        Attachment(id: Attachments.radius) {
            RadiusLabel()
                .environment(findSurface)
        }
        
        Attachment(id: Attachments.status) {
            StatusView()
                .environment(sceneManager)
                .environment(timer)
                .frame(width: 320)
        }
        
        Attachment(id: Attachments.confirm) {
            ConfirmationDialogView()
                .environment(worldManager)
                .environment(uiEntityManager)
                .environment(scenePhaseTracker)
        }
    }
    
    var body: some View {
        
        RealityView { content, attachments in
            // Add the initial RealityKit content
            await make(&content, attachments)
        } update: { content, attachments in
            update(&content, attachments)
        } attachments: {
            attachments()
        }
        .upperLimbVisibility(.automatic)
        .task {
            await sessionManager.monitorSessionEvents { error in
                openWindow(sceneID: SceneID.error, value: ErrorCode.sessionErrorOccurred(.init(from: error)))
            }
        }
        .task {
            await sceneManager.updateAnchors()
        }
        .task {
            await worldManager.updateAnchors()
        }
        .task {
            await worldManager.updateDeviceTransform { deviceTransform in
                await worldManager.deviceTransformUpdated(deviceTransform)
                await uiEntityManager.deviceTransformUpdated(deviceTransform)
            }
        }
        .task {
            await uiEntityManager.updateAnchors()
        }
        .onChange(of: worldManager.previewEnabled, initial: true) {
            uiEntityManager.triangleHighlighter.isEnabled = !worldManager.previewEnabled
        }
        .onChange(of: worldManager.previewSamplingFrequency, initial: true) {
            state.restartPreviewUpdateLoop(refreshRate: worldManager.previewSamplingFrequency)
        }
        .onSpatialTapGesture(target: sceneManager.rootEntity, action: onTapGesture(_:_:))
        .gesture(state.magnifyGesture)
        .onAppear {
            onAppear()
        }
        .onDisappear {
            onDisappear()
        }
        .onChange(of: scenePhase) {
            onDisappear()
            if scenePhase != .active {
                onScenePhaseNotActive()
            }
        }
    }
    
    private func onTapGesture(_ location: simd_float3, _ entity: Entity) {
        if uiEntityManager.shouldShowConfirmDialog {
            uiEntityManager.shouldShowConfirmDialog = false
            return
        }
        if worldManager.previewEnabled {
            state.shouldTakeNextPreviewAsResult = true
        } else {
            Task {
                do {
                    try await state.handleSpatialTap(location, entity)
                } catch let error as FindSurface.Failure {
                    let errorCode: ErrorCode = switch error {
                    case .memoryAllocationFailure:      .findSurfaceError("memory allocation failed")
                    case let .invalidArgument(reason):  .findSurfaceError(reason)
                    case let .invalidOperation(reason): .findSurfaceError(reason)
                    }
                    openWindow(sceneID: SceneID.error, value: errorCode)
                } catch {
                    openWindow(sceneID: SceneID.error, value: ErrorCode.findSurfaceError("\(error)"))
                }
            }
        }
    }
    
    private func onAppear() {
        
        self.state.findSurface = findSurface
        self.state.worldManager = worldManager
        self.state.sceneManager = sceneManager
        self.state.uiEntityManager = uiEntityManager
        self.state.timer = timer
        self.worldManager.logger = logger
        
        sceneManager.loadFromUserDefaults()
        findSurface.loadFromUserDefaults()
        worldManager.loadPersistentObjects()
        worldManager.loadFromUserDefaults()
        uiEntityManager.loadFromUserDefaults()
    }
    
    private func onDisappear() {
        sceneManager.saveToUserDefaults()
        findSurface.saveToUserDefaults()
        worldManager.savePersistentObjects()
        worldManager.saveToUserDefaults()
        uiEntityManager.saveToUserDefaults()
    }
    
    private func onScenePhaseNotActive() {
        onDisappear()
//        if scenePhaseTracker.activeScene == [.shareWindow] {
//            dismissWindow(scen)
//        }
        if scenePhaseTracker.activeScene.contains(.settings) {
            dismissWindow(sceneID: SceneID.settings, value: SceneID.settings)
        }
        
        if scenePhaseTracker.activeScene.contains(.inspector) {
            dismissWindow(sceneID: SceneID.inspector, value: SceneID.inspector)
        }
    }
}
//
//#Preview(immersionStyle: .mixed) {
//    ImmersiveView()
//}
