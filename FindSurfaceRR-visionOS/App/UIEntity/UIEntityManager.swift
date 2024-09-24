//
//  UIEntityManager.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 8/8/24.
//

import Foundation
import ARKit
import RealityKit
import Combine
import _RealityKit_SwiftUI

import FindSurface_visionOS


enum HandsVisibility: Int {
    case none = 0
    case left
    case right
    case both
}

enum StatusPosition: Int, CaseIterable {
    case control
    case wrist
    case device
}

@Observable
final class UIEntityManager {
    
    let handTracking = HandTrackingProvider()
    
    @MainActor
    func updateAnchors() async {
        for await update in handTracking.anchorUpdates {
            await anchorUpdated(update.anchor)
        }
    }
    
    @MainActor
    init() {
        let rootEntity = Entity()
        
        let hands = Entity()
        hands.name = "Hands"
        rootEntity.addChild(hands)
        
        let leftHand = HandEntity()
        leftHand.name = "Hand (left)"
        hands.addChild(leftHand)
        
        let rightHand = HandEntity()
        rightHand.name = "Hand (right))"
        hands.addChild(rightHand)
        
        let seedAreaIndicator = SeedAreaIndicator()
        seedAreaIndicator.name = "Seed Area Indicator"
        seedAreaIndicator.isEnabled = false
        rootEntity.addChild(seedAreaIndicator)
        
        let seedAreaControl = SeedAreaControl()
        seedAreaControl.name = "Seed Area Control"
        seedAreaControl.isEnabled = false
        rootEntity.addChild(seedAreaControl)
        
        let gesturePointIndicator = ModelEntity(mesh: .generateBox(size: 0.02, cornerRadius: 0.005),
                                                materials: [SimpleMaterial(color: .green, roughness: 0.75, isMetallic: true)])
        gesturePointIndicator.name = "Gesture Point Indicator"
        gesturePointIndicator.isEnabled = false
        rootEntity.addChild(gesturePointIndicator)
        
        let axisIndicator = AxisIndicator()
        axisIndicator.name = "Axis Indicator"
        axisIndicator.isEnabled = false
        rootEntity.addChild(axisIndicator)
        
        self.rootEntity = rootEntity
        self.hands = hands
        self.leftHand = leftHand
        self.rightHand = rightHand
        self.seedAreaIndicator = seedAreaIndicator
        self.seedAreaControl = seedAreaControl
        self.gesturePointIndicator = gesturePointIndicator
        self.axisIndicator = axisIndicator
    }
    
    let rootEntity: Entity
    
    // - MARK: Device Tracking
    private var deviceTransform: simd_float4x4? = nil
    
    @MainActor
    func deviceTransformUpdated(_ transform: simd_float4x4) async {
        deviceTransform = transform
        
        initializeControlPanelLocation(transform)
        orientConversionPromptViewAttachmentEntities(transform)
        updateStatusLocation(transform)
    }
    
    
    // - MARK: Control Panel
    var controlEntity: ViewAttachmentEntity? {
        didSet {
            if let oldValue {
                oldValue.removeFromParent()
            }
            if let controlEntity {
                rootEntity.addChild(controlEntity)
                shouldLocateControlInitially = true
            }
        }
    }
    
    private var shouldLocateControlInitially = false
    @MainActor
    private func initializeControlPanelLocation(_ deviceTransform: simd_float4x4) {
        
        guard let controlEntity,
              shouldLocateControlInitially else { return }
        
        let devicePosition = deviceTransform.position
        let deviceForward = -deviceTransform.basisZ
        let deviceRight = deviceTransform.basisX
        
        let location = devicePosition + 0.7 * normalize(deviceForward + deviceRight)
        controlEntity.look(at: devicePosition,
                           from: location,
                           relativeTo: nil,
                           forward: .positiveZ)
        shouldLocateControlInitially = false
        
        locateConfirmDialog(devicePosition, location)
    }
    
