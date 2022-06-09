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
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var store = CLStore.shared

    var body: some Scene {
        WindowGroup {
            CLMainView()
                .environmentObject(store)
                .frame(minWidth: 700, minHeight: 320)
        }
        .handlesExternalEvents(matching: Set(arrayLiteral: "*"))
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

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    
    private lazy var statusItem: NSStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
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
        // Stats Bar Menu
        createMenu()
    }

    func applicationWillTerminate(_: Notification) {}

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        NSApp.setActivationPolicy(.accessory)
        return false
    }

    func applicationShouldTerminate(_: NSApplication) -> NSApplication.TerminateReply {
        CLTaskManager.shared.cleanup()

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            NSApplication.shared.reply(toApplicationShouldTerminate: true)
        }

        return .terminateLater
    }

    func userNotificationCenter(_: UNUserNotificationCenter, willPresent _: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner])
    }

    func userNotificationCenter(_: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == String.taskCompleteActionRepeatIdentifier, let uuid = UUID(uuidString: response.notification.request.identifier) {
            CLTaskManager.shared.restartTask(byTaskUUID: uuid)
        }
        completionHandler()
    }
    
    func createMenu() {
        
        if let button = self.statusItem.button {
            let image = NSImage(named: "rocket")
            image?.isTemplate = true
            button.image = image
        }
       
        let menu = NSMenu()
        
        let showMenuItem = NSMenuItem(title: "Show", action: #selector(showMainWindowAction), keyEquivalent: "o")
        menu.addItem(showMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitMenuItem = NSMenuItem(title: "Quit", action: #selector(quitAction), keyEquivalent: "q")
        menu.addItem(quitMenuItem)
        
        self.statusItem.menu = menu
        
        NSApp.setActivationPolicy(.regular)
    }
    
    @objc
    private func showMainWindowAction() {
        NSApp.setActivationPolicy(.regular)
        if let url = URL(string: "CodeLauncher://*") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc
    private func quitAction() {
        NSApp.terminate(self)
    }
}
