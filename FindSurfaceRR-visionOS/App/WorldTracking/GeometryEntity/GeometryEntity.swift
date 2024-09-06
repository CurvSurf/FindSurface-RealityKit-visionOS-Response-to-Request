//
//  Entity.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/25/24.
//

import Foundation
import RealityKit

@MainActor
class GeometryEntity: Entity {
    
    required init() {
        super.init()
    }
    
    func enableOutline(_ visible: Bool) {
        fatalError()
    }
}

extension GeometryEntity {
    
    class func generateGeometryEntity(from object: PersistentObject) async -> GeometryEntity {
        
        let entity: GeometryEntity = switch object {
            
        case let .plane(_, plane, _, _): {
            return PlaneEntity(width: plane.width, height: plane.height) as GeometryEntity
        }()
        case let .sphere(_, sphere, _, _): {
            return SphereEntity(radius: sphere.radius) as GeometryEntity
        }()
        case let .cylinder(_, cylinder, _, _): {
            return CylinderEntity(radius: cylinder.radius, length: cylinder.height, shape: .surface) as GeometryEntity
        }()
        case let .cone(_, cone, _, _): {
            return ConeEntity(topRadius: cone.topRadius, bottomRadius: cone.bottomRadius, length: cone.height, shape: .surface) as GeometryEntity
        }()
        case let .torus(_, torus, _, _, begin, delta): {
            if delta >= .radians(fromDegrees: 270) {
                return TorusEntity(meanRadius: torus.meanRadius, tubeRadius: torus.tubeRadius) as GeometryEntity
            }
            return TorusEntity(meanRadius: torus.meanRadius, tubeRadius: torus.tubeRadius, tubeBegin: begin, tubeAngle: delta, shape: .surface)
        }()
        }
            
        entity.name = object.name
        entity.transform = Transform(matrix: object.object.extrinsics)
        entity.components.set(PersistentComponent(object: object))
        return entity
    }
}

extension Array where Element == (any Material) {
    
    static var mesh: [any Material] {
        return [UnlitMaterial(color: .blue).wireframe]
    }
    
    static var plane: [any Material] {
        return [UnlitMaterial(color: .red)]
    }
    
    static var sphere: [any Material] {
        return [UnlitMaterial(color: .green)]
    }
    
    static var cylinder: [any Material] {
        return [UnlitMaterial(color: .purple)]
    }
    
    static var cone: [any Material] {
        return [UnlitMaterial(color: .cyan)]
    }
    
    static var torus: [any Material] {
        return [UnlitMaterial(color: .yellow)]
    }
}

extension ModelEntity {
    
    class func generatePointcloudEntity(name: String, 
                                        points: [simd_float3],
                                        size: Float = 0.01,
                                        materials: [any Material],
                                        opacity: Float = 1.0,
                                        transform: Transform = .identity
    ) async -> ModelEntity? {
        
        guard let mesh = try? await MeshResource.generatePointcloud(name: name, points: points, size: size) else {
            return nil
        }
        
        let entity = ModelEntity(mesh: mesh, materials: materials)
        entity.name = name
        entity.components.set(OpacityComponent(opacity: opacity))
        entity.transform = transform
        return entity
    }
    
    class func generatePointcloudEntity(from object: PersistentObject) async -> ModelEntity? {
        
        let name = "\(object.name) (inliers)"
        let materials: [any Material] = switch object {
        case .plane:    .plane
        case .sphere:   .sphere
        case .cylinder: .cylinder
        case .cone:     .cone
        case .torus:    .torus
        }
        return await generatePointcloudEntity(name: name,
                                              points: object.inliers,
                                              materials: materials,
                                              opacity: 0.5,
                                              transform: Transform(matrix: object.object.extrinsics))
    }
}
