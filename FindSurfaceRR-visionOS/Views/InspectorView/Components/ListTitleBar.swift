//
//  GeometryListTitleBar.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 9/3/24.
//

import Foundation
import SwiftUI

fileprivate extension TimeZone {
    static var currentAbbreviation: String? {
        let dictionary = TimeZone.abbreviationDictionary
        let currentIdentifier = TimeZone.current.identifier
        return dictionary.filter { (abbreviation, identifier) in
            identifier == currentIdentifier
        }.first?.key
    }
}

struct ListTitleBar<Title: View>: View {
    
    @AppStorage("display-current-time") private var displayCurrentTime: Bool = true
    
    @Environment(\.currentDate) private var currentDate: Date
    
    @Binding var shouldShowConfirmDialog: Bool
    let deleteButtonDisabled: Bool
    let title: () -> Title
    
    var body: some View {
        HStack {
            
            title()
                .font(.title)
            
            Spacer()
            
            if displayCurrentTime {
                Text("\(timeFormatter.string(from: currentDate)) \(TimeZone.currentAbbreviation ?? "")")
            }
            
            Button {
                shouldShowConfirmDialog = true
            } label: {
                Image(systemName: "trash")
            }
            .clipShape(.circle)
            .buttonStyle(.borderedProminent)
            .disabled(deleteButtonDisabled)
        }
        .padding()
    }
}
