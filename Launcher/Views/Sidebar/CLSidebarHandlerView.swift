//
//  CLSidebarHandlerView.swift
//  CodeLauncher
//
//  Created by Kai on 7/3/22.
//

import SwiftUI


private class CLSidebarHandlerBaseView: NSView {
    var project: CLProject

    init(withProject p: CLProject) {
        project = p
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        DispatchQueue.main.async {
            CLStore.shared.currentProjectID = self.project.id
        }
    }
}


struct CLSidebarHandlerView: NSViewRepresentable {
    var project: CLProject

    func makeNSView(context: Context) -> some NSView {
        CLSidebarHandlerBaseView(withProject: project)
    }

    func updateNSView(_ nsView: NSViewType, context: Context) {
    }
}