    var shouldShowControl: Bool = true {
        didSet {
            controlEntity?.isEnabled = shouldShowControl
        }
    }
    var shouldShowInspector: Bool = true
    
    
    // - MARK: Hand Tracking
    let hands: Entity
    let leftHand: HandEntity
    let rightHand: HandEntity
    
    @MainActor
    var handsVisibility: HandsVisibility {
        get {
            access(keyPath: \.handsVisibility)
            return leftHand.shouldDraw ? rightHand.shouldDraw ? .both : .left : rightHand.shouldDraw ? .right : .none
        }
        set {
            withMutation(keyPath: \.handsVisibility) {
                leftHand.shouldDraw = newValue == .both || newValue == .left
                rightHand.shouldDraw = newValue == .both || newValue == .right
            }
        }
    }
    
    @MainActor
    var showHands: Bool {
        get {
            access(keyPath: \.showHands)
            return hands.isEnabled
        }
        set {
            withMutation(keyPath: \.showHands) {
                hands.isEnabled = newValue
            }
        }
    }
    
    @MainActor
    private func anchorUpdated(_ anchor: HandAnchor) async {
        switch anchor.chirality {
        case .right:    
            rightHand.update(anchor)
            updateControlPanelLocation()
            updateStatusLocationByWrist()
        case .left:
            leftHand.update(anchor)
            updateAxisIndicator()
            break
        }
    }
    
    private var middleFingerDragCount: Int = 0
    
    @MainActor
    private func updateControlPanelLocation() {
        
        guard let deviceTransform,
              let controlEntity,
              rightHand.isTracked else {
            middleFingerDragCount = max(middleFingerDragCount - 1, 0)
            return
        }
        
        let devicePosition = deviceTransform.position
        let deviceRight = deviceTransform.basisX
        
        guard let thumbPosition = rightHand.jointPosition(.thumbTip),
              let middleFingerPosition = rightHand.jointPosition(.middleFingerTip),
              let wristPosition = rightHand.jointPosition(.wrist) else {
            middleFingerDragCount = max(middleFingerDragCount - 1, 0)
            return
        }
        
        if distance_squared(thumbPosition, middleFingerPosition) < 0.0001 {
            middleFingerDragCount = min(middleFingerDragCount + 1, 5)
        } else {
            middleFingerDragCount = max(middleFingerDragCount - 1, 0)
        }
        
        if middleFingerDragCount > 3 {
            let position = (thumbPosition + middleFingerPosition) * 0.5
            
            let direction = normalize(position - wristPosition)
//            let outward = normalize(cross(direction, .init(0, 1, 0)))
            let outward = normalize(.init(-direction.z, 0, direction.x))
            let right = deviceRight
            
            let location = wristPosition + normalize(outward + direction) * 0.3 + .init(0, 0.2, 0) - right * 0.30
            
            controlEntity.isEnabled = true
            controlEntity.look(at: devicePosition,
                               from: location,
                               relativeTo: nil,
                               forward: .positiveZ)
            
            locateConfirmDialog(devicePosition, location)
        }
    }
    
    
    // - MARK: Conversion Prompt
    private(set) var conversionPrompts: [UUID: ConversionPrompt] = [:]
    func promptUserForApplyingConversion(targetFeature: FeatureType,
                                         foundFeature: FeatureType,
                                         location: simd_float3) async -> Bool {
        return await withCheckedContinuation { continuation in
            let conversionPrompt = ConversionPrompt(targetFeature: targetFeature,
                                                    foundFeature: foundFeature,
                                                    dialogLocation: location,
                                                    continuation: continuation)
            conversionPrompts[conversionPrompt.id] = conversionPrompt
        }
    }
    
    private var conversionPromptViewAttachments: [UUID: ViewAttachmentEntity] = [:]
    func registerConversionPromptViewAttachment(_ entity: ViewAttachmentEntity, forKey key: UUID) {
        guard conversionPrompts.keys.contains(key) else { return }
        if !conversionPromptViewAttachments.keys.contains(key) {
            conversionPromptViewAttachments[key] = entity
            rootEntity.addChild(entity)
        }
    }
    
