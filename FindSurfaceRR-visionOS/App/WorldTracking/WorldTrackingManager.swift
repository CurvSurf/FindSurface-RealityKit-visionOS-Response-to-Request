//
//  GeometryManager.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 8/6/24.
//

import Foundation
import ARKit
import RealityKit
import _RealityKit_SwiftUI
import Combine
import AVKit

import FindSurface_visionOS

@Observable
final class WorldTrackingManager {
    
    unowned var logger: Logger!
    
    let worldTracking = WorldTrackingProvider()
    
    @MainActor
    func updateAnchors() async {
        for await update in worldTracking.anchorUpdates {
            let anchor = update.anchor
            switch update.event {
            case .added:
                _ = await anchorAdded(anchor)
            case .updated:
                await anchorUpdated(anchor)
            case .removed:
                await anchorRemoved(anchor)
            }
        }
    }
    
    @MainActor
    func updateDeviceTransform(_ update: @escaping (simd_float4x4) async -> Void) async {
//        var count = 0
        await run(withFrequency: 90) { [self] in
            guard worldTracking.state == .running,
                  let anchor = worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()),
                  anchor.isTracked else { return }
            
            var transform = anchor.originFromAnchorTransform
            if useDeviceAnchorBias {
                transform.position += devicePositionBias
                let rotation = simd_quatf(angle: -deviceDirectionVerticalBias, axis: transform.basisX)
                transform.basisY = rotation.act(transform.basisY)
                transform.basisZ = rotation.act(transform.basisZ)
            }
            
            await update(transform)
        }
    }
    
    @MainActor
    static var preview: WorldTrackingManager {
        let instance = WorldTrackingManager()
        instance.geometryKeys = (0..<5).map { _ in UUID() }
        instance.geometryValues = [
            .plane("Plane1", .init(width: 2, height: 3, extrinsics: .extrinsics(position: .init(4, 5, 6))), [], 0.0353),
            .sphere("Sphere2", .init(radius: 2, extrinsics: .extrinsics(position: .init(4, 5, 6))), [], 0.1234),
            .cylinder("Cylinder3", .init(height: 2, radius: 3, extrinsics: .extrinsics(position: .init(4, 5, 6))), [], 0.532),
            .cone("Cone4", .init(height: 8, topRadius: 2, bottomRadius: 3, extrinsics: .extrinsics(position: .init(4, 5, 6))), [], 0.6838),
            .torus("Torus5", .init(meanRadius: 2, tubeRadius: 5, extrinsics: .extrinsics(position: .init(4, 5, 6))), [], 0.5324, 0.0, .pi)
        ]
        return instance
    }
    
    @MainActor
    init() {
        let rootEntity = Entity()
        
        let previewEntity = PreviewEntity()
        rootEntity.addChild(previewEntity)
        
        let geometryEntity = Entity()
        rootEntity.addChild(geometryEntity)
    
        let inlierEntity = Entity()
        rootEntity.addChild(inlierEntity)
        
        let viewAttachmentEntity = Entity()
        rootEntity.addChild(viewAttachmentEntity)
        
        self.rootEntity = rootEntity
        self.previewEntity = previewEntity
        self.geometryEntity = geometryEntity
        self.inlierEntity = inlierEntity
        self.viewAttachmentEntity = viewAttachmentEntity
    }
    
    let rootEntity: Entity
    
    @MainActor
    func reset() {
        Task {
            for key in persistentObjects.keys {
                await removeAnchor(id: key)
            }
            persistentObjects.removeAll()
            
        }
    }
    
    @MainActor
    func removeAnchor(id: UUID) async {
        guard persistentObjects.removeValue(forKey: id) != nil else { return }
        do {
            try await worldTracking.removeAnchor(forID: id)
        } catch {
            print("anchor remove failed: \(error)")
            await anchorRemoved(id)
        }
    }
    
    
    // - MARK: Preview Entities
    private let previewEntity: PreviewEntity
    var previewSamplingFrequency: PreviewSamplingFrequency = .k90Hz
    var previewEnabled: Bool = false
    
    var useDeviceAnchorBias: Bool = true
    var devicePositionBias: simd_float3 = .zero
    var deviceDirectionVerticalBias: Float = 0
    
    var offlinePreviewTarget: OfflinePreviewTarget = .whereDeviceLooks
    var shouldApplyConversionWithoutPrompt: Bool = false
    
    @MainActor
    func updatePreviewEntity(_ result: FindSurface.Result, location: simd_float3) async {
        await previewEntity.update(result, location: location)
    }
    
    // - MARK: World Anchors
    @MainActor
    private func anchorAdded(_ anchor: WorldAnchor) async -> Bool {
        
        var anchorIsOriginatedFromPreviousSession = true
        if pendingObjects.keys.contains(anchor.id) {
            persistentObjects[anchor.id] = pendingObjects.removeValue(forKey: anchor.id)
            anchorIsOriginatedFromPreviousSession = false
        }
        
        guard let object = persistentObjects[anchor.id] else {
            try? await worldTracking.removeAnchor(anchor)
            return false
        }
        
        if anchorIsOriginatedFromPreviousSession {
            let message = object.attr + " has been detected, which is from the previous session.".attr
            logger.add(message)
        } else {
            let message = object.attr + " has been captured by FindSurface.".attr
            logger.add(message)
        }
        
        let geometry = await GeometryEntity.generateGeometryEntity(from: object)
        if !isGeometryOutlineVisible {
            geometry.enableOutline(false)
        }
        geometryEntity.addChild(geometry)
        geometries[anchor.id] = geometry
        geometryKeys.append(anchor.id)
        geometryValues.append(object)
        
        if let inlier = await ModelEntity.generatePointcloudEntity(from: object) {
            inlierEntity.addChild(inlier)
            inliers[anchor.id] = inlier
        }
        
        return true
    }
    
    @MainActor
    private func anchorUpdated(_ anchor: WorldAnchor) async {
        
        let transform = Transform(matrix: anchor.originFromAnchorTransform)
        
        if let geometry = geometries[anchor.id] {
            geometry.transform = transform
            if var object = geometry.components[PersistentComponent.self]?.object {
                object.object.extrinsics = transform.matrix
                geometry.components.set(PersistentComponent(object: object))
                if let index = geometryKeys.firstIndex(of: anchor.id) {
                    geometryValues[index] = object
                }
            }
        }
        
        inliers[anchor.id]?.transform = transform
        viewAttachments[anchor.id]?.transform = transform
    }
    
    @MainActor
    private func anchorRemoved(_ anchor: WorldAnchor) async {
        await anchorRemoved(anchor.id)
    }
    
    @MainActor
    private func anchorRemoved(_ id: UUID) async {
        
        geometries.removeValue(forKey: id)?.removeFromParent()
        inliers.removeValue(forKey: id)?.removeFromParent()
        viewAttachments.removeValue(forKey: id)?.removeFromParent()
        
        if let index = geometryKeys.firstIndex(of: id) {
            geometryKeys.remove(at: index)
            let object = geometryValues.remove(at: index)
            
            let message = object.attr + " has been removed."
            logger.add(message)
        }
    }
    
    
    // - MARK: Geometry entities
    private let geometryEntity: Entity
    private(set) var geometries: [UUID: GeometryEntity] = [:]
    private(set) var geometryKeys: [UUID] = []
    private(set) var geometryValues: [PersistentObject] = []
    
    @MainActor
    var isGeometryOutlineVisible: Bool = true {
        didSet {
            for entity in geometries.values {
                entity.enableOutline(isGeometryOutlineVisible)
            }
        }
    }
    
    // - MARK: Inlier entities
    private let inlierEntity: Entity
    private var inliers: [UUID: ModelEntity] = [:]
    
    var areInlierPointVisible: Bool {
        get {
            access(keyPath: \.areInlierPointVisible)
            return inlierEntity.isEnabled
        }
        set {
            withMutation(keyPath: \.areInlierPointVisible) {
                inlierEntity.isEnabled = newValue
            }
        }
    }
    
    
    // - MARK: Object Info View attachment entities
    private var deviceTransform: simd_float4x4? = nil
    var devicePosition: simd_float3? { deviceTransform?.position }
    var deviceDirection: simd_float3? {
        guard let backward = deviceTransform?.basisZ else { return nil }
        return -backward
    }

    private let viewAttachmentEntity: Entity
    private var viewAttachments: [UUID: ViewAttachmentEntity] = [:]
    
    func addViewAttachmentEntity(_ entity: ViewAttachmentEntity, forKey key: UUID) {
        viewAttachments[key] = entity
    }
    
    @MainActor
    func deviceTransformUpdated(_ transform: simd_float4x4) async {
        deviceTransform = transform
        
        await orientAttachments(to: transform)
    }
    
    @MainActor
    private func orientAttachments(to deviceTransform: simd_float4x4) async {
        
        let devicePosition = deviceTransform.position
        for (key, attachment) in viewAttachments {
            
            guard let geometry = geometries[key],
                  let object = geometry.components[PersistentComponent.self]?.object else { continue }
            
            switch object {
            case .plane(_, let plane, _, _):        await orient(attachment, with: plane, towards: devicePosition)
            case .sphere(_, let sphere, _, _):      await orient(attachment, with: sphere, towards: devicePosition)
            case .cylinder(_, let cylinder, _, _):  await orient(attachment, with: cylinder, towards: devicePosition)
            case .cone(_, let cone, _, _):          await orient(attachment, with: cone, towards: devicePosition)
            case .torus(_, let torus, _, _, _, _):  await orient(attachment, with: torus, towards: devicePosition)
            }
        }
    }
    
    // - MARK: Persistent objects
    private var pendingObjects: [UUID: PersistentObject] = [:]
    private var persistentObjects: [UUID: PersistentObject] = [:]
    
    var enableFullTorusConversion: Bool = true
    var fullTorusAngleThreshold: Float = .pi * 1.5
    var enableFullConeConversion: Bool = true
    var fullConeRadiiRatioThreshold: Float = 0.1
    
    func addPendingObject(_ result: FindSurface.Result) async {
        let count = persistentObjects.count + pendingObjects.count
        
        let object: PersistentObject = switch result {
        case let .foundPlane(plane, inliers, rmsError):
                .plane("Plane\(count)", plane, inliers, rmsError)
        case let .foundSphere(sphere, inliers, rmsError):
                .sphere("Sphere\(count)", sphere, inliers, rmsError)
        case let .foundCylinder(cylinder, inliers, rmsError):
                .cylinder("Cylinder\(count)", cylinder, inliers, rmsError)
        case let .foundCone(cone, inliers, rmsError):
                .cone("Cone\(count)", cone, inliers, rmsError)
        case let .foundTorus(torus, inliers, rmsError): {
            var (beginAngle, deltaAngle) = torus.calcAngleRange(from: inliers)
            if enableFullTorusConversion && deltaAngle > Float(fullTorusAngleThreshold) {
                deltaAngle = .twoPi
            }
            return .torus("Torus\(count)", torus, inliers, rmsError, beginAngle, deltaAngle)
        }()
        default: fatalError("should never reach here (\(result)).")
        }
        
        do {
            let anchor = WorldAnchor(originFromAnchorTransform: object.object.extrinsics)
            pendingObjects[anchor.id] = object
            print("add pending object with key (\(anchor.id.uuidString)).")
            try await worldTracking.addAnchor(anchor)
        } catch {
            print("\(error)")
        }
    }
    
    func updatePersistentObject(_ object: PersistentObject, forKey key: UUID) {
        persistentObjects[key] = object
    }
    
    func removePersistentObject(forKey key: UUID) {
        persistentObjects.removeValue(forKey: key)
    }
    
    func loadPersistentObjects() {
        persistentObjects = (try? .load()) ?? [:]
    }
    
    func savePersistentObjects() {
        try? persistentObjects.save()
    }
    
    
    // - MARK: USDA exports
    func exportAsUSD() async -> String {
        return await export(geometries.values.map { $0 })
    }
}

