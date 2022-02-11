//
//  CLTask.swift
//  launcher
//
//  Created by Kai on 11/18/21.
//

import Foundation

enum CLTaskStatus {
    case running
    case failed
    case stopped
}

struct CLTask: Codable, Hashable, Identifiable {
    let id: UUID
    let projectID: UUID
    let created: Date
    var executable: String
    var directory: String
    var arguments: String
    var environments: String
    var delay: Double
    var autoStart: Bool
    var lastExitCode: Int32? = 0

    init(id: UUID, projectID: UUID, created: Date, executable: String, directory: String, arguments: String, environments: String = "", delay: Double, autoStart: Bool = false) {
        self.id = id
        self.projectID = projectID
        self.created = created
        self.executable = executable
        self.directory = directory
        self.arguments = arguments
        self.environments = environments
        self.delay = delay
        self.autoStart = autoStart
        self.lastExitCode = 0
    }

    var hasServicePort: Bool {
        if arguments.contains("port") {
            return true
        } else {
            return false
        }
    }

    var isRunning: Bool {
        if CLStore.shared.taskProcesses[id.uuidString] == nil {
            return false
        }
        return true
    }

    var status: CLTaskStatus {
        if self.isRunning {
            return .running
        } else if self.lastExitCode != 0 {
            return .failed
        } else {
            return .stopped
        }
    }

    var servicePort: Int {
        let args = arguments
        let argsRange = NSRange(
            args.startIndex ..< args.endIndex,
            in: args
        )

        let capturePattern = #"port[\s=]([0-9]+)"#
        let captureRegex = try! NSRegularExpression(
            pattern: capturePattern,
            options: []
        )

        let matches = captureRegex.matches(
            in: args,
            options: [],
            range: argsRange
        )

        guard let match = matches.first else {
            return 0
        }

        let matchRange = match.range(at: match.numberOfRanges - 1)

        // Extract the substring matching the capture group
        if let substringRange = Range(matchRange, in: args) {
            let capture = String(args[substringRange])
            return Int(capture)!
        }

        return 0
    }

    func launchTask(complete: @escaping (Process?, Bool, String?) -> Void) {
        let taskValidation = taskValidated()
        debugPrint("task validation: \(taskValidation), path: \(CLStore.shared.envPATH)")
        guard taskValidation.valid, let url = taskValidation.executableURL, let dir = taskValidation.directoryURL else {
            debugPrint("Invalid task: \(self)")
            return complete(nil, false, "Invalid task, abort.")
        }
        let cmd = CLCommand(executable: url, directory: dir, arguments: arguments.stringToArguments(), environments: environments.processedEnvironments(), delay: delay)
        runAsyncCommand(command: cmd) { process, completed, output in
            complete(process, completed, output)
        }
    }

    func taskValidated() -> (valid: Bool, executableURL: URL?, directoryURL: URL?) {
        var valid = true
        var alternativeExecutableURL: URL?
        var alternativeDirectoryURL: URL?

        if !executable.starts(with: "/") {
            for p in CLStore.shared.envPATH.components(separatedBy: ":") {
                let anExecutablePath = p + "/" + executable
                if FileManager.default.fileExists(atPath: anExecutablePath), FileManager.default.isExecutableFile(atPath: anExecutablePath) {
                    alternativeExecutableURL = URL(fileURLWithPath: anExecutablePath)
                    break
                }
            }
            if alternativeExecutableURL == nil {
                return (false, nil, nil)
            }
        } else {
            // validate executable as full path.
            let executableURL = URL(fileURLWithPath: executable)
            if executableURL.lastPathComponent == "" {
                valid = false
            }
            if executableURL.hasDirectoryPath {
                valid = false
            }
            if !executableURL.isFileURL {
                valid = false
            }
            if !FileManager.default.isExecutableFile(atPath: executableURL.path) {
                valid = false
            }
            if valid {
                alternativeExecutableURL = executableURL
            }
        }

        // validate directory
        let directoryURL = URL(fileURLWithPath: directory)
        alternativeDirectoryURL = directoryURL

        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            valid = false
            alternativeDirectoryURL = CLTaskManager.shared.currentUserHomePath()
        }
        if !directoryURL.isFileURL {
            valid = false
            alternativeDirectoryURL = CLTaskManager.shared.currentUserHomePath()
        }

        return (valid, alternativeExecutableURL, alternativeDirectoryURL)
    }
}

struct CLTaskPID: Codable {
    let id: UUID
    let identifier: Int32
}

struct CLTaskOutput: Hashable {
    let id: UUID
    let taskID: UUID
    let projectID: UUID
    let content: String
}


extension CLTask {
    static var placeholder: Self {
        CLTask(id: UUID(), projectID: UUID(), created: Date(), executable: "", directory: "", arguments: "", environments: "", delay: 0, autoStart: false)
    }
}
