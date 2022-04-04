//
//  CLTaskItemView.swift
//  CodeLauncher
//
//  Created by Kai on 12/5/21.
//

import Darwin
import SwiftUI


struct CLTaskItemView: View {
    @EnvironmentObject private var store: CLStore
    @Environment(\.openURL) var openURL

    var task: CLTask

    var body: some View {
        VStack {
            HStack {
                VStack {
                    CLTaskStatusIndicatorView(status: task.status).padding(.top, 3)

                    Spacer()
                }

                VStack {
                    Text(task.executable + " ")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        +
                        Text(task.arguments.replacingOccurrences(of: ",", with: " "))
                        .font(.system(size: 13, weight: .regular, design: .monospaced))

                    Spacer()
                }

                Spacer()

                VStack {
                    Button {
                        startStopTask(task: task)
                    } label: {
                        Image(systemName: taskIsRunning(task: task) ? "stop.circle" : "play.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 14, height: 14, alignment: .center)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer()
                }
            }

            if task.environments != "" || task.delay > 0 || task.autoStart {
                Spacer()
            }

            HStack {
                if task.environments != "" {
                    ForEach(task.environments.processedEnvironmentsLabels(), id: \.self) { env in
                        Text(env.processedTaskProperty())
                            .modifier(TaskPropertyLabelStyle())
                    }
                }

                Spacer()

                if task.delay > 0 {
                    Text("Delay \(String(format: "%.f", task.delay))")
                        .modifier(TaskPropertyLabelStyle())
                }

                if task.autoStart {
                    Text("Auto Start")
                        .modifier(TaskPropertyLabelStyle())
                }
            }
        }
        .padding(10)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(6)
        /* This style can be used for currently selected task for console output
         .overlay(
                 RoundedRectangle(cornerRadius: 6)
                         .stroke(Color.blue.opacity(0.2), lineWidth: 2)
         )
          */
        .contextMenu {
            Button {
                startStopTask(task: task)
            } label: {
                Image(systemName: taskIsRunning(task: task) ? "stop.fill" : "play.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 14, height: 14, alignment: .center)
                Text(taskIsRunning(task: task) ? "Stop" : "Run")
            }

            Divider()

            if task.hasServicePort {
                Button {
                    openURL(URL(string: "http://localhost:" + String(task.servicePort))!)
                } label: {
                    Image(systemName: "globe")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 14, height: 14, alignment: .center)
                    Text("Open localhost:" + String(task.servicePort) + " in Browser")
                }
            }

            Button {
                openTerminal(task)
            } label: {
                Image(systemName: "terminal")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 14, height: 14, alignment: .center)
                Text("Open a Terminal")
            }

            if hasVSCode() {
                Button {
                    openVSCode(task)
                } label: {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 14, height: 14, alignment: .center)
                    Text("Open in VSCode")
                }
            }

            Button {
                revealInFinder(task)
            } label: {
                Image(systemName: "folder")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 14, height: 14, alignment: .center)
                Text("Reveal in Finder")
            }

            Divider()

            if taskIsRunning(task: task) {
                Button {
                    let pid = String(store.taskProcesses[task.id.uuidString]!.processIdentifier)
                    store.isAlert = true
                    store.alertMessage = "Copied the process ID " + pid + " to the Clipboard."
                    copyProcessIDtoClipboard(pid)
                } label: {
                    Image(systemName: "command")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 14, height: 14, alignment: .center)
                    Text(taskIsRunning(task: task) ? "Copy PID " + String(store.taskProcesses[task.id.uuidString]!.processIdentifier) : "")
                }.alert(isPresented: $store.isAlert, content: {
                    Alert(title: Text("PID Copied"), message: Text("Copied")
                        .font(.system(.body)), dismissButton: Alert.Button.cancel(Text("OK")))
                })
            }
        }
    }

    private func startStopTask(task: CLTask) {
        store.currentViewingTaskID = task.id
        if store.taskProcesses[task.id.uuidString] == nil {
            CLTaskManager.shared.startTask(task: task)
        } else {
            CLTaskManager.shared.stopTask(task: task)
        }
    }

    private func taskIsRunning(task: CLTask) -> Bool {
        if store.taskProcesses[task.id.uuidString] == nil {
            return false
        }
        return true
    }

    private func copyProcessIDtoClipboard(_ pid: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(pid, forType: .string)
    }

    private func openTerminal(_ task: CLTask) {
        guard
            let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Terminal")
        else { return }

        let url = URL(fileURLWithPath: task.directory)

        NSWorkspace.shared.open([url], withApplicationAt: appUrl, configuration: self.openConfiguration(), completionHandler: nil)
    }

    private func hasVSCode() -> Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.microsoft.VSCode") != nil
    }

    private func openVSCode(_ task: CLTask) {
        guard
            let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.microsoft.VSCode")
        else { return }

        let url = URL(fileURLWithPath: task.directory)
        NSWorkspace.shared.open([url], withApplicationAt: appUrl, configuration: self.openConfiguration(), completionHandler: nil)
    }

    private func revealInFinder(_ task: CLTask) {
        let url = URL(fileURLWithPath: task.directory)
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
    }
    
    private func openConfiguration() -> NSWorkspace.OpenConfiguration {
        let conf = NSWorkspace.OpenConfiguration()
        conf.hidesOthers = false
        conf.hides = false
        conf.activates = true
        return conf
    }
}

struct CLTaskItemView_Previews: PreviewProvider {
    static var previews: some View {
        CLTaskItemView(task: CLTask(id: UUID(), projectID: UUID(), created: Date(), executable: "", directory: "", arguments: "", environments: "", delay: 0, autoStart: false))
    }
}
