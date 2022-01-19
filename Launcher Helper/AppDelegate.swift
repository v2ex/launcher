//
//  AppDelegate.swift
//  CodeLauncher Helper
//
//  Created by Kai on 12/1/21.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    @objc private func terminate() {
        NSApp.terminate(nil)
    }

    func applicationDidFinishLaunching(_: Notification) {
        let mainAppIdentifier = CLConfiguration.bundlePrefix + ".CodeLauncher"
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = !runningApps.filter { $0.bundleIdentifier == mainAppIdentifier }.isEmpty

        if !isRunning {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(terminate), name: .killHelper, object: mainAppIdentifier)

            let path = Bundle.main.bundlePath as NSString
            var components = path.pathComponents
            components.removeLast()
            components.removeLast()
            components.removeLast()
            components.append("MacOS")
            components.append("CodeLauncher")

            let aPath = NSString.path(withComponents: components)
            NSWorkspace.shared.launchApplication(aPath)
        } else {
            terminate()
        }
    }

    func applicationWillTerminate(_: Notification) {}
}
