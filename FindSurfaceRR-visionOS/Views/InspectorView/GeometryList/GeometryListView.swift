//
//  GeometryListView.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 8/28/24.
//

import Foundation
import SwiftUI

struct GeometryListView: View {
    
    @Environment(\.dismissWindow) private var dismissWindow
    
    @Environment(ScenePhaseTracker.self) private var scenePhaseTracker
    @Environment(WorldTrackingManager.self) private var worldManager
    
    @State private var shouldShowConfirmDialog: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            
            ListTitleBar(shouldShowConfirmDialog: $shouldShowConfirmDialog, 
                         deleteButtonDisabled: worldManager.geometries.isEmpty) {
                Title()
            }
            
            let objects = zip(worldManager.geometryKeys, worldManager.geometryValues).map {
                ($0, $1)
            }
            if objects.isEmpty {
                GeometryListEmptyView()
            } else {
                List {
                    ForEach(objects, id: \.0) { object in
                        GeometryListItemView(isSelected: .constant(false), key: object.0, object: object.1)
                    }
                }
                .toolbar {
                    EditButton()
                }
            }
        }
        .listStyle(.sidebar)
        .confirmationDialog("Before Deleting...", isPresented: $shouldShowConfirmDialog, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if scenePhaseTracker.activeScene.contains(.share) {
                    dismissWindow(sceneID: SceneID.share)
                }
                worldManager.reset()
                shouldShowConfirmDialog = false
            }
            Button("Cancel", role: .cancel) {
                shouldShowConfirmDialog = false
            }
        } message: {
            VStack {
                Text("Are you sure to delete \(worldManager.geometryKeys.count) objects?")
                    .padding(.bottom, 8)
                
                Text("This will **delete** the geometries **permanently**\nand you cannot undo this action.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)
            }
        }
    }
    
    struct Title: View {
        var body: some View {
            Label("Geometries", systemImage: "doc.text.magnifyingglass")
        }
    }
}
