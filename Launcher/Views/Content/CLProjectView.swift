//
//  CLTaskGroupView.swift
//  CodeLauncher
//
//  Created by Kai on 11/20/21.
//

import SwiftUI

struct CLProjectView: View {
    @EnvironmentObject private var store: CLStore
    @State private var showErrorAlert = false
    @State private var error: Error?
    
    var isCreatingProject: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            VStack {
                HStack {
                    Text(isCreatingProject ? "New Project" : "Edit Project")
                        .font(.title)
                    Spacer()
                }
                .padding(.top, 12)

                HStack {
                    VStack {
                        HStack {
                            HStack {
                                Text("Name")
                                Spacer()
                            }
                            .frame(width: 82)
                            TextField("", text: $store.editingProject.name)
                                .textFieldStyle(ProjectTextFieldStyle(isCommandArguments: false))
                        }

                        HStack {
                            HStack {
                                Text("Description")
                                Spacer()
                            }
                            .frame(width: 82)
                            TextField("", text: $store.editingProject.description)
                                .textFieldStyle(ProjectTextFieldStyle(isCommandArguments: false))
                        }
                    }

                    VStack {
                        CLProjectAvatarView(project: store.editingProject, inEditMode: true)
                        HStack {
                            Spacer()
                            Text("Avatar")
                            Spacer()
                        }
                    }
                    .frame(width: 60, alignment: .center)
                }

                HStack {
                    Toggle("Launch Project Automatically", isOn: $store.editingProject.autoStart)
                    Spacer()
                }

                Divider()
                    .padding(.vertical, 10)

                HStack {
                    Text(store.editingProject.tasks.count > 1 ? "Tasks (\(store.editingProject.tasks.count))" : "Tasks")
                    Spacer()
                    Button {
                        store.editingProject.tasks.append(CLTask(id: UUID(), projectID: store.editingProject.id, created: Date(), executable: "", directory: CLTaskManager.shared.currentUserHomePath().path, arguments: "", delay: 0))
                    } label: {
                        Image(systemName: "plus")
                            .resizable()
                            .frame(width: 12, height: 12, alignment: .center)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 4)

                if store.editingProject.tasks.count > 0 {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach($store.editingProject.tasks, id: \.id) { t in
                                CLTaskView(task: t)
                            }
                        }
                    }
                } else {
                    Spacer()
                }
            }
            .padding(.horizontal, 16)

            Divider()

            HStack {
                Button {
                    store.isEditingProject = false
                    CLTaskManager.shared.removeProjectAvatar(projectID: store.editingProject.id, isEditing: true)
                } label: {
                    Text("Cancel")
                }
                .keyboardShortcut(.escape, modifiers: [])
                .keyboardShortcut(.cancelAction)

                Spacer()
                
                Button {
                    if isCreatingProject {
                        store.projects.insert(store.editingProject, at: 0)
                    } else {
                        do {
                            try store.saveProject(project: store.editingProject)
                        } catch {
                            self.showErrorAlert = true
                            self.error = error
                        }
                    }
                    store.isEditingProject = false
                } label: {
                    Text(store.editingProject.autoStart ? "Save and Launch" : "Save")
                }
                .disabled(store.editingProject.name == "")
                .keyboardShortcut(.defaultAction)
                .alert(isPresented: $showErrorAlert) {
                    Alert(
                        title: Text("Error"),
                        message: Text(self.error?.localizedDescription ?? "")
                    )
                }
            }
            .padding()
        }
        .frame(width: 600, height: 560, alignment: .center)
    }
}
