//
//  CLStore.swift
//  launcher
//
//  Created by Kai on 11/18/21.
//

import Cocoa
import Combine
import Foundation
import SwiftUI


private actor CLDataStore {
    func saveProjects(_ projects: [CLProject]) {
        let databasePath = CLTaskManager.shared.databasePath()
        let encoder = JSONEncoder()
        encoder.outputFormatting = .withoutEscapingSlashes
        do {
            let data = try encoder.encode(projects)
            try data.write(to: databasePath, options: .atomic)
        } catch {
            debugPrint("failed to save tasks: \(error)")
        }
    }

    func loadProjects() -> [CLProject] {
        let databasePath = CLTaskManager.shared.databasePath()
        let decoder = JSONDecoder()
        do {
            let data = try Data(contentsOf: databasePath)
            return try decoder.decode([CLProject].self, from: data).sorted { a, b in
                a.created > b.created
            }
        } catch {
            debugPrint("failed to load tasks: \(error).")
        }
        return []
    }
}


class CLStore: ObservableObject {
    static let shared: CLStore = .init()

    private let store = CLDataStore()

    var envSHELL: String = ""
    var envPATH: String = ""

    @Published var currentViewingTaskID: UUID?

    @Published var projects: [CLProject] = [] {
        didSet {
            Task.detached {
                await self.store.saveProjects(self.projects)
            }
            if let uuidString = CLDefaults.default.lastActiveProjectUUID, let uuid = UUID(uuidString: uuidString) {
                DispatchQueue.main.async {
                    CLStore.shared.currentProjectID = uuid
                }
            }
        }
    }

    @Published var currentProjectID: UUID = .init() {
        didSet {
            CLDefaults.default.lastActiveProjectUUID = currentProjectID.uuidString

            if let index = CLDefaults[currentProjectID].lastSelectedTaskIndex {
                selectedTaskIndex = index
            } else {
                selectedTaskIndex = -1
            }

            let minTaskViewHeight: CGFloat = 84

            let lastActiveTaskViewHeight = CLDefaults[currentProjectID].lastActiveConsoleTaskViewHeight

            if lastActiveTaskViewHeight > 0 {
                outputTaskViewHeight = lastActiveTaskViewHeight
            } else {
                if let p = loadProject(byID: currentProjectID) {
                    if p.tasks.count > 3 {
                        outputTaskViewHeight = minTaskViewHeight * 3
                    } else if p.tasks.count == 0 {
                        outputTaskViewHeight = minTaskViewHeight
                    } else {
                        outputTaskViewHeight = minTaskViewHeight * CGFloat(p.tasks.count)
                    }
                } else {
                    outputTaskViewHeight = minTaskViewHeight
                }
            }

            outputConsoleClosed = CLDefaults[currentProjectID].lastSelectedProjectConsoleStatus

            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .scrollDownToLatestConsoleOutput, object: nil)
            }
        }
    }

    @Published var taskProcesses: [String: Process] = [:] {
        didSet {
            DispatchQueue.global(qos: .utility).async {
                self._updateExistingTasks()
            }

            DispatchQueue.global(qos: .background).async {
                var updatedActiveProjects: [String] = []
                for taskID in self.taskProcesses.keys {
                    for p in self.projects {
                        for t in p.tasks {
                            if taskID == t.id.uuidString {
                                if !updatedActiveProjects.contains(p.id.uuidString) {
                                    updatedActiveProjects.append(p.id.uuidString)
                                }
                            }
                        }
                    }
                }
                DispatchQueue.main.async {
                    self.activeProjects = updatedActiveProjects
                }
            }
        }
    }

    @Published var activeProjects: [String] = []

    @Published var selectedTaskIndex: Int = -1 {
        didSet {
            CLDefaults[currentProjectID].lastSelectedTaskIndex = selectedTaskIndex
        }
    }

    @Published var outputConsoleClosed: Bool = false {
        didSet {
            CLDefaults[currentProjectID].lastSelectedProjectConsoleStatus = outputConsoleClosed
        }
    }

    @Published var outputTaskViewHeight: CGFloat = 84

    @Published var editingProject: CLProject!

    @Published var isAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""

    @Published var isEditingProject: Bool = false
    @Published var isDeletingProject: Bool = false
    @Published var isImportingProject: Bool = false

    init() {
        debugPrint("CL Store Init.")

        Task.init {
            let p = await self.store.loadProjects()
            await MainActor.run {
                self.projects = p
            }
            self._detectExistingTasks()
        }
    }

    subscript(projectID: CLProject.ID?) -> CLProject {
        get {
            if let id = projectID {
                return projects.first(where: { $0.id == id }) ?? .placeholder
            }
            return .placeholder
        }

        set(newValue) {
            if let id = projectID {
                projects[projects.firstIndex(where: { $0.id == id })!] = newValue
            }
        }
    }

    func loadProject(byID id: UUID) -> CLProject? {
        projects.filter { t in
            t.id == id
        }.first
    }

    func saveProject(project: CLProject) {
        if self[project.id].tasks.count != project.tasks.count {
            DispatchQueue.main.async {
                self.selectedTaskIndex = -1
            }
        }

        projects = projects.map { p in
            if p.id == project.id {
                return project
            }
            return p
        }

        if let img = CLTaskManager.shared.projectAvatar(projectID: editingProject.id, isEditing: true) {
            CLTaskManager.shared.updateProjectAvatar(image: img)
            CLTaskManager.shared.removeProjectAvatar(projectID: editingProject.id, isEditing: true)
        }
        NotificationCenter.default.post(name: .updateProjectAvatar, object: nil)

        let projectsToSave = projects
        Task.detached {
            await self.store.saveProjects(projectsToSave)
        }
    }

    private func _detectExistingTasks() {
        debugPrint("detecting tasks...")
        let taskPath = CLTaskManager.shared.taskPath()
        let decoder = JSONDecoder()
        do {
            let data = try Data(contentsOf: taskPath)
            let taskPIDs: [CLTaskPID] = try decoder.decode([CLTaskPID].self, from: data)
            for taskPID in taskPIDs {
                let cmd = CLCommand(executable: URL(fileURLWithPath: "/bin/kill"), directory: URL(fileURLWithPath: ""), arguments: ["-9", "\(taskPID.identifier)"])
                runAsyncCommand(command: cmd) { _, _, _ in
                }
            }
        } catch {
            debugPrint("failed to load task pids: \(error)")
        }
    }

    private func _updateExistingTasks() {
        let taskPath = CLTaskManager.shared.taskPath()
        var taskPIDs: [CLTaskPID] = []
        for uuid in taskProcesses.keys {
            guard let p = taskProcesses[uuid], let id = UUID(uuidString: uuid) else { continue }
            taskPIDs.append(CLTaskPID(id: id, identifier: p.processIdentifier))
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .withoutEscapingSlashes
        do {
            let data = try encoder.encode(taskPIDs)
            try data.write(to: taskPath, options: .atomic)
        } catch {
            debugPrint("failed to update task pids: \(error)")
        }
    }
}
