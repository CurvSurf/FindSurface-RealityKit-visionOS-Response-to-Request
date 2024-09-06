//
//  MeshManager.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 8/5/24.
//

import Foundation
import ARKit
import RealityKit
import _RealityKit_SwiftUI
import Combine

import Algorithms

@Observable
final class SceneReconstructionManager {
    
    let sceneReconstruction = SceneReconstructionProvider()
    
    @MainActor
    func updateAnchors() async {
        for await update in sceneReconstruction.anchorUpdates {
            switch update.event {
            case .added:
                await anchorAdded(update.anchor)
            case .updated:
                await anchorUpdated(update.anchor)
            case .removed:
                await anchorRemoved(update.anchor)
            }
        }
    }
    
    init() {
        let rootEntity = Entity()
        
        self.rootEntity = rootEntity
    }
    
    let rootEntity: Entity
    
    var shouldShowMesh: Bool {
        get {
            access(keyPath: \.shouldShowMesh)
            return rootEntity.isEnabled
        }
        set {
            withMutation(keyPath: \.shouldShowMesh) {
                rootEntity.isEnabled = newValue
            }
        }
    }
    
    private var anchors: Set<MeshAnchor> = []
    private var entities: [UUID: ModelEntity] = [:]
    
    @MainActor
    private func anchorAdded(_ anchor: MeshAnchor) async {
        
        let entity = if let sceneBoundary {
            await ModelEntity.generateWireframe(from: anchor, sceneBoundary: sceneBoundary)
        } else {
            await ModelEntity.generateWireframe(from: anchor)
        }
        guard let entity else { return }
        
        entity.transform = Transform(matrix: anchor.originFromAnchorTransform)
        
        rootEntity.addChild(entity)
        anchors.insert(anchor)
        entities[anchor.id] = entity
        
        updatePoints(anchor.worldPositions, forKey: anchor.id)
        
        playUpdateAnimation(entity, forKey: anchor.id)
    }
    
    @MainActor
    private func anchorUpdated(_ anchor: MeshAnchor) async {
        
        guard let entity = entities[anchor.id],
              let materials = entity.model?.materials,
              let (mesh, shape) = try? await generateMeshAndShapeResources(from: anchor,
                                                                           sceneBoundary: sceneBoundary)
        else { return }
        
        anchors.update(with: anchor)
        entity.model = ModelComponent(mesh: mesh, materials: materials)
        entity.transform = Transform(matrix: anchor.originFromAnchorTransform)
        entity.collision?.shapes = [shape]
        updatePoints(anchor.worldPositions, forKey: anchor.id)
        
        stopUpdateAnimation(entity, forKey: anchor.id)
        playUpdateAnimation(entity, forKey: anchor.id)
    }
    
    @MainActor
    private func anchorRemoved(_ anchor: MeshAnchor) async {
        
        guard let entity = entities.removeValue(forKey: anchor.id) else { return }
        
        anchors.remove(anchor)
        entity.removeFromParent()
        updatePoints(nil, forKey: anchor.id)
        
        stopUpdateAnimation(entity, forKey: anchor.id)
    }
    
    
    // - MARK: Scene Boundary
    var sceneBoundary: SceneBoundary? = nil
    
    func updateSceneBoundary() async {
        for anchor in anchors {
            await anchorUpdated(anchor)
        }
    }
    
    func updateSceneBoundaryEntity() {
        
        rootEntity.findEntity(named: "Scene Boundary")?.removeFromParent()
        switch sceneBoundary {
        case let .cylinder(cylinder):
            let mesh = MeshResource.generateCylindricalSurface(radius: cylinder.radius, length: cylinder.height, insideOut: true)
            let entity = ModelEntity(mesh: mesh, materials: [UnlitMaterial(color: .blue.withAlphaComponent(0.3))])
            entity.name = "Scene Boundary"
            entity.position = .init(cylinder.position.x, cylinder.height * 0.5, cylinder.position.z)
            rootEntity.addChild(entity)
        default: break
        }
    }
    
    
    // - MARK: Pointcloud
    private var pointMap: [UUID: [simd_float3]] = [:]
    var meshPoints: [simd_float3] {
        pointMap.values.flatMap { $0 }
    }
    private(set) var pointCount: Int = 0
    
    private func updatePoints(_ points: [simd_float3]?, forKey key: UUID) {
        
        guard let points else {
            if let removed = pointMap.removeValue(forKey: key) {
                pointCount -= removed.count
            }
            return
        }
        
        if let removed = pointMap.updateValue(points, forKey: key) {
            pointCount -= removed.count
        }
        pointCount += points.count
    }
    
    
    // - MARK: Mesh update animation
    var shouldShowUpdateAnimation: Bool = false
    
