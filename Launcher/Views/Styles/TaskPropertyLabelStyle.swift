//
//  TaskPropertyLabelStyle.swift
//  CodeLauncher
//
//  Created by Kai on 12/5/21.
//

import SwiftUI

struct TaskPropertyLabelStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .lineLimit(1)
            .font(.system(size: 11, weight: .light, design: .monospaced))
            .padding(.vertical, 2)
            .padding(.horizontal, 4)
            .background(Color.secondary.opacity(0.15))
            .cornerRadius(4)
    }
}
