//
//  CLTaskManager.swift
//  launcher
//
//  Created by Kai on 11/18/21.
//

import Cocoa
import Foundation
import ServiceManagement
import UserNotifications

class CLTaskManager: NSObject {
    static let shared: CLTaskManager = .init()

    private var unitTesting: Bool = {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }()

    override private init() {
        super.init()
    }

    func setup() {
        debugPrint("CL Task Manager Setup")
        _ = CLStore.shared
        setupExecutableProfilesForCurrentUser()
        setupNotifications()
        processProjects()
    }

    func cleanup() {
        debugPrint("CL Task Manager Cleanup")
        for (_, p) in CLStore.shared.taskProcesses {
            p.terminate()
        }
        DispatchQueue.main.async {
            CLStore.shared.taskProcesses = [:]
        }
    }

    func setupExecutableProfilesForCurrentUser() {
        let processENV = ProcessInfo.processInfo.environment
        for k in processENV.keys {
            if k == "SHELL", let s = processENV[k] {
                CLStore.shared.envSHELL = s
            } else if k == "PATH", let s = processENV[k] {
                CLStore.shared.envPATH = s
            }
        }
        // /opt/homebrew/bin:/opt/homebrew/sbin
        // /usr/local/bin
        let optionals: [String] = ["/opt/homebrew/sbin", "/opt/homebrew/bin", "/usr/local/bin"]
        let currentENVPath = CLStore.shared.envPATH
        for op in optionals {
            if !currentENVPath.contains(op) {
                CLStore.shared.envPATH = op + ":" + CLStore.shared.envPATH
            }
        }
    }