    private var subscriptions: [UUID: AnyCancellable] = [:]
    
    private func playUpdateAnimation(_ entity: ModelEntity, forKey key: UUID) {
        guard shouldShowUpdateAnimation else { return }
        subscriptions[key] = entity.playUpdateAnimation { [weak self] in
            self?.subscriptions.removeValue(forKey: key)
        }
    }
    
    private func stopUpdateAnimation(_ entity: ModelEntity, forKey key: UUID) {
        guard shouldShowUpdateAnimation else { return }
        subscriptions.removeValue(forKey: key)?.cancel()
    }
    
    
    // - MARK: Ray casting
    func raycast(origin: simd_float3, direction: simd_float3) async -> CollisionCastHit? {
        return await rootEntity.scene?.raycast(origin: origin, direction: direction, query: .nearest).first
    }
}

//@Observable
//final class MeshManager {
//    
//    init() {
//        let rootEntity = Entity()
//        
//        self.rootEntity = rootEntity
//    }
//    
//    let rootEntity: Entity
//    
//    var anchors: Set<MeshAnchor> = []
//    var entities: [UUID: ModelEntity] = [:]
//    
//    @MainActor
//    func anchorAdded(_ anchor: MeshAnchor) async {
//        
//        let entity = if let sceneBoundary {
//            await ModelEntity.generateWireframe(from: anchor, sceneBoundary: sceneBoundary)
//        } else {
//            await ModelEntity.generateWireframe(from: anchor)
//        }
//        guard let entity else { return }
//        
//        entity.transform = Transform(matrix: anchor.originFromAnchorTransform)
//        
//        rootEntity.addChild(entity)
//        anchors.insert(anchor)
//        entities[anchor.id] = entity
//        
//        updatePoints(anchor.worldPositions, forKey: anchor.id)
//        
//        playUpdateAnimation(entity, forKey: anchor.id)
//    }
//    
//    @MainActor
//    func anchorUpdated(_ anchor: MeshAnchor) async {
//        
//        guard let entity = entities[anchor.id],
//              let materials = entity.model?.materials,
//              let (mesh, shape) = try? await generateMeshAndShapeResources(from: anchor,
//                                                                           sceneBoundary: sceneBoundary)
//        else { return }
//        
//        anchors.update(with: anchor)
//        entity.model = ModelComponent(mesh: mesh, materials: materials)
//        entity.transform = Transform(matrix: anchor.originFromAnchorTransform)
//        entity.collision?.shapes = [shape]
//        updatePoints(anchor.worldPositions, forKey: anchor.id)
//        
//        stopUpdateAnimation(entity, forKey: anchor.id)
//        playUpdateAnimation(entity, forKey: anchor.id)
//    }
//    
//    @MainActor
//    func anchorRemoved(_ anchor: MeshAnchor) async {
//        
//        guard let entity = entities.removeValue(forKey: anchor.id) else { return }
//        
//        anchors.remove(anchor)
//        entity.removeFromParent()
//        updatePoints(nil, forKey: anchor.id)
//        
//        stopUpdateAnimation(entity, forKey: anchor.id)
//    }
//    
//    // - MARK: Scene Boundary
//    var sceneBoundary: SceneBoundary? = nil
//    
//    func updateSceneBoundary() async {
//        for anchor in anchors {
//            await anchorUpdated(anchor)
//        }
//    }
//    
//    func updateSceneBoundaryEntity() {
//        
//        rootEntity.findEntity(named: "Scene Boundary")?.removeFromParent()
//        switch sceneBoundary {
//        case let .cylinder(cylinder):
//            let mesh = MeshResource.generateCylindricalSurface(radius: cylinder.radius, length: cylinder.height, insideOut: true)
//            let entity = ModelEntity(mesh: mesh, materials: [UnlitMaterial(color: .blue.withAlphaComponent(0.3))])
//            entity.name = "Scene Boundary"
//            entity.position = .init(cylinder.position.x, cylinder.height * 0.5, cylinder.position.z)
//            rootEntity.addChild(entity)
//        default: break
//        }
//    }
//    
//    // - MARK: Pointcloud
//    private var pointMap: [UUID: [simd_float3]] = [:]
//    var meshPoints: [simd_float3] {
//        pointMap.values.flatMap { $0 }
//    }
//    private(set) var pointCount: Int = 0
//    
//    private func updatePoints(_ points: [simd_float3]?, forKey key: UUID) {
//        
//        guard let points else {
//            if let removed = pointMap.removeValue(forKey: key) {
//                pointCount -= removed.count
//            }
//            return
//        }
//        
//        if let removed = pointMap.updateValue(points, forKey: key) {
//            pointCount -= removed.count
//        }
//        pointCount += points.count
//    }
//    
//    
//    // - MARK: Mesh update animation
//    var shouldShowUpdateAnimation: Bool = true
//    private var subscriptions: [UUID: AnyCancellable] = [:]
//    
//    private func playUpdateAnimation(_ entity: ModelEntity, forKey key: UUID) {
//        guard shouldShowUpdateAnimation else { return }
//        subscriptions[key] = entity.playUpdateAnimation { [weak self] in
//            self?.subscriptions.removeValue(forKey: key)
//        }
//    }
//    
//    private func stopUpdateAnimation(_ entity: ModelEntity, forKey key: UUID) {
//        guard shouldShowUpdateAnimation else { return }
//        subscriptions.removeValue(forKey: key)?.cancel()
//    }
//}

