//
//  LogMessageListView.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 9/3/24.
//

import Foundation
import SwiftUI

struct LogMessageListView: View {
    
    @Environment(Logger.self) private var logger
    
    
    @Environment(\.currentDate) private var currentDate: Date
    
    @AppStorage("display-message-level-icons") private var displayMessageLevelIcons: Bool = true
    
    @State private var shouldShowConfirmDialog: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            
            ListTitleBar(shouldShowConfirmDialog: $shouldShowConfirmDialog,
                         deleteButtonDisabled: logger.messages.isEmpty) {
                Title()
            }
            
            if logger.messages.isEmpty {
                LogMessageListEmptyView()
            } else {
                
                Divider()
                    .overlay(Color.white)
                    .padding(.horizontal, 26)
                
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading) {
                            
                            ForEach(logger.messages, id: \.self) { message in
                                LogMessageListItemView(message: message)
                                    .id(message)
                            }
                        }
                        .onChange(of: logger.messages) {
                            scrollToLatest(proxy)
                        }
                    }
                    .onAppear {
                        scrollToLatest(proxy)
                    }
                }
                .padding(displayMessageLevelIcons ? .trailing : .horizontal, 24)
                
                Divider()
                    .overlay(Color.white)
                    .padding(.horizontal, 26)
            }
        }
        .confirmationDialog("Before Deleting...", isPresented: $shouldShowConfirmDialog, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                logger.clear()
                shouldShowConfirmDialog = false
            }
            Button("Cancel", role: .cancel) {
                shouldShowConfirmDialog = false
            }
        } message: {
            VStack {
                Text("Are you sure to delete \(logger.messages.count) log messages?")
                    .padding(.bottom, 8)
                
                Text("This will **delete** the log messages **permanently**\nand you cannot undo this action.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)
            }
        }

    }
    
    private func scrollToLatest(_ proxy: ScrollViewProxy) {
        withAnimation {
            if let lastMessage = logger.messages.last {
                proxy.scrollTo(lastMessage)
            }
        }
    }
    
    struct Title: View {
        var body: some View {
            Label("Logs", systemImage: "clock")
        }
    }
}
