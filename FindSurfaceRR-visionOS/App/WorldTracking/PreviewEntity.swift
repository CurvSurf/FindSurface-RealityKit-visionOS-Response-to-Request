//
//  PreviewEntity.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 8/7/24.
//

import Foundation
import RealityKit

import FindSurface_visionOS

@MainActor
final class PreviewEntity: Entity {
    
    private let plane: PlaneEntity
    private let sphere: SphereEntity
    private let cylinder: CylinderEntity
    private let cone: ConeEntity
    private let torus: TorusEntity
    private let dot: ModelEntity
    
    required init() {
        
        let plane = PlaneEntity(preview: true)
        plane.name = "Preview Plane"
        plane.isEnabled = false
        
        let sphere = SphereEntity(preview: true)
        sphere.name = "Preview Sphere"
        sphere.isEnabled = false
        
        let cylinder = CylinderEntity(preview: true)
        cylinder.name = "Preview Cylinder"
        cylinder.isEnabled = false
        
        let cone = ConeEntity(preview: true)
        cone.name = "Preview Cone"
        cone.isEnabled = false
        
        let torus = TorusEntity(preview: true)
        torus.name = "Preview Torus"
        torus.isEnabled = false
        
        let dot = ModelEntity(mesh: .generateSphere(radius: 0.01), materials: [UnlitMaterial(color: .black)])
        dot.name = "Preview Dot"
        dot.components.set(OpacityComponent(opacity: 0.5))
        dot.isEnabled = true
        
        self.plane = plane
        self.sphere = sphere
        self.cylinder = cylinder
        self.cone = cone
        self.torus = torus
        self.dot = dot
        super.init()
        
        addChild(plane)
        addChild(sphere)
        addChild(cylinder)
        addChild(cone)
        addChild(torus)
        addChild(dot)
    }
    
    private func setPreviewVisibility(plane planeVisible: Bool = false,
                                      sphere sphereVisible: Bool = false,
                                      cylinder cylinderVisible: Bool = false,
                                      cone coneVisible: Bool = false,
                                      torus torusVisible: Bool = false) {
        if plane.isEnabled != planeVisible {
            plane.isEnabled = planeVisible
        }
        if sphere.isEnabled != sphereVisible {
            sphere.isEnabled = sphereVisible
        }
        if cylinder.isEnabled != cylinderVisible {
            cylinder.isEnabled = cylinderVisible
        }
        if cone.isEnabled != coneVisible {
            cone.isEnabled = coneVisible
        }
        if torus.isEnabled != torusVisible {
            torus.isEnabled = torusVisible
        }
    }
    
    func update(_ result: FindSurface.Result, location: simd_float3) async {
        
        dot.position = location
        
        var opacity: Float = 1.0
        switch result {
        case let .foundPlane(object, _, _):
            plane.update { intrinsics in
                intrinsics.width = object.width
                intrinsics.height = object.height
            }
            plane.transform = Transform(matrix: object.extrinsics)
            setPreviewVisibility(plane: true)
            
        case let .foundSphere(object, _, _):
            sphere.update { intrinsics in
                intrinsics.radius = object.radius
            }
            sphere.transform = Transform(matrix: object.extrinsics)
            setPreviewVisibility(sphere: true)
            
        case let .foundCylinder(object, _, _):
            cylinder.update { intrinsics in
                intrinsics.radius = object.radius
                intrinsics.length = object.height
            }
            cylinder.transform = Transform(matrix: object.extrinsics)
            setPreviewVisibility(cylinder: true)
            
        case let .foundCone(object, _, _):
            cone.update { intrinsics in
                intrinsics.topRadius = object.topRadius
                intrinsics.bottomRadius = object.bottomRadius
                intrinsics.length = object.height
            }
            cone.transform = Transform(matrix: object.extrinsics)
            setPreviewVisibility(cone: true)
            
        case let .foundTorus(object, inliers, _):
            torus.update { intrinsics in
                intrinsics.meanRadius = object.meanRadius
                intrinsics.tubeRadius = object.tubeRadius
                let (begin, delta) = object.calcAngleRange(from: inliers)
                intrinsics.tubeBegin = begin
                intrinsics.tubeAngle = delta
            }
            torus.transform = Transform(matrix: object.extrinsics)
            setPreviewVisibility(torus: true)
            
        case .none(_):
            opacity = 0.5
            setPreviewVisibility()
        }
        
        dot.components.set(OpacityComponent(opacity: opacity))
    }
}
