//
//  AppStorage.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 7/17/24.
//

import Foundation
import SwiftUI

import FindSurface_visionOS

extension SceneReconstructionManager {
    
    enum DefaultKey: String, UserDefaults.Key {
        case shouldShowSceneReconstructionUpdateEffect = "should-show-scene-reconstruction-update-effect"
    }

    func loadFromUserDefaults() {
        let storage = UserDefaults.Adapter<DefaultKey>()
        shouldShowUpdateAnimation = storage.bool(forKey: .shouldShowSceneReconstructionUpdateEffect) ?? false
    }
    
    func saveToUserDefaults() {
        let storage = UserDefaults.Adapter<DefaultKey>()
        storage.set(shouldShowUpdateAnimation, forKey: .shouldShowSceneReconstructionUpdateEffect)
    }
}

extension WorldTrackingManager {
    
    enum DefaultKey: String, UserDefaults.Key {
        case shouldShowGeometryOutline = "should-show-geometry-outline"
        case shouldShowInlierPoints = "should-show-inlier-points"
        case useDeviceAnchorBias = "use-device-anchor-bias"
        case devicePositionBias = "device-position-bias"
        case deviceDirectionVerticalBias = "device-direction-vertical-bias"
        case enableFullTorusConversion = "enable-full-torus-conversion"
        case fullTorusAngleThreshold = "full-torus-angle-threshold"
        case enableFullConeConversion = "enable-full-cone-conversion"
        case fullConeRadiiRatioThreshold = "full-cone-radii-ratio-threshold"
        case previewSamplingFrequency = "preview-sampling-frequency"
        case offlinePreviewTarget = "offline-preview-target"
        case shouldApplyConversionWithoutPrompt = "should-apply-conversion-without-prompt"
    }
    
    @MainActor
    func loadFromUserDefaults() {
        let storage = UserDefaults.Adapter<DefaultKey>()
        isGeometryOutlineVisible = storage.bool(forKey: .shouldShowGeometryOutline) ?? true
        areInlierPointVisible = storage.bool(forKey: .shouldShowInlierPoints) ?? false
        useDeviceAnchorBias = storage.bool(forKey: .useDeviceAnchorBias) ?? true
        devicePositionBias = storage.simd(forKey: .devicePositionBias) ?? .zero
        deviceDirectionVerticalBias = storage.float(forKey: .deviceDirectionVerticalBias) ?? 10
        enableFullTorusConversion = storage.bool(forKey: .enableFullTorusConversion) ?? true
        fullTorusAngleThreshold = storage.float(forKey: .fullTorusAngleThreshold) ?? .pi * 1.5
        enableFullConeConversion = storage.bool(forKey: .enableFullConeConversion) ?? true
        fullConeRadiiRatioThreshold = storage.float(forKey: .fullConeRadiiRatioThreshold) ?? 0.1
        previewSamplingFrequency = storage.enum(forKey: .previewSamplingFrequency) ?? .k90Hz
        offlinePreviewTarget = storage.enum(forKey: .offlinePreviewTarget) ?? .whereDeviceLooks
        shouldApplyConversionWithoutPrompt = storage.bool(forKey: .shouldApplyConversionWithoutPrompt) ?? false
    }
    
    @MainActor
    func saveToUserDefaults() {
        let storage = UserDefaults.Adapter<DefaultKey>()
        storage.set(isGeometryOutlineVisible, forKey: .shouldShowGeometryOutline)
        storage.set(areInlierPointVisible, forKey: .shouldShowInlierPoints)
        storage.set(useDeviceAnchorBias, forKey: .useDeviceAnchorBias)
        storage.set(devicePositionBias, forKey: .devicePositionBias)
        storage.set(deviceDirectionVerticalBias, forKey: .deviceDirectionVerticalBias)
        storage.set(enableFullTorusConversion, forKey: .enableFullTorusConversion)
        storage.set(fullTorusAngleThreshold, forKey: .fullTorusAngleThreshold)
        storage.set(enableFullConeConversion, forKey: .enableFullConeConversion)
        storage.set(fullConeRadiiRatioThreshold, forKey: .fullConeRadiiRatioThreshold)
        storage.set(previewSamplingFrequency, forKey: .previewSamplingFrequency)
        storage.set(offlinePreviewTarget, forKey: .offlinePreviewTarget)
        storage.set(shouldApplyConversionWithoutPrompt, forKey: .shouldApplyConversionWithoutPrompt)
    }
}

