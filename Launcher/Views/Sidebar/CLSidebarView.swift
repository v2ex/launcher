//
//  CLSidebarView.swift
//  launcher
//
//  Created by Kai on 11/18/21.
//

import SwiftUI

struct CLSidebarView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var store: CLStore

    @State private var project: CLProject!

    var body: some View {
        VStack(spacing: 0) {
            List {
                ForEach(store.projects, id: \.id) { p in
                    HStack(spacing: 6) {
                        CLProjectAvatarView(project: p, highlight: store.currentProjectID == p.id)
                        VStack {
                            HStack {
                                Text(p.name)
                                    .font(.system(size: 14, weight: .regular, design: .default))
                                    .foregroundColor(Color.primary)
                                Spacer()
                            }
                            if !p.description.isEmpty {
                                HStack {
                                    Text(p.description)
                                        .font(.system(size: 12, weight: .light, design: .default))
                                        .foregroundColor(Color.secondary)
                                        .lineLimit(2)
                                    Spacer()
                                }
                            }
                        }

                        Spacer()

                        HStack {
                            if store.activeProjects.filter { projectID in
                                projectID == p.id.uuidString
                            }.count > 0 {
                                CLTaskStatusIndicatorView(status: .running)
                            }
                            if p.tasks.count > 1 {
                                Text(String(p.tasks.count))
                                    .font(.system(size: 10, weight: .light, design: .rounded))
                                    .frame(width: 16, height: 16, alignment: .center)
                                    .padding(1)
                                    .foregroundColor(store.currentProjectID == p.id ? Color.black : Color.primary)
                                    .background(store.currentProjectID == p.id ? Color.white.opacity(0.5) : Color.secondary.opacity(0.2))
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
                    .background(store.currentProjectID == p.id ? Color("SidebarHighlight").opacity(colorScheme == .light ? 0.8 : 0.5) : Color.clear)
                    .contentShape(Rectangle())
                    .cornerRadius(6)
                    .onTapGesture {
                        DispatchQueue.main.async {
                            self.store.currentProjectID = p.id
                        }
                    }
                    .contextMenu {
                        CLSidebarOptionMenuView(project: p)
                            .environmentObject(store)
                    }
                }
                .onMove { indices, destination in
                    store.moveProject(fromOffsets: indices, toOffset: destination)
                }
            }

            HStack {
                Button {
                    CLTaskManager.shared.addNewProject()
                } label: {
                    Image(systemName: "plus")
                        .resizable()
                        .frame(width: 13, height: 13, alignment: .center)
                }
                .disabled(store.isEditingProject)
                .buttonStyle(PlainButtonStyle())
                .keyboardShortcut(.escape, modifiers: [])

                Spacer()

                Button {
                    store.isDeletingProject = true
                } label: {
                    Image(systemName: "trash")
                        .resizable()
                        .frame(width: 13, height: 13, alignment: .center)
                }
                .disabled(store.isEditingProject || store.loadProject(byID: store.currentProjectID) == nil)
                .buttonStyle(PlainButtonStyle())
                .keyboardShortcut(.escape, modifiers: [])
            }
            .frame(height: 44)
            .padding(.horizontal, 16)
        }
        .background(CLVisualEffectView())
        .alert(isPresented: $store.isDeletingProject, content: {
            Alert(title: Text("Are you sure to delete this project?"), primaryButton: Alert.Button.destructive(Text("Delete"), action: {
                guard store.isEditingProject == false else { return }
                if let p = store.loadProject(byID: store.currentProjectID) {
                    CLTaskManager.shared.removeProject(project: p)
                }
            }), secondaryButton: Alert.Button.cancel(Text("Cancel"), action: {}))
        })
        .padding(.bottom, 0)
    }
}

struct CLSidebarView_Previews: PreviewProvider {
    static var previews: some View {
        CLSidebarView()
    }
}
