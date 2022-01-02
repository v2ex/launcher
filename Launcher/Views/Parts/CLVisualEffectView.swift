//
//  CLVisualEffectView.swift
//  CodeLauncher
//
//  Created by Kai on 12/16/21.
//

import SwiftUI

struct CLVisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .sidebar

    func makeNSView(context _: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.isEmphasized = true
        view.material = material
        return view
    }

    func updateNSView(_: NSVisualEffectView, context _: Context) {}
}