    func setupNotifications() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
            if settings.alertSetting == .disabled {
                center.requestAuthorization(options: [.alert]) { granted, error in
                    debugPrint("alert settings granted?: \(granted), error: \(error)")
                }
            } else {
                debugPrint("alert settings granted.")
            }
        }
    }

    func processProjects() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            for p in CLStore.shared.projects {
                if p.autoStart {
                    self.autoStartProject(project: p)
                }
            }
        }
    }

    func addNewProject() {
        let projectID = UUID()
        let now = Date()
        let task = CLTask(id: UUID(), projectID: projectID, created: now, executable: "", directory: currentUserHomePath().path, arguments: "", delay: 0, autoStart: false)
        DispatchQueue.main.async {
            CLStore.shared.currentProjectID = projectID
            CLStore.shared.editingProject = CLProject(id: projectID, created: now, name: "", description: "", tasks: [task], autoStart: false)
            CLStore.shared.isEditingProject = true
        }
    }

    func editProject() {
        guard let p = CLStore.shared.loadProject(byID: CLStore.shared.currentProjectID) else { return }
        DispatchQueue.main.async {
            CLStore.shared.editingProject = p
            CLStore.shared.isEditingProject = true
        }
    }

    func editTargetProject(project: CLProject) {
        DispatchQueue.main.async {
            CLStore.shared.editingProject = project
            CLStore.shared.isEditingProject = true
        }
    }

    func removeProject(project: CLProject) {
        for t in project.tasks {
            stopTask(task: t)
        }
        let ps = CLStore.shared.projects
        var updatedPS: [CLProject] = []
        for p in ps {
            if p.id == project.id {
                continue
            }
            updatedPS.append(p)
        }
        DispatchQueue.main.async {
            CLStore.shared.projects = updatedPS
            CLStore.shared.projectOutputs = CLStore.shared.projectOutputs.filter { output in
                if output.projectID == project.id {
                    return false
                }
                return true
            }
            CLStore.shared.currentProjectID = UUID()
        }
        removeProjectAvatar(projectID: project.id)
    }

    func importProject(fromJSONPath path: URL) {
        let decoder = JSONDecoder()
        do {
            let data = try Data(contentsOf: path)
            let project = try decoder.decode(CLProject.self, from: data)
            var shouldSkipImport = false

            if CLStore.shared.projects.filter({ p in
                p.id == project.id
            }).count > 0 {
                shouldSkipImport = true
            }

            if !shouldSkipImport {
                for task in project.tasks {
                    for p in CLStore.shared.projects {
                        if p.tasks.filter({ t in
                            t.id == task.id
                        }).count > 0 {
                            shouldSkipImport = true
                            break
                        }
                    }
                }
            }

            if shouldSkipImport {
                DispatchQueue.main.async {
                    CLStore.shared.alertTitle = "Failed to Import Project"
                    CLStore.shared.alertMessage = "The project you are importing exists in the database."
                    CLStore.shared.isAlert = true
                }
                return
            }

            DispatchQueue.main.async {
                CLStore.shared.projects.append(project)
            }
        } catch {
            debugPrint("failed to import project: \(error)")
        }
    }

    func exportProject(project: CLProject) {
        let panel = NSSavePanel()
        let encoder = JSONEncoder()
        encoder.outputFormatting = .withoutEscapingSlashes
        panel.nameFieldLabel = "Export Project"
        panel.nameFieldStringValue = project.name.lowercased().replacingOccurrences(of: " ", with: "-") + ".json"
        panel.canCreateDirectories = true
        panel.begin { response in
            if response == NSApplication.ModalResponse.OK, let fileUrl = panel.url {
                do {
                    let data = try encoder.encode(project)
                    try data.write(to: fileUrl)
                } catch {
                    debugPrint("failed to export project: \(error).")
                }
            }
        }
    }

    func resizedProjectAvatarImage(image: NSImage) -> NSImage {
        let targetImage: NSImage
        let targetImageSize = CGSize(width: 64, height: 64)
        if min(image.size.width, image.size.height) > targetImageSize.width / 2.0 {
            targetImage = image.imageResize(targetImageSize) ?? image
        } else {
            targetImage = image
        }
        return targetImage
    }

    func projectAvatar(projectID id: UUID, isEditing: Bool = false) -> NSImage? {
        let imageURL = avatarPath(forProjectID: id, isEditing: isEditing)
        if FileManager.default.fileExists(atPath: imageURL.path) {
            return NSImage(contentsOf: imageURL)
        }
        return nil
    }

    func updateProjectAvatar(image: NSImage, isEditing: Bool = false) {
        let imageURL = avatarPath(forProjectID: CLStore.shared.editingProject.id, isEditing: isEditing)
        let targetImage = resizedProjectAvatarImage(image: image)
        targetImage.imageSave(imageURL)
    }

    func removeProjectAvatar(projectID id: UUID, isEditing: Bool = false) {
        let imageURL = avatarPath(forProjectID: id, isEditing: isEditing)
        try? FileManager.default.removeItem(at: imageURL)
    }

    func resetDatabase() {
        DispatchQueue.main.async {
            CLStore.shared.projects.removeAll()
            CLStore.shared.projectOutputs.removeAll()
            CLStore.shared.currentProjectID = UUID()
        }
    }

    func startTasks(fromProject project: CLProject) {
        for t in project.tasks {
            startTask(task: t)
        }
    }

    func stopTasks(fromProject project: CLProject) {
        for t in project.tasks {
            stopTask(task: t)
        }
    }

    func startTask(task: CLTask) {
        guard CLStore.shared.taskProcesses[task.id.uuidString] == nil else { return }
        task.launchTask { process, completed, output in
            if completed {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    CLStore.shared.taskProcesses.removeValue(forKey: task.id.uuidString)
                }
                if let p = process {
                    if p.isRunning == false, p.terminationStatus != 0 {
                        self.sendNotification(forTask: task, started: false, failed: true)
                        self.restartFailedTask(task: task)
                        return
                    }
                }
                self.sendNotification(forTask: task, started: false)
            } else {
                if let o = output, o != "" {
                    var processedOutputs: [String] = []
                    if (o as NSString).range(of: "\n", options: .caseInsensitive).location != NSNotFound {
                        for processedString in o.components(separatedBy: "\n") {
                            processedOutputs.append(processedString)
                        }
                    } else {
                        processedOutputs.append(o)
                    }

                    for processedOutput in processedOutputs {
                        let taskOutput = CLTaskOutput(id: UUID(), taskID: task.id, projectID: task.projectID, content: processedOutput)
                        DispatchQueue.main.async {
                            CLStore.shared.projectOutputs.append(taskOutput)
                        }
                    }
                    
                    DispatchQueue.main.async {
                        if CLStore.shared.taskProcesses[task.id.uuidString] == nil {
                            CLStore.shared.taskProcesses[task.id.uuidString] = process
                            self.sendNotification(forTask: task, started: true)
                        }
                    }
                } else if output == nil {
                    DispatchQueue.global(qos: .utility).async {
                        DispatchQueue.main.async {
                            if CLStore.shared.taskProcesses[task.id.uuidString] == nil {
                                CLStore.shared.taskProcesses[task.id.uuidString] = process
                                self.sendNotification(forTask: task, started: true)
                            }
                        }
                    }
                }
            }
        }
    }

    func stopTask(task: CLTask) {
        var taskProcesses = CLStore.shared.taskProcesses
        guard taskProcesses[task.id.uuidString] != nil else { return }
        var targetProcess: Process?
        for (taskUUIDString, taskProcess) in taskProcesses {
            if taskUUIDString == task.id.uuidString {
                targetProcess = taskProcess
                break
            }
        }
        if let p = targetProcess {
            p.terminate()
        }
        taskProcesses.removeValue(forKey: task.id.uuidString)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            CLStore.shared.taskProcesses = taskProcesses
        }
    }

    func autoStartProject(project: CLProject) {
        for task in project.tasks {
            if task.autoStart {
                startTask(task: task)
            }
        }
    }

    func restartTask(byTaskUUID uuid: UUID) {
        let ps = CLStore.shared.projects
        for p in ps {
            for task in p.tasks {
                if task.id == uuid {
                    startTask(task: task)
                    return
                }
            }
        }
    }

    func restartFailedTask(task: CLTask) {
        guard UserDefaults.standard.bool(forKey: String.settingsAutoRestartFailedTaskKey) else { return }

        // Set a maxium retry count for this task.
        // If exceeds:
        // - Ignore this task
        // - Turn off auto restart option
        // - Retry count of this task will be reset when turned on auto restart option again.

        let count = CLStore.shared.retriedTasks[task.id.uuidString] ?? 0
        if count > 10 {
            UserDefaults.standard.set(false, forKey: String.settingsAutoRestartFailedTaskKey)
            DispatchQueue.main.async {
                CLStore.shared.retriedTasks.removeValue(forKey: task.id.uuidString)
            }
            return
        }
        DispatchQueue.global(qos: .background).async {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                DispatchQueue.global(qos: .utility).async {
                    self.startTask(task: task)
                }
                CLStore.shared.retriedTasks[task.id.uuidString] = count + 1
            }
        }
    }

    func sendNotification(forTask task: CLTask, started: Bool, failed: Bool = false) {
        guard UserDefaults.standard.bool(forKey: String.settingsUseNotificationForTaskStatusKey) else { return }
        let title = failed ? "Task Failed" : (started ? "Task Started" : "Task Finished")
        let subtitle = task.executable + " " + task.arguments.replacingOccurrences(of: ",", with: "")
        let content = UNMutableNotificationContent()
        content.title = title
        content.categoryIdentifier = String.taskCompleteIdentifier
        content.body = subtitle
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    func updateLaunchOption() {
        let launcherAppID = "com.v2ex.CodeLauncher.helper"
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = !runningApps.filter { $0.bundleIdentifier == launcherAppID }.isEmpty
        let currentLaunchOption = UserDefaults.standard.bool(forKey: String.settingsLaunchOptionKey)
        let succeed = SMLoginItemSetEnabled(launcherAppID as CFString, currentLaunchOption)
        if isRunning {
            DistributedNotificationCenter.default().post(name: .killHelper, object: Bundle.main.bundleIdentifier!)
        }
        if !succeed {
            UserDefaults.standard.set(false, forKey: String.settingsLaunchOptionKey)
        } else {
            UserDefaults.standard.set(!currentLaunchOption, forKey: String.settingsLaunchOptionKey)
        }
    }

    func avatarPath(forProjectID id: UUID, isEditing: Bool = false) -> URL {
        let path = _basePath().appendingPathComponent(isEditing ? "avatars_editing" : "avatars")
        if !FileManager.default.fileExists(atPath: path.path) {
            try? FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
        }
        return path.appendingPathComponent(id.uuidString + ".png")
    }

    func databasePath() -> URL {
        _basePath().appendingPathComponent("projects.json")
    }

    func taskPath() -> URL {
        _basePath().appendingPathComponent("task_pid.json")
    }

    func currentUserHomePath() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
    }

    private func _applicationSupportPath() -> URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
    }

    private func _basePath() -> URL {
        #if DEBUG
            let bundleID = Bundle.main.bundleIdentifier ?? "codelauncher_dev"
        #else
            let bundleID = Bundle.main.bundleIdentifier ?? "codelauncher"
        #endif
        let path: URL
        if let p = _applicationSupportPath() {
            path = p.appendingPathComponent(bundleID, isDirectory: true)
        } else {
            path = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("CodeLauncher")
        }
        if !FileManager.default.fileExists(atPath: path.path) {
            try? FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
        }
        return path
    }
}
