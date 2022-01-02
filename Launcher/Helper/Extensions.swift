//
//  Extensions.swift
//  Code Launcher
//
//  Created by Kai on 11/19/21.
//

import Cocoa
import Foundation
import SwiftUI

extension String {
    static let settingsLaunchOptionKey = "CLUserDefaultsLaunchOptionKey"
    static let settingsUseNotificationForTaskStatusKey = "CLUserDefaultsUseNotificationForTaskStatusKey"
    static let settingsAutoRestartFailedTaskKey = "CLUserDefaultsAutoRestartFailedTaskKey"

    static let lastActiveProjectUUIDKey = "CLUserDefaultsLastActiveProjectUUIDKey"
    static let lastSelectedTaskIndexKey = "CLUserDefaultsLastSelectedTaskIndexKey"
    static let lastSelectedProjectConsoleStatusKey = "CLUserDefaultsLastSelectedProjectConsoleStatusKey"
    static let lastActiveConsoleTaskViewHeightKey = "CLUserDefaultsLastActiveConsoleTaskViewHeightKey"

    static let killHelper = Notification.Name("CLKillCodeLauncherHelper")

    static let taskCompleteIdentifier: String = "codelauncher.v2ex.task.complete"
    static let taskCompleteActionDismissIdentifier: String = "codelauncher.v2ex.task.dismiss"
    static let taskCompleteActionRepeatIdentifier: String = "codelauncher.v2ex.task.repeat"

    func processedArguments() -> [String] {
        var output: [String] = []
        var s = self
        if s.hasPrefix(" ") {
            _ = s.removeFirst()
        }
        if s.hasSuffix(" ") {
            _ = s.removeLast()
        }
        if s.contains(",") {
            for o in s.components(separatedBy: ",") {
                if o.contains(" ") {
                    for so in o.components(separatedBy: " ") {
                        if !output.contains(so) {
                            output.append(so)
                        }
                    }
                } else if !output.contains(o) {
                    output.append(o)
                }
            }
        } else {
            for so in s.components(separatedBy: " ") {
                if !output.contains(so) {
                    output.append(so)
                }
            }
        }
        return output.filter { o in
            if o == "" {
                return false
            }
            return true
        }
    }

    func processedEnvironments() -> [String: String] {
        var outputEnvs: [String: String] = [:]
        var s = self
        // PORT =  3000 -> PORT=3000
        if let regex = try? NSRegularExpression(pattern: #"\s*=\s*"#, options: .caseInsensitive) {
            let range = NSRange(location: 0, length: s.count)
            s = regex.stringByReplacingMatches(in: s, options: [], range: range, withTemplate: "=")
        }
        // Multiple Lines
        let envs = s.split(whereSeparator: \.isNewline)
        for env in envs where env.contains("=") {
            let coms = env.components(separatedBy: "=")
            if let key: String = coms.first, let value: String = coms.last {
                outputEnvs[key] = value
            }
        }
        return outputEnvs
    }

    func processedEnvironmentsLabels() -> [String] {
        var s = self
        // PORT =  3000 -> PORT=3000
        if let regex = try? NSRegularExpression(pattern: #"\s*=\s*"#, options: .caseInsensitive) {
            let range = NSRange(location: 0, length: s.count)
            s = regex.stringByReplacingMatches(in: s, options: [], range: range, withTemplate: "=")
        }
        // Multiple Lines
        let envs = s.split(whereSeparator: \.isNewline)
        return envs.map { t in
            String(t)
        }
    }

    func processedTaskProperty() -> String {
        var s = self
        let secrectWords = ["secret", "password", "passcode"]
        if let label = s.components(separatedBy: "=").first, let property = s.components(separatedBy: "=").last {
            for w in secrectWords {
                if label.lowercased().hasPrefix(w) || label.lowercased().hasSuffix(w) {
                    s = label + "=" + String(repeating: "•", count: property.count)
                    break
                }
            }
        }
        return s
    }
}

extension NSNotification.Name {
    static let killHelper = Notification.Name("CLKillCodeLauncherHelper")
    static let scrollDownToLatestConsoleOutput = Notification.Name("CLScrollDownToLatestConsoleOutput")
    static let updateProjectAvatar = Notification.Name("CLUpdateProjectAvatar")
}

extension NSImage {
    func imageResize(_ newSize: NSSize) -> NSImage? {
        autoreleasepool {
            if let bitmapRep = NSBitmapImageRep(
                bitmapDataPlanes: nil, pixelsWide: Int(newSize.width), pixelsHigh: Int(newSize.height),
                bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
            ) {
                bitmapRep.size = newSize
                NSGraphicsContext.saveGraphicsState()
                NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
                draw(in: NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height), from: .zero, operation: .copy, fraction: 1.0)
                NSGraphicsContext.restoreGraphicsState()
                let resizedImage = NSImage(size: newSize)
                resizedImage.addRepresentation(bitmapRep)
                return resizedImage
            }
            return nil
        }
    }

    func imageSave(_ filepath: URL) {
        autoreleasepool {
            guard let imageData = self.tiffRepresentation else { return }
            let imageRep = NSBitmapImageRep(data: imageData)
            let data = imageRep?.representation(using: .png, properties: [:])
            do {
                try data?.write(to: filepath, options: .atomic)
            } catch {
                debugPrint("[Image Save Error] \(error)")
            }
        }
    }
}

extension UUID {
    // UUID is 128-bit, we need two 64-bit values to represent it
    var integers: (Int64, Int64) {
        var a: UInt64 = 0
        a |= UInt64(self.uuid.0)
        a |= UInt64(self.uuid.1) << 8
        a |= UInt64(self.uuid.2) << (8 * 2)
        a |= UInt64(self.uuid.3) << (8 * 3)
        a |= UInt64(self.uuid.4) << (8 * 4)
        a |= UInt64(self.uuid.5) << (8 * 5)
        a |= UInt64(self.uuid.6) << (8 * 6)
        a |= UInt64(self.uuid.7) << (8 * 7)

        var b: UInt64 = 0
        b |= UInt64(self.uuid.8)
        b |= UInt64(self.uuid.9) << 8
        b |= UInt64(self.uuid.10) << (8 * 2)
        b |= UInt64(self.uuid.11) << (8 * 3)
        b |= UInt64(self.uuid.12) << (8 * 4)
        b |= UInt64(self.uuid.13) << (8 * 5)
        b |= UInt64(self.uuid.14) << (8 * 6)
        b |= UInt64(self.uuid.15) << (8 * 7)

        return (Int64(bitPattern: a), Int64(bitPattern: b))
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 08) & 0xFF) / 255,
            blue: Double((hex >> 00) & 0xFF) / 255,
            opacity: alpha
        )
    }
}
