//
//  CLCommand.swift
//  Code Launcher
//
//  Created by Kai on 11/20/21.
//

import Dispatch
import Foundation

/**
 *  Run commands async
 *
 *  - parameter command: The command with launch path, config path and arguments
 *  - parameter process: The process to use to perform the command. default: New one every command
 *  - returns: complete block with task status, optional output (standard output + error output)
 *
 */
func runAsyncCommand(command: CLCommand, process: Process = .init(), complete: @escaping (Process, Bool, String?) -> Void) {
    debugPrint("running async command: \(command)")

    let argus: [String] = command.arguments.map { s in
        s.processedCommandArgument()
    }

    if command.delay > 0 {
        DispatchQueue.main.asyncAfter(deadline: .now() + command.delay) {
            DispatchQueue.global(qos: .utility).async {
                process.launchAsyncCommand(executable: command.executable, directory: command.directory, argus: argus, envs: command.environments) { currentProcess, processCompleted, output in
                    complete(currentProcess, processCompleted, output)
                }
            }
        }
    } else {
        DispatchQueue.global(qos: .utility).async {
            process.launchAsyncCommand(executable: command.executable, directory: command.directory, argus: argus, envs: command.environments) { currentProcess, processCompleted, output in
                complete(currentProcess, processCompleted, output)
            }
        }
    }
}

// MARK: - CLCommand

struct CLCommand {
    let executable: URL
    let directory: URL
    let arguments: [String]
    let environments: [String: String]
    let delay: Double

    init(executable: URL, directory: URL, arguments: [String], environments: [String: String] = [:], delay: Double = 0) {
        self.executable = executable
        self.directory = directory
        self.arguments = arguments
        self.environments = environments
        self.delay = delay
    }
}

private extension Process {
    func launchAsyncCommand(executable: URL, directory: URL, argus: [String] = [], envs: [String: String] = [:], complete: @escaping (Process, Bool, String?) -> Void) {
        executableURL = executable
        currentDirectoryURL = directory
        arguments = argus

        var theEnvironment = ProcessInfo.processInfo.environment
        if envs != [:] {
            for envKey in envs.keys {
                theEnvironment[envKey] = envs[envKey]
            }
        }

        if CLStore.shared.envPATH != "" {
            theEnvironment["PATH"] = CLStore.shared.envPATH
        }

        environment = theEnvironment

        debugPrint("launching async command at executable: \(executableURL), directory: \(currentDirectoryURL), arguments: \(arguments), environment: \(environment).")

        let processQueue = DispatchQueue(label: "com.v2ex.codelauncher.async-command-output-queue")

        var outputData = Data()
        var errorData = Data()

        let outputPipe = Pipe()
        standardOutput = outputPipe

        let errorPipe = Pipe()
        standardError = errorPipe

        outputPipe.fileHandleForReading.readabilityHandler = { handler in
            let data = handler.availableData
            processQueue.async {
                outputData.append(data)
                complete(self, false, data.stringOutput())
            }
        }

        errorPipe.fileHandleForReading.readabilityHandler = { handler in
            let data = handler.availableData
            processQueue.async {
                errorData.append(data)
                complete(self, false, data.stringOutput())
            }
        }

        launch()

        waitUntilExit()

        outputPipe.fileHandleForReading.readabilityHandler = nil
        errorPipe.fileHandleForReading.readabilityHandler = nil

        if outputData.stringOutput() != "" {
            complete(self, true, outputData.stringOutput())
        } else if errorData.stringOutput() != "" {
            complete(self, true, errorData.stringOutput())
        } else {
            complete(self, true, "")
        }
    }
}

private extension String {
    func processedMultilineCommandOutput() -> String {
        var s = self

        if let o = s.removingPercentEncoding {
            s = o
        }

        s = s.replacingOccurrences(of: "\t", with: " ")
        s = s.replacingOccurrences(of: "\\", with: "")
        s = s.replacingOccurrences(of: "\\n", with: "\n")

        return s
    }

    func processedCommandArgument() -> String {
        var s = self
        if s.hasPrefix(" ") {
            s.removeFirst()
        }
        if s.hasSuffix(" ") {
            s.removeLast()
        }
        return s
    }
}

private extension Data {
    func stringOutput() -> String? {
        guard let output = String(data: self, encoding: .utf8) else {
            return nil
        }

        guard !output.hasSuffix("\n") else {
            let endIndex = output.index(before: output.endIndex)
            let o = String(output[..<endIndex])
            return o == "" ? nil : o.processedMultilineCommandOutput()
        }

        return output.processedMultilineCommandOutput()
    }
}