extension WorldAnchor: Hashable, Equatable {
    
    public static func == (lhs: WorldAnchor, rhs: WorldAnchor) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

fileprivate func orient(_ attachment: ViewAttachmentEntity, with plane: Plane, towards deviceLocation: simd_float3) async {
    let normal = plane.normal
    let center = plane.center
    
    let isHorizontalPlane = abs(normal.y) > cos(.pi / 12)
    if isHorizontalPlane {
        let position = center + 0.20 * normal
        await attachment.look(at: deviceLocation, from: position, relativeTo: nil, forward: .positiveZ)
    } else {
        let at = center + normal
        let position = center + 0.20 * normal
        await attachment.look(at: at, from: position, relativeTo: nil, forward: .positiveZ)
    }
}

fileprivate func orient(_ attachment: ViewAttachmentEntity, with sphere: Sphere, towards deviceLocation: simd_float3) async {
    let radius = sphere.radius
    let center = sphere.center
    
    let position = center + (0.15 + radius) * normalize(deviceLocation - center)
    await attachment.look(at: deviceLocation, from: position, relativeTo: nil, forward: .positiveZ)
}

fileprivate func orient(_ attachment: ViewAttachmentEntity, with cylinder: Cylinder, towards deviceLocation: simd_float3) async {
    let center = cylinder.center
    let axis = cylinder.axis
    let top = cylinder.top
    let radius = cylinder.radius
    
    let isLyingDown = abs(axis.y) * sqrt(2.0) < 1
    let isAboveEyeLevel = top.y > deviceLocation.y + 0.10
    if isLyingDown || isAboveEyeLevel {
        let position = center + (0.15 + radius) * normalize(deviceLocation - center)
        await attachment.look(at: deviceLocation, from: position, relativeTo: nil, forward: .positiveZ)
    } else {
        let position = top + 0.15 * axis
        await attachment.look(at: deviceLocation, from: position, relativeTo: nil, forward: .positiveZ)
    }
}

fileprivate func orient(_ attachment: ViewAttachmentEntity, with cone: Cone, towards deviceLocation: simd_float3) async {
    let axis = cone.axis
    let top = cone.top
    let bottom = cone.bottom
    let center = cone.center
    let bottomRadius = cone.bottomRadius
    
    let isLyingDown = abs(axis.y) * sqrt(2.0) < 1
    let isAboveEyeLevel = top.y > deviceLocation.y + 0.10
    if isLyingDown || isAboveEyeLevel {
        let position = center + (0.15 + bottomRadius) * normalize(deviceLocation - center)
        await attachment.look(at: deviceLocation, from: position, relativeTo: nil, forward: .positiveZ)
    } else {
        let isUpsideDown = axis.y < 0
        let position = isUpsideDown ? bottom - 0.15 * axis : top + 0.15 * axis
        await attachment.look(at: deviceLocation, from: position, relativeTo: nil, forward: .positiveZ)
    }
}

fileprivate func orient(_ attachment: ViewAttachmentEntity, with torus: Torus, towards deviceLocation: simd_float3) async {
    let axis = torus.axis
    let center = torus.center
    let tubeRadius = torus.tubeRadius
    let meanRadius = torus.meanRadius
    
    let isLyingDown = abs(axis.y) * sqrt(2.0) < 1
    let isAboveEyeLevel = center.y + tubeRadius > deviceLocation.y + 0.10
    if isLyingDown || isAboveEyeLevel {
        let position = center + (0.15 + meanRadius + tubeRadius) * normalize(deviceLocation - center)
        await attachment.look(at: deviceLocation, from: position, relativeTo: nil, forward: .positiveZ)
    } else {
        let position = center + (0.15 + tubeRadius) * axis
        await attachment.look(at: deviceLocation, from: position, relativeTo: nil, forward: .positiveZ)
    }
}


fileprivate func angle(_ a: simd_float3, _ b: simd_float3, _ c: simd_float3 = .init(0, -1, 0)) -> Float {
    let angle = acos(dot(a, b))
    if dot(c, cross(a, b)) < 0 {
        return -angle
    } else {
        return angle
    }
}

extension Torus {
    func calcAngleRange(from inliers: [simd_float3]) -> (begin: Float, delta: Float) {
        
        let projected = inliers.map { point in
            normalize(simd_float3(point.x, 0, point.z))
        }
        var projectedCenter = projected.reduce(.zero, +) / Float(projected.count)
        
        if length(projectedCenter) < 0.1 {
            return (begin: .zero, delta: .twoPi)
        }
        projectedCenter = normalize(projectedCenter)
        
        let baseAngle = angle(.init(1, 0, 0), projectedCenter)
        
        let angles = projected.map {
            return angle(projectedCenter, $0)
        }
        
        guard let (beginAngle, endAngle) = angles.minAndMax() else {
            return (begin: .zero, delta: .twoPi)
        }
        
        let begin = beginAngle + baseAngle
        let end = endAngle + baseAngle
        let delta = end - begin
        
        return (begin: begin, delta: delta)
    }
}
