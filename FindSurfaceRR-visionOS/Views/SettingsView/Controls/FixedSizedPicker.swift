//
//  FixedSizedPicker.swift
//  FindSurfaceRR-visionOS
//
//  Created by CurvSurf-SGKim on 8/29/24.
//

import Foundation
import SwiftUI

fileprivate struct PickerWidthReaderWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

fileprivate struct PickerWidthReader<SelectionValue: Hashable, Content: View>: View {
    
    let items: [SelectionValue]
    let makeLabel: (SelectionValue) -> String
    @ViewBuilder let content: (CGFloat) -> Content
    
    @State private var width: CGFloat = 0
    
    var body: some View {
        ZStack {
            ForEach(items, id: \.self) { item in
                Picker("", selection: .constant(item)) {
                    Text(makeLabel(item)).lineLimit(1).fixedSize().tag(item)
                }
                .lineLimit(1).fixedSize()
            }
            .clipShape(.capsule)
            .labelsHidden()
            .hidden()
            .disabled(true)
            .background(GeometryReader { geometry in
                Color.clear
                    .preference(key: PickerWidthReaderWidthPreferenceKey.self,
                                value: geometry.size.width)
            })
            .onPreferenceChange(PickerWidthReaderWidthPreferenceKey.self) { width in
                self.width = width
            }
            
            content(width)
        }
    }
}

struct FixedSizedPicker<SelectionValue: Hashable>: View {
    
    let items: [SelectionValue]
    @Binding var selection: SelectionValue
    let makeLabel: (SelectionValue) -> String
    
    var body: some View {
        ZStack {
            PickerWidthReader(items: items, makeLabel: makeLabel) { width in
                Picker("", selection: $selection) {
                    ForEach(items, id: \.self) { item in
                        Text(makeLabel(item))
                            .lineLimit(1).fixedSize().tag(item)
                    }
                }
                .lineLimit(1).fixedSize()
                .hoverEffect(.automatic)
                .clipShape(.capsule)
                .labelsHidden()
                .frame(width: width > 0 ? width + 16 : nil,
                       alignment: .center)
            }
        }
    }
}

extension FixedSizedPicker {
    init(selection: Binding<SelectionValue>,
         makeLabel: @escaping (SelectionValue) -> String
    ) where SelectionValue: CaseIterable {
        self.init(items: Array(SelectionValue.allCases),
                  selection: selection,
                  makeLabel: makeLabel)
    }
}
