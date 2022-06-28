//
//  launcherApp.swift
//  launcher
//
//  Created by Kai on 11/18/21.
//

import Sparkle
import SwiftUI
import UserNotifications

@main
struct CLApp: App {
    @StateObject var store = CLStore.shared

    var body: some Scene {
        WindowGroup {
            CLMainView()
                .environmentObject(store)
                .frame(minWidth: 700, minHeight: 320)
                .handlesExternalEvents(preferring: Set(arrayLiteral: String.mainWindowScheme), allowing: Set(arrayLiteral: String.mainWindowScheme))
                .onOpenURL { u in
                    if NSApp.activationPolicy() == .regular && CLDefaults.default.settingsMenuBarMode {
                        NSApp.setActivationPolicy(.accessory)
                        NSApplication.shared.activate(ignoringOtherApps: true)
                    }
                }
        }
        .handlesExternalEvents(matching: Set(arrayLiteral: String.mainWindowScheme))
        .commands {
            CommandGroup(replacing: .newItem) {
                Button {
                    CLTaskManager.shared.addNewProject()
                } label: {
                    Text("New Project")
                }
                .keyboardShortcut("n", modifiers: .command)
                .disabled(store.isEditingProject)

                Button {
                    CLTaskManager.shared.editProject()
                } label: {
                    Text("Edit Project")
                }
                .keyboardShortcut("e", modifiers: .command)
                .disabled(store.isEditingProject || store.loadProject(byID: store.currentProjectID) == nil)

                Divider()

                Button {
                    DispatchQueue.main.async {
                        CLStore.shared.isImportingProject = true
                    }
                } label: {
                    Text("Import Project")
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
                .disabled(store.isEditingProject)

                Button {
                    CLTaskManager.shared.exportProject(project: store.loadProject(byID: store.currentProjectID)!)
                } label: {
                    Text("Export Project")
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
                .disabled(store.isEditingProject || store.loadProject(byID: store.currentProjectID) == nil)

                Divider()

                Button {
                    store.isDeletingProject = true
                } label: {
                    Text("Delete Project")
                }
                .keyboardShortcut(.delete, modifiers: .command)
                .disabled(store.isEditingProject || store.loadProject(byID: store.currentProjectID) == nil)
            }
            CommandGroup(after: .appInfo) {
                Button {
                    SUUpdater.shared().checkForUpdates(NSButton())
                } label: {
                    Text("Check for Updates")
                }
                .keyboardShortcut("u", modifiers: .command)
            }
            CommandGroup(replacing: CommandGroupPlacement.systemServices) {}
            SidebarCommands()
        }

        Settings {
            CLSettingsView()
                .environmentObject(store)
        }
    }
}


class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    @Environment(\.openURL) private var openURL

    private var menuletItem: NSStatusItem?

    func applicationWillFinishLaunching(_: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
        UserDefaults.standard.set(false, forKey: "NSFullScreenMenuItemEverywhere")
    }

    func applicationDidFinishLaunching(_: Notification) {
        CLTaskManager.shared.setup()
        SUUpdater.shared().checkForUpdatesInBackground()

        UNUserNotificationCenter.current().delegate = self
        let dismissAction = UNNotificationAction(identifier: String.taskCompleteActionDismissIdentifier, title: "Dismiss", options: [.destructive])
        let repeatAction = UNNotificationAction(identifier: String.taskCompleteActionRepeatIdentifier, title: "Repeat", options: [.destructive])
        let category = UNNotificationCategory(identifier: String.taskCompleteIdentifier, actions: [dismissAction, repeatAction], intentIdentifiers: [], hiddenPreviewsBodyPlaceholder: "", options: .customDismissAction)
        UNUserNotificationCenter.current().setNotificationCategories([category])

        createMenulet()
    }

    func applicationWillTerminate(_: Notification) {}

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        return false
    }

