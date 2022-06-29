//
//  CLDefaults.swift
//  CodeLauncher
//
//  Created by Lex on 2022/1/23.
//

import Foundation

struct CLDefaults {

    static let settingsLaunchOptionKey = "CLUserDefaultsLaunchOptionKey"
    @CLUserDefault(key: settingsLaunchOptionKey, defaultValue: false)
    var settingsLaunchOption

    static let settingsMenuBarModeKey = "CLUserDefaultsMenuBarModeKey"
    @CLUserDefault(key: settingsMenuBarModeKey, defaultValue: false)
    var settingsMenuBarMode

    static let settingsShowMenuBarIconKey = "CLUserDefaultsShowMenuBarIconKey"
    @CLUserDefault(key: settingsShowMenuBarIconKey, defaultValue: true)
    var settingsShowMenuBarIcon

    static let settingsUseNotificationForTaskStatusKey = "CLUserDefaultsUseNotificationForTaskStatusKey"
    @CLUserDefault(key: settingsUseNotificationForTaskStatusKey, defaultValue: true)
    var settingsUseNotificationForTaskStatus

    static let settingsAutoRestartFailedTaskKey = "CLUserDefaultsAutoRestartFailedTaskKey"
    @CLUserDefault(key: settingsAutoRestartFailedTaskKey, defaultValue: true)
    var settingsAutoRestartFailedTask

    static let settingsAppearanceKey = "CLUserDefaultsAppearanceKey"
    @CLUserDefault(key: settingsAppearanceKey, defaultValue: Appearance.dark)
    var settingsAppearance

    @CLUserDefault(key: "CLUserDefaultsLastActiveProjectUUIDKey")
    var lastActiveProjectUUID: String?

    @CLUserDefault(key: "CLUserDefaultsLastSelectedTaskIndexKey")
    var lastSelectedTaskIndex: Int?

    @CLUserDefault(key: "CLUserDefaultsLastSelectedProjectConsoleStatusKey", defaultValue: false)
    var lastSelectedProjectConsoleStatus

    @CLUserDefault(key: "CLUserDefaultsLastActiveConsoleTaskViewHeightKey", defaultValue: CGFloat(80))
    var lastActiveConsoleTaskViewHeight

    // MARK: -

    fileprivate static var currentProjectID: UUID?
    private static var shared = CLDefaults()

    static var `default`: MutableReference<CLDefaults> {
        currentProjectID = nil
        return MutableReference(value: shared)
    }

    static subscript(projectID: UUID? = nil) -> MutableReference<CLDefaults> {
        currentProjectID = projectID

        return MutableReference(value: shared)
    }

}

@propertyWrapper
struct CLUserDefault<Value: Codable> {

    let key: String
    var defaultValue: Value
    var container = UserDefaults.standard

    var wrappedValue: Value {
        get { getter() }
        set { setter(newValue) }
    }

    private func getter() -> Value {
        let getterKey: String
        if let projectKey = CLDefaults.currentProjectID {
            getterKey = "\(projectKey.uuidString)-\(key)"
        } else {
            getterKey = key
        }

        if
            let data = container.data(forKey: getterKey),
            let array = try? JSONDecoder().decode(Value.self, from: data)
        {
            return array
        }

        return container.object(forKey: getterKey) as? Value ?? defaultValue
    }

    func anyRaw(_ value: Any) -> Codable? {
        if let any = value as? String {
            return any
        } else if let any = value as? Bool {
            return any
        } else if let any = value as? Int {
            return any
        } else if let any = value as? Double {
            return any
        } else if let any = value as? CGFloat {
            return any
        }
        return nil
    }

    private func setter(_ newValue: Value) {
        let setterKey: String
        if let projectKey = CLDefaults.currentProjectID {
            setterKey = "\(projectKey.uuidString)-\(key)"
        } else {
            setterKey = key
        }

        if let optional = newValue as? AnyOptional, optional.isNil {
            container.removeObject(forKey: setterKey)
        } else {
            if let raw = anyRaw(newValue) {
                container.set(raw, forKey: setterKey)
            } else {
                if let data = try? JSONEncoder().encode(newValue) {
                    container.set(data, forKey: setterKey)
                }
            }
        }
    }

}

@dynamicMemberLookup
class Reference<Value> {
    fileprivate(set) var value: Value

    init(value: Value) {
        self.value = value
    }

    subscript<T>(dynamicMember keyPath: KeyPath<Value, T>) -> T {
        value[keyPath: keyPath]
    }
}

class MutableReference<Value>: Reference<Value> {
    subscript<T>(dynamicMember keyPath: WritableKeyPath<Value, T>) -> T {
        get { value[keyPath: keyPath] }
        set { value[keyPath: keyPath] = newValue }
    }
}

private protocol AnyOptional {
    var isNil: Bool { get }
}

extension Optional: AnyOptional {
    fileprivate var isNil: Bool { self == nil }
}

extension CLUserDefault where Value: ExpressibleByNilLiteral {
    init(key: String) {
        self.init(key: key, defaultValue: nil)
    }
}
