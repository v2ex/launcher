//
//  Updater.swift
//  CodeLauncher
//
//  Created by 王一丁 on 2022/9/1.
//

import Foundation
import SwiftUI
import Sparkle

class LauncherUpdater: NSObject, ObservableObject {
    static let shared = LauncherUpdater()

    @Published var canCheckForUpdates: Bool = false

    private let updater: SPUUpdater = {
        let mainAppBundle = Bundle.main
        let userDriver = SPUStandardUserDriver(hostBundle: Bundle.main, delegate: nil)
        let anUpdater = SPUUpdater(hostBundle: mainAppBundle, applicationBundle: mainAppBundle, userDriver: userDriver, delegate: nil)
        return anUpdater
    }()

    override init() {
        do {
            try updater.start()
            canCheckForUpdates = updater.canCheckForUpdates
        } catch {
            debugPrint("failed to start planet updater: \(error)")
        }
    }

    func checkForUpdates() {
        updater.checkForUpdates()
    }

    func checkForUpdatesInBackground() {
        updater.checkForUpdatesInBackground()
    }
}
