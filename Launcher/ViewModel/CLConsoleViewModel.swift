//
//  CLConsoleViewModel.swift
//  CodeLauncher
//
//  Created by Kai on 4/19/22.
//

import Foundation
import SwiftUI


class CLConsoleViewModel: ObservableObject {
    static let shared = CLConsoleViewModel()
    @Published var projectOutputs: [CLTaskOutput] = [] {
        didSet {
            guard let last = projectOutputs.last, last.projectID == CLStore.shared.currentProjectID else { return }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .scrollDownToLatestConsoleOutput, object: last)
            }
        }
    }
}
