//
//  CLConsoleView.swift
//  CodeLauncher
//
//  Created by Kai on 11/24/21.
//

import Foundation
import SwiftUI

// TODO: Functions for Color
// Here we need more functions to return Color based on the setting value of Appearance
// Four possibilities: dark, light, device, reverse

private func outputsForegroundColor(index: Int = 0) -> Color {
    index % 2 == 0 ? Color("ConsoleOutputsForegroundIndexed") : Color("ConsoleOutputsForeground")
}

private func outputsBackgroundColor(index: Int = 0) -> Color {
    index % 2 == 0 ? Color("ConsoleOutputsBackgroundIndexed") : Color("ConsoleOutputsBackground")
}

private struct CLTaskIndexedOutput: Hashable, Identifiable {
    let id: UUID
    let index: Int
    let output: CLTaskOutput
}

private struct TaskConsoleOutputTextStyle: ViewModifier {
    var output: CLTaskIndexedOutput

    func body(content: Content) -> some View {
        content
            .font(.system(size: 13, weight: .regular, design: .monospaced))
            .foregroundColor(outputsForegroundColor(index: output.index))
    }
}

@available(macOS 12.0, *)
private struct TaskConsoleOutputTextSelectionStyle: ViewModifier {
    var output: CLTaskIndexedOutput

    func body(content: Content) -> some View {
        content
            .textSelection(.enabled)
            .font(.system(size: 13, weight: .regular, design: .monospaced))
            .foregroundColor(outputsForegroundColor(index: output.index))
    }
}

private struct CLTaskIndexedOutputView: View {
    var output: CLTaskIndexedOutput

    var body: some View {
        HStack {
            if #available(macOS 12.0, *) {
                Text(output.output.content)
                    .modifier(TaskConsoleOutputTextSelectionStyle(output: output))
            } else {
                Text(output.output.content)
                    .modifier(TaskConsoleOutputTextStyle(output: output))
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .id(output.id)
        .background(outputsBackgroundColor(index: output.index))
    }
}

struct CLConsoleView: View {
    @EnvironmentObject private var store: CLStore

    var project: CLProject

    @State private var taskID: UUID!
    @State private var lastTaskOutputID: UUID!

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack {
                        ForEach(outputsWithIndex(outputs: store.projectOutputs.filter { t in
                            if t.projectID == store.currentProjectID {
                                if let taskID = taskID {
                                    if taskID == t.taskID {
                                        return true
                                    } else if store.selectedTaskIndex == -1 {
                                        return true
                                    }
                                } else {
                                    return true
                                }
                            }
                            return false
                        }), id: \.id) { t in
                            CLTaskIndexedOutputView(output: t)
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .scrollDownToLatestConsoleOutput, object: nil)) { n in
                    guard let taskOutput = n.object as? CLTaskOutput else {
                        if let lastID = lastTaskOutputID {
                            DispatchQueue.main.async {
                                proxy.scrollTo(lastID, anchor: .top)
                            }
                        }
                        return
                    }
                    if let taskID = taskID {
                        if taskID != taskOutput.taskID {
                            return
                        }
                    }
                    DispatchQueue.main.async {
                        proxy.scrollTo(taskOutput.id, anchor: .top)
                        self.lastTaskOutputID = taskOutput.id
                    }
                }
            }
            .background(outputsBackgroundColor())

            HStack(spacing: 16) {
                if project.tasks.count > 1 {
                    Picker("Show Output of", selection: $store.selectedTaskIndex) {
                        Text("All Tasks")
                            .tag(-1)
                        if project.tasks.count > 0 {
                            ForEach(0 ..< project.tasks.count, id: \.self) { index in
                                Text(project.tasks[index].executable + " " + project.tasks[index].arguments)
                                    .tag(index)
                            }
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: store.selectedTaskIndex) { updated in
                        if updated == -1 {
                            taskID = nil
                        } else {
                            if updated < project.tasks.count {
                                taskID = project.tasks[updated].id
                            }
                        }
                    }
                    .onChange(of: store.currentViewingTaskID) { updated in
                        taskID = updated
                        for i in 0 ..< project.tasks.count {
                            if project.tasks[i].id == updated {
                                store.selectedTaskIndex = i
                                break
                            }
                        }
                    }
                    .frame(minWidth: 140, idealWidth: 200, maxWidth: 500)
                }

                Spacer()

                Button {
                    DispatchQueue.main.async {
                        self.store.projectOutputs = self.store.projectOutputs.filter { output in
                            if output.projectID == self.store.currentProjectID {
                                if let taskID = self.taskID {
                                    if taskID == output.taskID {
                                        return false
                                    }
                                } else {
                                    return false
                                }
                            }
                            return true
                        }
                    }
                } label: {
                    Image(systemName: "trash.square")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 14, height: 14, alignment: .center)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .frame(height: 44)
            .padding(.horizontal, 16)
            .background(Color.secondary.opacity(0.05))
        }
        .padding(0)
    }

    private func outputsWithIndex(outputs: [CLTaskOutput]) -> [CLTaskIndexedOutput] {
        var indexedOutput: [CLTaskIndexedOutput] = []
        var index = 0
        for o in outputs {
            let t = CLTaskIndexedOutput(id: o.id, index: index, output: o)
            indexedOutput.append(t)
            index += 1
        }
        return indexedOutput
    }
}

struct CLConsoleView_Previews: PreviewProvider {
    static var previews: some View {
        CLConsoleView(project: CLProject(id: UUID(), created: Date(), name: "", description: "", tasks: [], autoStart: false))
    }
}
