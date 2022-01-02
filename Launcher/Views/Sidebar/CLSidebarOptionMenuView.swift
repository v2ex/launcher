//
//  CLSidebarOptionMenuView.swift
//  CodeLauncher
//
//  Created by Kai on 12/3/21.
//

import SwiftUI

struct CLSidebarOptionMenuView: View {
    @EnvironmentObject private var store: CLStore

    var project: CLProject

    var body: some View {
        VStack {
            Button {
                CLTaskManager.shared.editTargetProject(project: project)
            } label: {
                Text("Edit")
            }

            Button {
                CLTaskManager.shared.exportProject(project: project)
            } label: {
                Text("Export")
            }

            Divider()

            Button {
                store.isDeletingProject = true
            } label: {
                Text("Delete")
            }
        }
    }
}

struct CLSidebarOptionMenuView_Previews: PreviewProvider {
    static var previews: some View {
        CLSidebarOptionMenuView(project: CLProject(id: UUID(), created: Date(), name: "", description: "", tasks: [], autoStart: false))
    }
}
