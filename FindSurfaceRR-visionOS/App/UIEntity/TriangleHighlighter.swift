//
//  TriangleHighlighter.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 9/27/24.
//

import RealityKit

@MainActor
final class TriangleHighlighter: Entity {
    
    private let model: ModelEntity
    
    required init() {
        let submesh = Submesh(positions: [.zero, .zero, .zero], triangleIndices: [0, 1, 2])
        let mesh = try! MeshResource.generate(name: "triangleMesh", from: submesh)
        let material = SimpleMaterial(color: .green.withAlphaComponent(0.3), roughness: 0.75, isMetallic: false)
        let model = ModelEntity(mesh: mesh, materials: [material])
        
        self.model = model
        super.init()
        addChild(model)
    }
    
    func updateTriangle(_ point0: simd_float3,
                        _ point1: simd_float3,
                        _ point2: simd_float3) {
        let submesh = Submesh(positions: [point0, point1, point2, point0, point2, point1], triangleIndices: [0, 1, 2, 3, 4, 5])
        model.model?.mesh = try! .generate(name: "triangleMesh", from: submesh)
    }
}
