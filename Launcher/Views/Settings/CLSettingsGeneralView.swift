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
    case dracula
    case device
    case reverse

    var id: String { self.rawValue }
}

struct CLSettingsGeneralView: View {
    @AppStorage(CLDefaults.settingsUseNotificationForTaskStatusKey) var useNotification =
    CLDefaults.default.settingsUseNotificationForTaskStatus

    @AppStorage(CLDefaults.settingsLaunchOptionKey) var launchOption =
    CLDefaults.default.settingsLaunchOption

    @AppStorage(CLDefaults.settingsMenuBarModeKey) var menuBarMode =
    CLDefaults.default.settingsMenuBarMode

    @AppStorage(CLDefaults.settingsShowMenuBarIconKey) var showMenuBarIcon =
    CLDefaults.default.settingsShowMenuBarIcon

    @AppStorage(CLDefaults.settingsAutoRestartFailedTaskKey) var autoRestartTask =
    CLDefaults.default.settingsAutoRestartFailedTask

    @AppStorage(CLDefaults.settingsAppearanceKey) var selectedAppearance: Appearance = .dark

    var body: some View {
        VStack(spacing: 20) {
            GroupBox {
                HStack {
                    Text("Output Appearance")
                        .font(.body)
                    Spacer()
                    Picker("", selection: $selectedAppearance) {
                        Text("Dark theme").tag(Appearance.dark)
                        Text("Light theme").tag(Appearance.light)
                        Text("Dracula theme").tag(Appearance.dracula)
                        Text("Use device theme").tag(Appearance.device)
                        Text("Use device theme (reverse)").tag(Appearance.reverse)
                    }
                    .frame(width: 200)
                }
                .padding(.horizontal, 6)
            } label: {
                Label("Appearance Options", systemImage: "note.text")
                    .font(.body)
                    .padding(.top, 12)
                    .padding(.bottom, 6)
            }

            GroupBox {
                HStack {
                    Spacer()
                    Toggle("Launch at startup", isOn: $launchOption)
                        .help("Launch CodeLauncher automatically when you start up your Mac.")
                        .onChange(of: launchOption) { _ in
                            CLTaskManager.shared.updateLaunchOption()
                        }
                }
                .padding(.horizontal, 6)

                HStack {
                    Spacer()
                    Toggle("Show menu bar icon", isOn: $showMenuBarIcon)
                        .help("Show CodeLauncher icon in menu bar.")
                        .onChange(of: showMenuBarIcon) { newValue in
                            updateMenuBarIconAction(status: newValue)
                        }
                        .disabled(menuBarMode)
                }
                .padding(.horizontal, 6)

                HStack {
                    Spacer()
                    Toggle("Run in menu bar only", isOn: $menuBarMode)
                        .help("Run CodeLauncher in menu bar only.")
                        .onChange(of: menuBarMode) { newValue in
                            if newValue {
                                if showMenuBarIcon == false {
                                    showMenuBarIcon = true
                                }
                            }
                            updateMenuBarModeAction()
                        }
                }
                .padding(.horizontal, 6)
            } label: {
                Label("Launch Options", systemImage: "gearshape.2")
                    .font(.body)
                    .padding(.bottom, 6)
            }

            GroupBox {
                HStack {
                    Spacer()
                    Toggle("Use Notification", isOn: $useNotification)
                        .help("Use system notification for task status.")
                }
                .padding(.horizontal, 6)

                HStack {
                    Spacer()
                    Toggle("Auto Restart Failed Tasks", isOn: $autoRestartTask)
                        .help("Auto restart a failed task for a limited times.")
                }
                .padding(.horizontal, 6)
            } label: {
                Label("Task Options", systemImage: "memorychip")
                    .font(.body)
                    .padding(.bottom, 6)
            }

            Spacer()
        }
        .padding()
    }

    private func updateMenuBarIconAction(status: Bool) {
        if status {
            CLStore.shared.appDelegate.createMenulet()
        } else {
            CLStore.shared.appDelegate.removeMenulet()
        }
    }

    private func updateMenuBarModeAction() {
        CLStore.shared.appDelegate.updateMenuletActivationPolicy()
    }
}

struct CLSettingsGeneralView_Previews: PreviewProvider {
    static var previews: some View {
        CLSettingsGeneralView()
            .frame(width: 400, height: 320)
    }
}
