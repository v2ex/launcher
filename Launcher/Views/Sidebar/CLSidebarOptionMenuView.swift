//
//  CLSidebarOptionMenuView.swift
//  CodeLauncher
//
//  Created by Kai on 12/3/21.
//

import SwiftUI

struct CLSidebarOptionMenuView: View {
    @EnvironmentObject private var store: CLStore
    @State private var showErrorAlert = false
    @State private var error: Error?
    
    var project: CLProject

    var body: some View {
        VStack {
            Button {
                CLTaskManager.shared.editTargetProject(project: project)
            } label: {
                Text("Edit")
            }
            #if DEBUG
            Button {
                CLTaskManager.shared.duplicateProject(project: project)
            } label: {
                Text("Duplicate")
            }
            #endif
            Button {
                Task {
                    do {
                        try await CLTaskManager.shared.exportProject(project: project)
                    } catch {
                        self.showErrorAlert = true
                        self.error = error
                    }
                }
            } label: {
                Text("Export")
            }

            Divider()

            Button {
                store.isDeletingProject = true
            } label: {
                Text("Delete")
            }
        }.alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Error"),
                message: Text(error?.localizedDescription ?? "")
            )
        }
    }
}

struct CLSidebarOptionMenuView_Previews: PreviewProvider {
    static var previews: some View {
        CLSidebarOptionMenuView(project: CLProject(id: UUID(), created: Date(), name: "", description: "", tasks: [], autoStart: false))
    }
}
