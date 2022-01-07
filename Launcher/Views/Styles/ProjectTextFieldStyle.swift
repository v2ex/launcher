//
//  ProjectTextFieldStyle.swift
//  CodeLauncher
//
//  Created by Kai on 11/24/21.
//

import SwiftUI

struct ProjectTextFieldStyle: TextFieldStyle {
    var isCommandArguments: Bool = true

    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .font(.system(.body, design: isCommandArguments ? .monospaced : .default))
    }
}
