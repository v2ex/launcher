//
//  CLProjectAvatarView.swift
//  CodeLauncher
//
//  Created by Kai on 12/12/21.
//

import SwiftUI

struct CLProjectAvatarView: View {
    var project: CLProject
    var highlight: Bool = false
    var inEditMode: Bool = false

    @State private var updatedAvatarImage: NSImage!
    @State private var isChoosingAvatarImage: Bool = false
    @State private var showErrorAlert = false
    @State private var error: Error?
    
    var body: some View {
        VStack {
            if updatedAvatarImage == nil {
                Text(project.generateAvatarName())
                    .font(Font.custom("Arial Rounded MT Bold", size: 13))
                    .foregroundColor(Color.white)
                    .contentShape(Rectangle())
                    .frame(width: 32, height: 32, alignment: .center)
                    .background(LinearGradient(gradient: project.gradient(), startPoint: .top, endPoint: .bottom))
                    .cornerRadius(16)
            } else {
                Image(nsImage: updatedAvatarImage!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32, alignment: .center)
            }
        }
        .onTapGesture {
            guard inEditMode else { return }
            isChoosingAvatarImage = true
        }
        .fileImporter(isPresented: $isChoosingAvatarImage, allowedContentTypes: [.png, .jpeg, .tiff], allowsMultipleSelection: false) { result in
            if let urls = try? result.get(), let url = urls.first, let img = NSImage(contentsOf: url) {
                let targetImage = CLTaskManager.shared.resizedProjectAvatarImage(image: img)
                do {
                    try CLTaskManager.shared.updateProjectAvatar(image: targetImage, isEditing: true)
                    DispatchQueue.main.async {
                        self.updatedAvatarImage = targetImage
                    }
                } catch {
                    self.showErrorAlert = true
                    self.error = error
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .updateProjectAvatar, object: nil)) { _ in
            if let img = CLTaskManager.shared.projectAvatar(projectID: project.id) {
                DispatchQueue.main.async {
                    self.updatedAvatarImage = img
                }
            } else {
                DispatchQueue.main.async {
                    self.updatedAvatarImage = nil
                }
            }
        }
        .onAppear {
            if let img = CLTaskManager.shared.projectAvatar(projectID: project.id) {
                DispatchQueue.main.async {
                    self.updatedAvatarImage = img
                }
            }
        }
        .contextMenu {
            if inEditMode {
                VStack {
                    Button {
                        isChoosingAvatarImage = true
                    } label: {
                        Text("Upload Avatar")
                    }

                    Button {
                        CLTaskManager.shared.removeProjectAvatar(projectID: project.id, isEditing: inEditMode)
                        CLTaskManager.shared.removeProjectAvatar(projectID: project.id)
                        NotificationCenter.default.post(name: .updateProjectAvatar, object: nil)
                        DispatchQueue.main.async {
                            self.updatedAvatarImage = nil
                        }
                    } label: {
                        Text("Delete Avatar")
                    }
                }
            }
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Error"),
                message: Text(self.error?.localizedDescription ?? "")
            )
        }
    }
    
    private func updateProjectAvatar( _ targetImage: NSImage) {
        
    }
}

struct CLProjectAvatarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 15) {
            CLProjectAvatarView(project: CLProject(id: UUID(), created: Date(), name: "", description: "", tasks: [], autoStart: false))
                .frame(width: 32, height: 32, alignment: .center)
            CLProjectAvatarView(project: CLProject(id: UUID(), created: Date(), name: "Project Python", description: "", tasks: [], autoStart: false))
                .frame(width: 32, height: 32, alignment: .center)
            CLProjectAvatarView(project: CLProject(id: UUID(), created: Date(), name: "Sample Project", description: "", tasks: [], autoStart: false), highlight: true)
                .frame(width: 32, height: 32, alignment: .center)
            CLProjectAvatarView(project: CLProject(id: UUID(), created: Date(), name: "Sample Project With Descriptions", description: "", tasks: [], autoStart: false), highlight: true)
                .frame(width: 32, height: 32, alignment: .center)
            CLProjectAvatarView(project: CLProject(id: UUID(), created: Date(), name: "你好，世界", description: "", tasks: [], autoStart: false))
                .frame(width: 32, height: 32, alignment: .center)
            CLProjectAvatarView(project: CLProject(id: UUID(), created: Date(), name: "你好 世界", description: "", tasks: [], autoStart: false))
                .frame(width: 32, height: 32, alignment: .center)
            CLProjectAvatarView(project: CLProject(id: UUID(), created: Date(), name: "Wrangler", description: "", tasks: [], autoStart: false), highlight: true)
                .frame(width: 32, height: 32, alignment: .center)
            CLProjectAvatarView(project: CLProject(id: UUID(), created: Date(), name: "IPFS", description: "", tasks: [], autoStart: false), highlight: true)
                .frame(width: 32, height: 32, alignment: .center)
        }
        .padding()

        VStack(spacing: 15) {
            CLProjectAvatarView(project: CLProject(id: UUID(), created: Date(), name: "", description: "", tasks: [], autoStart: false))
                .frame(width: 32, height: 32, alignment: .center)
            CLProjectAvatarView(project: CLProject(id: UUID(), created: Date(), name: "Project Python", description: "", tasks: [], autoStart: false))
                .frame(width: 32, height: 32, alignment: .center)
            CLProjectAvatarView(project: CLProject(id: UUID(), created: Date(), name: "Sample Project", description: "", tasks: [], autoStart: false), highlight: true)
                .frame(width: 32, height: 32, alignment: .center)
            CLProjectAvatarView(project: CLProject(id: UUID(), created: Date(), name: "Sample Project With Descriptions", description: "", tasks: [], autoStart: false), highlight: true)
                .frame(width: 32, height: 32, alignment: .center)
            CLProjectAvatarView(project: CLProject(id: UUID(), created: Date(), name: "你好，世界", description: "", tasks: [], autoStart: false))
                .frame(width: 32, height: 32, alignment: .center)
            CLProjectAvatarView(project: CLProject(id: UUID(), created: Date(), name: "你好 世界", description: "", tasks: [], autoStart: false))
                .frame(width: 32, height: 32, alignment: .center)
            CLProjectAvatarView(project: CLProject(id: UUID(), created: Date(), name: "Wrangler", description: "", tasks: [], autoStart: false), highlight: true)
                .frame(width: 32, height: 32, alignment: .center)
            CLProjectAvatarView(project: CLProject(id: UUID(), created: Date(), name: "IPFS", description: "", tasks: [], autoStart: false), highlight: true)
                .frame(width: 32, height: 32, alignment: .center)
        }
        .preferredColorScheme(.dark)
        .padding()
    }
}
