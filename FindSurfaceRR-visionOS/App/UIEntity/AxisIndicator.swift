//
//  AxisIndicator.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 9/5/24.
//

import Foundation
import RealityKit

@MainActor
final class AxisIndicator: Entity {
    
    required init() {
        
        let (origin, xAxis, yAxis, zAxis) = {
            let origin = Submesh.generateSphere(radius: 0.005)
            let arrowbody = Submesh.generateCylinder(radius: 0.003, length: 0.041)
            let arrowhead = Submesh.generateCone(topRadius: 0, bottomRadius: 0.005, length: 0.025)
            
            let arrowheadY = arrowhead.translated(y: 0.0575)
            let arrowbodyY = arrowbody.translated(y: 0.0245)
            
            let yAxis = arrowheadY + arrowbodyY
            let xAxis = yAxis.rotated(angle: .pi * 0.5, axis: .init(0, 0, 1))
            let zAxis = yAxis.rotated(angle: .pi * 0.5, axis: .init(1, 0, 0))
            
            let originMesh = try! MeshResource.generate(name: "Origin", from: origin)
            let xAxisMesh = try! MeshResource.generate(name: "X-Axis", from: xAxis)
            let yAxisMesh = try! MeshResource.generate(name: "Y-Axis", from: yAxis)
            let zAxisMesh = try! MeshResource.generate(name: "Z-Axis", from: zAxis)
            
            let originMat = [SimpleMaterial(color: .white, roughness: 0.75, isMetallic: true)]
            let xAxisMat = [SimpleMaterial(color: .red, roughness: 0.75, isMetallic: true)]
            let yAxisMat = [SimpleMaterial(color: .green, roughness: 0.75, isMetallic: true)]
            let zAxisMat = [SimpleMaterial(color: .blue, roughness: 0.75, isMetallic: true)]
            
            let originModel = ModelEntity(mesh: originMesh, materials: originMat)
            let xAxisModel = ModelEntity(mesh: xAxisMesh, materials: xAxisMat)
            let yAxisModel = ModelEntity(mesh: yAxisMesh, materials: yAxisMat)
            let zAxisModel = ModelEntity(mesh: zAxisMesh, materials: zAxisMat)
            
            return (originModel, xAxisModel, yAxisModel, zAxisModel)
        }()
        
        super.init()
        addChild(origin)
        addChild(xAxis)
        addChild(yAxis)
        addChild(zAxis)
    }
}