    func deregisterConversionPromptViewAttachment(forKey key: UUID) {
        conversionPrompts.removeValue(forKey: key)
        conversionPromptViewAttachments.removeValue(forKey: key)?.removeFromParent()
    }
    
    @MainActor
    private func orientConversionPromptViewAttachmentEntities(_ deviceTransform: simd_float4x4) {
        let devicePosition = deviceTransform.position
        let deviceForward = -deviceTransform.basisZ
        for (key, entity) in conversionPromptViewAttachments {
            let position = -0.15 * deviceForward + (conversionPrompts[key]?.dialogLocation ?? .zero)
            entity.look(at: devicePosition, from: position, relativeTo: nil, forward: .positiveZ)
        }
    }
    
    
    // - MARK: Indicator & Control
    let seedAreaIndicator: SeedAreaIndicator
    let seedAreaControl: SeedAreaControl
    
    var seedAreaIndicatorFlashingDuration: TimeInterval = 1.0
    
    @ObservationIgnored var flashingSeedAreaIndicatorAnimationSubscription: AnyCancellable? = nil
    
    @MainActor
    func flashSeedAreaIndicator(at location: simd_float3, withNormal normal: simd_float3, seedRadius: Float) async {
        
        flashingSeedAreaIndicatorAnimationSubscription?.cancel()
        flashingSeedAreaIndicatorAnimationSubscription = nil
        
        seedAreaIndicator.isEnabled = true
        seedAreaIndicator.position = location
        seedAreaIndicator.normal = normal
        seedAreaIndicator.radius = seedRadius
        
        let flashing = FromToByAnimation<Float>(name: "flashingSeedAreaIndicator",
                                                from: 0.8,
                                                to: 0.0,
                                                duration: seedAreaIndicatorFlashingDuration,
                                                timing: .easeInOut,
                                                bindTarget: .opacity)
        let animation = try! AnimationResource.generate(with: flashing)
        let controller = seedAreaIndicator.playAnimation(animation)
        
        flashingSeedAreaIndicatorAnimationSubscription = seedAreaIndicator.scene?
            .publisher(for: AnimationEvents.PlaybackCompleted.self)
            .filter { $0.playbackController == controller }
            .sink { [weak self] _ in
                self?.seedAreaIndicator.isEnabled = false
                self?.flashingSeedAreaIndicatorAnimationSubscription = nil
            }
    }
    
    private let gesturePointIndicator: ModelEntity
    
    var gesturePointIndicatorFlashingDuration: TimeInterval = 5.0
    
    @ObservationIgnored var flashingGesturePointIndicatorAnimationSubscription: AnyCancellable? = nil
    
    @MainActor
    func flashGesturePointIndicator(at location: simd_float3) async {
        
        flashingGesturePointIndicatorAnimationSubscription?.cancel()
        flashingGesturePointIndicatorAnimationSubscription = nil
        
        gesturePointIndicator.isEnabled = true
        gesturePointIndicator.position = location
        
        let flashing = FromToByAnimation<Float>(name: "flashingGesturePointIndicator",
                                                from: 1.0,
                                                to: 0.0,
                                                duration: gesturePointIndicatorFlashingDuration,
                                                timing: .easeInOut,
                                                bindTarget: .opacity)
        let animation = try! AnimationResource.generate(with: flashing)
        let controller = gesturePointIndicator.playAnimation(animation)
        
        flashingGesturePointIndicatorAnimationSubscription = gesturePointIndicator.scene?
            .publisher(for: AnimationEvents.PlaybackCompleted.self)
            .filter { $0.playbackController == controller }
            .sink { [weak self] _ in
                self?.gesturePointIndicator.isEnabled = false
                self?.flashingGesturePointIndicatorAnimationSubscription = nil
            }
    }
    
    
    // - MARK: status display
    var statusPosition: StatusPosition = .control
    var statusDeviceAnchorOffset: simd_float3 = .zero
    var statusWristAnchorOffset: simd_float3 = .zero
    
