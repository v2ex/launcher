//
//  CLSettingsGeneralView.swift
//  CodeLauncher
//
//  Created by Kai on 11/24/21.
//

import SwiftUI

enum Appearance: String, Codable, CaseIterable, Identifiable {
    case dark
    case light
    case device
    case reverse

    var id: String { self.rawValue }
}

struct CLSettingsGeneralView: View {
    @AppStorage(String.settingsUseNotificationForTaskStatusKey) var useNotification: Bool = UserDefaults.standard.bool(forKey: String.settingsUseNotificationForTaskStatusKey)
    @AppStorage(String.settingsLaunchOptionKey) var launchOption: Bool = UserDefaults.standard.bool(forKey: String.settingsLaunchOptionKey)
    @AppStorage(String.settingsAutoRestartFailedTaskKey) var autoRestartTask: Bool = UserDefaults.standard.bool(forKey: String.settingsAutoRestartFailedTaskKey)
    @AppStorage(String.settingsAppearanceKey) var selectedAppearance: Appearance = .dark

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Picker("Output Appearance", selection: $selectedAppearance) {
                    Text("Dark theme").tag(Appearance.dark)
                    Text("Light theme").tag(Appearance.light)
                    Text("Use device theme").tag(Appearance.device)
                    Text("Use device theme (reverse)").tag(Appearance.reverse)
                }
            }

            HStack {
                Text("Launch Option")
                Spacer()
                Toggle("Launch at startup", isOn: $launchOption)
                    .help("Launch CodeLauncher automatically when you start up your Mac.")
                    .onChange(of: launchOption) { _ in
                        CLTaskManager.shared.updateLaunchOption()
                    }
            }

            HStack {
                VStack {
                    Text("Task Option")
                    Spacer()
                }
                Spacer()
                VStack {
                    HStack {
                        Spacer()
                        Toggle("Use Notification", isOn: $useNotification)
                            .help("Use system notification for task status.")
                    }
                    HStack {
                        Spacer()
                        Toggle("Auto Restart Failed Tasks", isOn: $autoRestartTask)
                            .help("Auto restart a failed task for a limited times.")
                    }
                    Spacer()
                }
            }

            Spacer()
        }
        .padding()
    }
}

struct CLSettingsGeneralView_Previews: PreviewProvider {
    static var previews: some View {
        CLSettingsGeneralView()
    }
}
