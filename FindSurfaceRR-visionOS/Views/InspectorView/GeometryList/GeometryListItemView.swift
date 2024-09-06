//
//  GeometryListItemView.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 9/3/24.
//

import Foundation
import SwiftUI

struct GeometryListItemView: View {
    
    @Environment(WorldTrackingManager.self) private var worldManager
    
    @Binding var isSelected: Bool
    let key: UUID
    let object: PersistentObject
    
    @State private var isExpanded = false
    
    var body: some View {
        
        #if targetEnvironment(simulator)
        @Binding(get: { object.name.starts(with: "Sphere") || object.name.starts(with: "Cylinder") }, set: { _ in }) var isExpanded: Bool
        #endif
        VStack {
            Section(isExpanded: $isExpanded) {
                
                GeometryInfoTable(object: object)
                    .padding(.leading, 16)
                    .makeWidthMinMaxGroup(name: object.name)
                    .environment(\.widthMinMaxGroupName, object.name)
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            Task { await worldManager.removeAnchor(id: key) }
                        }
                    }
                
            } header: {
                Button {
                    withAnimation { isExpanded.toggle() }
                } label: {
                    HStack {
                        NamePlate(object: object)
                        
                        Summary(object: object)
                            .opacity(!isExpanded ? 1 : 0)
                        
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

fileprivate struct NamePlate: View {
    
    let object: PersistentObject
    
    var body: some View {
        HStack {
            Image(systemName: object.systemImage)
            Text(object.name)
                .font(.body.bold())
        }
        .foregroundStyle(object.color)
    }
}

fileprivate struct Summary: View {
    
    let object: PersistentObject
    
    var body: some View {
        Text(object.summary)
            .lineLimit(1)
            .truncationMode(.tail)
    }
}

fileprivate struct GeometryInfoTableRow: View {
    
    @Environment(\.widthMinMaxGroupName) private var groupName
    @Environment(\.widthMinMax) private var widthMinMax
    
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body.bold())
                .lineLimit(1)
                .fixedSize()
                .joinWidthMinMaxGroup(name: groupName)
                .frame(width: widthMinMax.maxValue > 0 ? widthMinMax.maxValue : nil,
                       alignment: .leading)
                .padding(.vertical, 4)
            
            Text(value)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

import FindSurface_visionOS

fileprivate struct PlaneInfoTable: View {
    
    let plane: Plane
    let rmsError: Float
    
    var body: some View {
        VStack(alignment: .leading) {
            GeometryInfoTableRow(label: "Width [cm]: ", value: "\(length: plane.width)")
            GeometryInfoTableRow(label: "Height [cm]: ", value: "\(length: plane.height)")
            GeometryInfoTableRow(label: "Position [cm]: ", value: "\(position: plane.center)")
            GeometryInfoTableRow(label: "Normal: ", value: "\(direction: plane.normal)")
            GeometryInfoTableRow(label: "RMS error [cm]: ", value: "\(length: rmsError)")
        }
    }
}

fileprivate struct SphereInfoTable: View {
    
    let sphere: Sphere
    let rmsError: Float
    
    var body: some View {
        VStack(alignment: .leading) {
            GeometryInfoTableRow(label: "Radius [cm]: ", value: "\(length: sphere.radius)")
            GeometryInfoTableRow(label: "Position [cm]: ", value: "\(position: sphere.center)")
            GeometryInfoTableRow(label: "RMS error [cm]: ", value: "\(length: rmsError)")
        }
    }
}

fileprivate struct CylinderInfoTable: View {
    
    let cylinder: Cylinder
    let rmsError: Float
    
    var body: some View {
        VStack(alignment: .leading) {
            GeometryInfoTableRow(label: "Radius [cm]: ", value: "\(length: cylinder.radius)")
            GeometryInfoTableRow(label: "Height [cm]: ", value: "\(length: cylinder.height)")
            GeometryInfoTableRow(label: "Position [cm]: ", value: "\(position: cylinder.center)")
            GeometryInfoTableRow(label: "Axis: ", value: "\(direction: cylinder.axis)")
            GeometryInfoTableRow(label: "RMS error [cm]: ", value: "\(length: rmsError)")
        }
    }
}

fileprivate struct ConeInfoTable: View {
    
    let cone: Cone
    let rmsError: Float
    
    var body: some View {
        VStack(alignment: .leading) {
            GeometryInfoTableRow(label: "Top radius [cm]: ", value: "\(length: cone.topRadius)")
            GeometryInfoTableRow(label: "Bottom radius [cm]: ", value: "\(length: cone.bottomRadius)")
            GeometryInfoTableRow(label: "Height [cm]: ", value: "\(length: cone.height)")
            GeometryInfoTableRow(label: "Position [cm]: ", value: "\(position: cone.center)")
            GeometryInfoTableRow(label: "Axis: ", value: "\(direction: cone.axis)")
            GeometryInfoTableRow(label: "RMS error [cm]: ", value: "\(length: rmsError)")
        }
    }
}

fileprivate struct TorusInfoTable: View {
    
    let torus: Torus
    let angle: Float
    let rmsError: Float
    
    var body: some View {
        VStack(alignment: .leading) {
            GeometryInfoTableRow(label: "Mean radius [cm]: ", value: "\(length: torus.meanRadius)")
            GeometryInfoTableRow(label: "Tube radius [cm]: ", value: "\(length: torus.tubeRadius)")
            GeometryInfoTableRow(label: "Position [cm]: ", value: "\(position: torus.center)")
            GeometryInfoTableRow(label: "Axis: ", value: "\(direction: torus.axis)")
            GeometryInfoTableRow(label: "Angle [deg.]: ", value: "\(angle: angle)")
            GeometryInfoTableRow(label: "RMS error [cm]: ", value: "\(length: rmsError)")
        }
    }
}

fileprivate struct GeometryInfoTable: View {
    
    let object: PersistentObject
    
    var body: some View {
        switch object {
        case let .plane(_, plane, _, rmsError):            PlaneInfoTable(plane: plane, rmsError: rmsError)
        case let .sphere(_, sphere, _, rmsError):          SphereInfoTable(sphere: sphere, rmsError: rmsError)
        case let .cylinder(_, cylinder, _, rmsError):      CylinderInfoTable(cylinder: cylinder, rmsError: rmsError)
        case let .cone(_, cone, _, rmsError):              ConeInfoTable(cone: cone, rmsError: rmsError)
        case let .torus(_, torus, _, rmsError, _, angle):  TorusInfoTable(torus: torus, angle: angle, rmsError: rmsError)
        }
    }
}