    var statusEntity: ViewAttachmentEntity? {
        didSet {
            if let oldValue {
                oldValue.removeFromParent()
            }
            if let statusEntity {
                rootEntity.addChild(statusEntity)
            }
        }
    }
    
    @MainActor
    private func updateStatusLocation(_ deviceTransform: simd_float4x4) {
        
        guard let statusEntity,
              statusPosition == .device else { return }
        
        let devicePosition = deviceTransform.position
        let basisX = deviceTransform.basisX
        let basisY = deviceTransform.basisY
        let basisZ = deviceTransform.basisZ
        
        let offset = statusDeviceAnchorOffset
        
        let position = devicePosition - basisZ + basisX * offset.x + basisY * offset.y + basisZ * offset.z
        
        statusEntity.look(at: devicePosition, from: position, relativeTo: nil, forward: .positiveZ)
    }
    
    @MainActor
    private func updateStatusLocationByWrist() {
        
        guard let statusEntity,
              statusPosition == .wrist,
              let devicePosition = deviceTransform?.position else { return }
              
        guard let wristTransform = leftHand.jointTransform(.forearmWrist) else {
            statusEntity.isEnabled = false
            return
        }
        
        statusEntity.isEnabled = true
        
        let wristPosition = wristTransform.position
        let basisX = -wristTransform.basisZ
        let basisY = -wristTransform.basisY
        let basisZ = -wristTransform.basisX
        
        let offset = statusWristAnchorOffset
        
        let position = wristPosition + basisX * offset.x + basisY * offset.y + basisZ * offset.z
        
        statusEntity.look(at: devicePosition, from: position, relativeTo: nil, forward: .positiveZ)
    }
    
    
    // - MARK: Confirmation Dialog
    var confirmEntity: ViewAttachmentEntity! {
        didSet {
            if let oldValue {
                oldValue.removeFromParent()
            }
            if let confirmEntity {
                rootEntity.addChild(confirmEntity)
            }
        }
    }
    
    var shouldShowConfirmDialog: Bool {
        get {
            access(keyPath: \.shouldShowConfirmDialog)
            return confirmEntity.isEnabled
        }
        set {
            withMutation(keyPath: \.shouldShowConfirmDialog) {
                confirmEntity.isEnabled = newValue
            }
        }
    }
    
    @MainActor
    private func locateConfirmDialog(_ devicePosition: simd_float3,
                                     _ controlPosition: simd_float3) {
            
        let controlNormalDirection = normalize(devicePosition - controlPosition)
        
        let dialogPosition = controlPosition + 0.10 * controlNormalDirection
        
        confirmEntity.look(at: devicePosition,
                           from: dialogPosition,
                           relativeTo: nil,
                           forward: .positiveZ)
    }
    
    
    // - MARK: axis indicator
    private var axisIndicator: AxisIndicator
    var showAxisIndicator: Bool {
        get {
            access(keyPath: \.showAxisIndicator)
            return axisIndicator.isEnabled
        }
        set {
            withMutation(keyPath: \.showAxisIndicator) {
                axisIndicator.isEnabled = newValue
            }
        }
    }
    
    @MainActor
    private func updateAxisIndicator() {
        
        guard axisIndicator.isEnabled,
              let transform = leftHand.jointTransform(.wrist)else { return }
        
        let rotation = simd_float4x4.transform(xAxis: .init(0, 0, -1), yAxis: .init(0, -1, 0), zAxis: .init(1, 0, 0))
        let translation = Transform(translation: .init(0, -0.10, 0)).matrix
        
        axisIndicator.transform = Transform(matrix: transform * translation * rotation)
    }
}

enum OfflinePreviewTarget: Int {
    case disabled = 0
    case whereDeviceLooks
    case whereUserStares
}
