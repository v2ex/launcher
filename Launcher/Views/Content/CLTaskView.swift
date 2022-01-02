//
//  CLNewTaskView.swift
//  Code Launcher
//
//  Created by Kai on 11/26/21.
//

import SwiftUI

struct CLTaskView: View {
    @EnvironmentObject private var store: CLStore

    @Binding var task: CLTask

    @State private var isChoosingExecutablePath: Bool = false
    @State private var isChoosingDirectoryPath: Bool = false
    @State private var taskDelayIndex: Int = -1

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    HStack {
                        Text("Executable Path")
                            .font(.body)
                        Spacer()
                    }
                    .frame(width: 120)

                    TextField("", text: $task.executable)
                        .textFieldStyle(ProjectTextFieldStyle())

                    Spacer(minLength: 10)

                    Button {
                        isChoosingExecutablePath = true
                    } label: {
                        Image(systemName: "ellipsis")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 12, height: 12, alignment: .center)
                            .contentShape(Rectangle())
                    }
                    .fileImporter(isPresented: $isChoosingExecutablePath, allowedContentTypes: [.executable], allowsMultipleSelection: false) { result in
                        if let urls = try? result.get(), let url = urls.first {
                            self.task.executable = url.path
                        }
                    }
                }

                HStack {
                    HStack {
                        Text("Working Directory")
                            .font(.body)
                        Spacer()
                    }
                    .frame(width: 120)

                    TextField(CLTaskManager.shared.currentUserHomePath().path, text: $task.directory)
                        .textFieldStyle(ProjectTextFieldStyle())

                    Spacer(minLength: 10)

                    Button {
                        isChoosingDirectoryPath = true
                    } label: {
                        Image(systemName: "ellipsis")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 12, height: 12, alignment: .center)
                            .contentShape(Rectangle())
                    }
                    .fileImporter(isPresented: $isChoosingDirectoryPath, allowedContentTypes: [.directory], allowsMultipleSelection: false) { result in
                        if let urls = try? result.get(), let url = urls.first {
                            self.task.directory = url.path
                        }
                    }
                }

                HStack {
                    HStack {
                        Text("Arguments")
                            .font(.body)
                        Spacer()
                    }
                    .frame(width: 120)
                    TextField("Separate by space.", text: $task.arguments)
                        .textFieldStyle(ProjectTextFieldStyle())
                }

                HStack {
                    VStack {
                        HStack {
                            Text("Environments")
                                .font(.body)
                            Spacer()
                        }
                        Spacer()
                    }
                    .frame(width: 120)

                    VStack {
                        TextEditor(text: $task.environments)
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .frame(height: 46)
                            .cornerRadius(6)
                            .padding(1)
                            .shadow(color: .secondary.opacity(0.75), radius: 0.5, x: 0, y: 0.5)
                        HStack {
                            Text("Case sensitive, separate by lines.")
                                .font(.caption)
                                .foregroundColor(Color.secondary)
                                .padding(.leading, 4)
                            Spacer()
                        }
                    }
                }

                Divider()
                    .padding(.vertical, 8)

                HStack {
                    HStack {
                        Text(task.delay > 1 ? "Launch Delay in \(String(format: "%.f", task.delay)) Seconds" : "Launch Delay in \(String(format: "%.f", task.delay)) Second")
                        Spacer()
                    }
                    .frame(width: 200)

                    Spacer()

                    Picker(selection: $taskDelayIndex) {
                        Text("No delay")
                            .tag(-1)
                        Text("5 seconds")
                            .tag(0)
                        Text("10 seconds")
                            .tag(1)
                        Text("20 seconds")
                            .tag(2)
                        Text("30 seconds")
                            .tag(3)
                        Text("45 seconds")
                            .tag(4)
                        Text("60 seconds")
                            .tag(5)
                    } label: {
                        Text("")
                    }
                    .pickerStyle(.menu)
                    .onChange(of: taskDelayIndex) { updated in
                        task.delay = delayValueFromIndex(index: updated)
                    }
                    .frame(width: 160)
                }

                HStack {
                    HStack {
                        Text("Launch Option")
                        Spacer()
                    }
                    .frame(width: 180)
                    Spacer()
                    Toggle("Auto start when project launches", isOn: $task.autoStart)
                }
            }
            .padding()
            .padding(.top, 10)

            VStack {
                HStack {
                    Button {
                        deleteTask()
                    } label: {
                        Image(systemName: "xmark")
                            .resizable()
                            .frame(width: 10, height: 10, alignment: .center)
                            .padding(2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    Spacer()
                }
                .padding(.top, 4)
                .padding(.horizontal, 4)
                Spacer()
            }
            .padding(0)
        }
        .padding(0)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(5)
        .onAppear {
            taskDelayIndex = delayIndexFromValue(value: task.delay)
        }
    }

    private func deleteTask() {
        let tasks = store.editingProject.tasks.filter { t in
            if t.id == self.task.id {
                return false
            }
            return true
        }
        DispatchQueue.main.async {
            self.store.editingProject.tasks = tasks
        }
    }

    private func delayValueFromIndex(index: Int) -> Double {
        var delay: Double = 0
        switch index {
        case 0:
            delay = 5
        case 1:
            delay = 10
        case 2:
            delay = 20
        case 3:
            delay = 30
        case 4:
            delay = 45
        case 5:
            delay = 60
        default:
            delay = 0
        }
        return delay
    }

    private func delayIndexFromValue(value: Double) -> Int {
        var index: Int = -1
        switch value {
        case 5:
            index = 0
        case 10:
            index = 1
        case 20:
            index = 2
        case 30:
            index = 3
        case 45:
            index = 4
        case 60:
            index = 5
        default:
            index = -1
        }
        return index
    }
}