extension UIEntityManager {
    
    enum DefaultKey: String, UserDefaults.Key {
        case showHands = "show-hands"
        case handsVisibility = "hands-visibility"
        case statusPosition = "status-position"
        case statusDeviceAnchorOffset = "status-device-anchor-offset"
        case statusWristAnchorOffset = "status-wrist-anchor-offset"
    }
    
    @MainActor
    func loadFromUserDefaults() {
        let storage = UserDefaults.Adapter<DefaultKey>()
        showHands = storage.bool(forKey: .showHands) ?? false
        handsVisibility = storage.enum(forKey: .handsVisibility) ?? .right
        statusPosition = storage.enum(forKey: .statusPosition) ?? .control
        statusDeviceAnchorOffset = storage.simd(forKey: .statusDeviceAnchorOffset) ?? .init(0.15, -0.04, 0.03)
        statusWristAnchorOffset = storage.simd(forKey: .statusWristAnchorOffset) ?? .init(0.00, 0.10, 0)
    }
    
    @MainActor
    func saveToUserDefaults() {
        let storage = UserDefaults.Adapter<DefaultKey>()
        storage.set(showHands, forKey: .showHands)
        storage.set(handsVisibility, forKey: .handsVisibility)
        storage.set(statusPosition, forKey: .statusPosition)
        storage.set(statusDeviceAnchorOffset, forKey: .statusDeviceAnchorOffset)
        storage.set(statusWristAnchorOffset, forKey: .statusWristAnchorOffset)
    }
}

extension FindSurface {
    
    enum DefaultKey: String, UserDefaults.Key {
        case measurementAccuracy = "measurement-accuracy"
        case meanDistance = "mean-distance"
        case seedRadius = "seed-radius"
        case lateralExtension = "lateral-extension"
        case radialExpansion = "radial-expansion"
        case allowsConeToCylinderConversion = "allows-cone-to-cylinder-conversion"
        case allowsTorusToSphereConversion = "allows-torus-to-sphere-conversion"
        case allowsTorusToCylinderConversion = "allows-torus-to-cylinder-conversion"
    }
    
    var defaultLoaded: Self {
        loadFromUserDefaults()
        return self
    }
    
    func loadFromUserDefaults() {
        let storage = UserDefaults.Adapter<DefaultKey>()
        measurementAccuracy = storage.float(forKey: .measurementAccuracy) ?? 0.025
        meanDistance = storage.float(forKey: .meanDistance) ?? 0.05
        seedRadius = storage.float(forKey: .seedRadius) ?? 0.10
        lateralExtension = storage.enum(forKey: .lateralExtension) ?? .off
        radialExpansion = storage.enum(forKey: .radialExpansion) ?? .lv5
        allowsCylinderInsteadOfCone = storage.bool(forKey: .allowsConeToCylinderConversion) ?? true
        allowsCylinderInsteadOfTorus = storage.bool(forKey: .allowsTorusToSphereConversion) ?? true
        allowsSphereInsteadOfTorus = storage.bool(forKey: .allowsTorusToCylinderConversion) ?? true
    }
    
    func saveToUserDefaults() {
        let storage = UserDefaults.Adapter<DefaultKey>()
        storage.set(measurementAccuracy, forKey: .measurementAccuracy)
        storage.set(meanDistance, forKey: .meanDistance)
        storage.set(seedRadius, forKey: .seedRadius)
        storage.set(lateralExtension, forKey: .lateralExtension)
        storage.set(radialExpansion, forKey: .radialExpansion)
        storage.set(allowsCylinderInsteadOfCone, forKey: .allowsConeToCylinderConversion)
        storage.set(allowsCylinderInsteadOfTorus, forKey: .allowsTorusToCylinderConversion)
        storage.set(allowsSphereInsteadOfTorus, forKey: .allowsTorusToSphereConversion)
    }
}