    func applicationShouldTerminate(_: NSApplication) -> NSApplication.TerminateReply {
        CLTaskManager.shared.cleanup()

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            NSApplication.shared.reply(toApplicationShouldTerminate: true)
        }

        return .terminateLater
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        return true
    }

    // MARK: - Notification -
    func userNotificationCenter(_: UNUserNotificationCenter, willPresent _: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner])
    }

    func userNotificationCenter(_: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == String.taskCompleteActionRepeatIdentifier, let uuid = UUID(uuidString: response.notification.request.identifier) {
            CLTaskManager.shared.restartTask(byTaskUUID: uuid)
        }
        completionHandler()
        if NSApp.activationPolicy() == .accessory {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                self?.updateMenuletActivationPolicy()
            }
        }
    }

    // MARK: - Menulet -
    func createMenulet() {
        guard menuletItem == nil, CLDefaults.default.settingsShowMenuBarIcon else { return }
        menuletItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))

        let image = NSImage(named: "rocket")
        image?.isTemplate = true
        menuletItem?.button?.image = image

        let menu = NSMenu()

        let showMenuItem = NSMenuItem(title: "Open CodeLauncher", action: #selector(showMainWindowAction), keyEquivalent: "")
        menu.addItem(showMenuItem)

        let projectsMenuItem = NSMenuItem(title: "Projects", action: nil, keyEquivalent: "")
        menu.addItem(projectsMenuItem)

        let preferencesItem = NSMenuItem(title: "Preferences", action: #selector(preferencesAction), keyEquivalent: "")
        menu.addItem(preferencesItem)

        menu.addItem(NSMenuItem.separator())
        let quitMenuItem = NSMenuItem(title: "Quit", action: #selector(quitAction), keyEquivalent: "")
        menu.addItem(quitMenuItem)
        menu.delegate = self

        menuletItem?.menu = menu

        updateMenuletActivationPolicy()
    }

    func removeMenulet() {
        if let item = menuletItem {
            NSStatusBar.system.removeStatusItem(item)
        }
        menuletItem = nil
    }

    func updateMenuletActivationPolicy() {
        NSApp.setActivationPolicy(CLDefaults.default.settingsMenuBarMode ? .accessory : .regular)
    }

    @objc
    private func showMainWindowAction() {
        if let url = URL(string: "CodeLauncher://" + String.mainWindowScheme) {
            openURL(url)
        }
    }

    @objc
    private func preferencesAction() {
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        if !NSApplication.shared.isActive {
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }

    @objc
    private func quitAction() {
        NSApp.terminate(self)
    }
}


extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        let projects = CLStore.shared.projects
        let projectMenuItem = menu.item(withTitle: "Projects")
        if projects.count > 0 {
            let projectMenu = NSMenu()
            for p in projects {
                let projectIsRunning = CLStore.shared.activeProjects.filter { projectID in
                    projectID == p.id.uuidString
                }.count > 0
                let item = NSMenuItem()
                item.title = p.name
                let itemSubmenu = NSMenu()
                let subItem = NSMenuItem()
                subItem.title = projectIsRunning ? "Stop Project" : "Start Project"
                subItem.target = self
                subItem.representedObject = p
                subItem.action = projectIsRunning ? #selector(stopProject(sender:)) : #selector(startProject(sender:))
                itemSubmenu.addItem(subItem)
                item.submenu = itemSubmenu
                projectMenu.addItem(item)
            }
            projectMenuItem?.submenu = projectMenu
        } else {
            projectMenuItem?.submenu?.removeAllItems()
        }
    }

    @objc
    private func startProject(sender: NSMenuItem) {
        guard let project = sender.representedObject as? CLProject else { return }
        CLTaskManager.shared.startTasks(fromProject: project)
    }

    @objc
    private func stopProject(sender: NSMenuItem) {
        guard let project = sender.representedObject as? CLProject else { return }
        CLTaskManager.shared.stopTasks(fromProject: project)
    }
}