extension MeshAnchor: Hashable, Equatable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: MeshAnchor, rhs: MeshAnchor) -> Bool {
        return lhs.id == rhs.id
    }
}

fileprivate func generateMeshAndShapeResources(from anchor: MeshAnchor, sceneBoundary: SceneBoundary?) async throws -> (MeshResource, ShapeResource) {
    
    guard let sceneBoundary else {
        let mesh = try await MeshResource.generate(from: anchor)
        let shape = try await ShapeResource.generateStaticMesh(from: anchor)
        return (mesh, shape)
    }
    
    let positionIndicesInBoundary = sceneBoundary.contains(anchor.worldPositions)
    
    var indexMap = [Int: Int]()
    let _positionsInBoundary = anchor.positions.enumerated().filter { positionIndicesInBoundary.contains($0.offset) }
    indexMap.reserveCapacity(_positionsInBoundary.count)
    let positionsInBoundary = _positionsInBoundary.enumerated().map {
        let newIndex = $0.offset
        let oldIndex = $0.element.offset
        let position = $0.element.element
        indexMap[oldIndex] = newIndex
        return position
    }
    let normalsInBoundary = anchor.normals.enumerated().filter { positionIndicesInBoundary.contains($0.offset) }.map { $0.element }
    let faceIndicesInBoundary: [UInt32] = anchor.faces.chunks(ofCount: 3).filter { face in
        face.allSatisfy { positionIndicesInBoundary.contains(Int($0)) }
    }.map {
        $0.map { UInt32(indexMap[Int($0)]!) }
    }.flatMap { $0 }
    
    var descriptor = MeshDescriptor(name: anchor.id.uuidString)
    descriptor.positions = .init(positionsInBoundary)
    descriptor.normals = .init(normalsInBoundary)
    descriptor.primitives = .triangles(faceIndicesInBoundary)
    
    let mesh = try await MeshResource.generate(from: [descriptor])
    let shape = try await ShapeResource.generateStaticMesh(positions: positionsInBoundary, faceIndices: faceIndicesInBoundary.map { UInt16($0) })
    
    return (mesh, shape)
}

extension ModelEntity {
    
    class func generateWireframe(from anchor: MeshAnchor,
                                 sceneBoundary: SceneBoundary) async -> ModelEntity? {
                
        guard let (mesh, shape) = try? await generateMeshAndShapeResources(from: anchor,
                                                                           sceneBoundary: sceneBoundary) else {
            return nil
        }
        
        let entity = ModelEntity(mesh: mesh, materials: .mesh)
        entity.name = anchor.id.uuidString
        entity.transform = Transform(matrix: anchor.originFromAnchorTransform)
        entity.collision = CollisionComponent(shapes: [shape], isStatic: true)
        entity.components.set(InputTargetComponent())
        entity.physicsBody = PhysicsBodyComponent(mode: .static)
        return entity
    }
    
    fileprivate func playUpdateAnimation(onCompletion completionHandler: @escaping () -> Void) -> AnyCancellable? {
        return playAnimation(name: "color",
                             from: simd_float3.one,
                             to: simd_float3(0, 0, 1),
                             duration: 1.0,
                             timing: .easeOut) { entity, color in
            guard var material = entity.model?.materials.first as? UnlitMaterial else { return }
            let red = CGFloat(color.x)
            let green = CGFloat(color.y)
            let blue = CGFloat(color.z)
            var alpha = CGFloat(1)
            material.color.tint.getRed(nil, green: nil, blue: nil, alpha: &alpha)
            material.color.tint = .init(red: red, green: green, blue: blue, alpha: alpha)
            self.model?.materials = [material]
        } onCompletion: {
            completionHandler()
        }
    }
}
