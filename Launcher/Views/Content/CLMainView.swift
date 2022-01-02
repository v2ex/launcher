//
//  ContentView.swift
//  launcher
//
//  Created by Kai on 11/18/21.
//

import SwiftUI

struct CLMainView: View {
    @EnvironmentObject private var store: CLStore

    var body: some View {
        NavigationView {
            CLSidebarView()
                .environmentObject(store)
                .frame(minWidth: 260)
                .fileImporter(isPresented: $store.isImportingProject, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
                    if let urls = try? result.get(), let url = urls.first {
                        CLTaskManager.shared.importProject(fromJSONPath: url)
                    }
                }

            CLContentView()
                .environmentObject(store)
                .frame(minWidth: 420)
                .toolbar {
                    ToolbarItemGroup {
                        Spacer()

                        Button {
                            CLTaskManager.shared.editProject()
                        } label: {
                            Image(systemName: "info.circle")
                                .resizable()
                                .frame(width: 20, height: 20, alignment: .center)
                        }
                        .disabled(store.loadProject(byID: store.currentProjectID) == nil)
                        .keyboardShortcut("i", modifiers: [.command])

                        Button {
                            guard let p = store.loadProject(byID: store.currentProjectID) else { return }
                            CLTaskManager.shared.startTasks(fromProject: p)
                        } label: {
                            Image(systemName: "play.circle")
                                .resizable()
                                .frame(width: 20, height: 20, alignment: .center)
                        }
                        .disabled(store.isEditingProject || store.loadProject(byID: store.currentProjectID) == nil)
                        .keyboardShortcut("r", modifiers: [.command])

                        Button {
                            guard let p = store.loadProject(byID: store.currentProjectID) else { return }
                            CLTaskManager.shared.stopTasks(fromProject: p)
                        } label: {
                            Image(systemName: "stop.circle")
                                .resizable()
                                .frame(width: 20, height: 20, alignment: .center)
                        }
                        .disabled(store.isEditingProject || store.loadProject(byID: store.currentProjectID) == nil)
                        .keyboardShortcut("s", modifiers: [.command])
                    }
                }
                .sheet(isPresented: $store.isEditingProject) {} content: {
                    CLProjectView(isCreatingProject: store.loadProject(byID: store.currentProjectID) == nil ? true : false)
                        .environmentObject(store)
                }
                .alert(isPresented: $store.isAlert, content: {
                    Alert(title: Text(store.alertTitle), message: Text(store.alertMessage), dismissButton: Alert.Button.cancel(Text("OK")))
                })
        }
        .navigationTitle(store.loadProject(byID: store.currentProjectID)?.name ?? "CodeLauncher")
    }
}
