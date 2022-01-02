//
//  CLProject.swift
//  Code Launcher
//
//  Created by Kai on 11/24/21.
//

import Foundation
import SwiftUI

struct CLProject: Codable, Hashable, Identifiable {
    let id: UUID
    let created: Date
    var name: String
    var description: String
    var tasks: [CLTask]
    var autoStart: Bool

    func generateAvatarName() -> String {
        if name.contains(" ") {
            let initials: [String] = name.components(separatedBy: " ").map { n in
                n.prefix(1).capitalized
            }
            return String(initials.joined(separator: "").prefix(2))
        } else {
            return name.prefix(1).capitalized
        }
    }

    var gradients: [Gradient] {
        [
            Gradient(colors: [Color(hex: 0x88D3FA), Color(hex: 0x4C9FED)]), // Sky Blue
            Gradient(colors: [Color(hex: 0xFACE76), Color(hex: 0xF5AD67)]), // Orange
            Gradient(colors: [Color(hex: 0xD8A9F0), Color(hex: 0xCA77E9)]), // Pink
            Gradient(colors: [Color(hex: 0xF39066), Color(hex: 0xF0636E)]), // Red
            Gradient(colors: [Color(hex: 0xACDB86), Color(hex: 0x74C771)]), // Green
            Gradient(colors: [Color(hex: 0x8AB2FB), Color(hex: 0x6469FA)]), // Violet
            Gradient(colors: [Color(hex: 0x7FE9D7), Color(hex: 0x5DC6B8)]), // Cyan
        ]
    }

    func gradient() -> Gradient {
        let gs = gradients
        let parts = id.integers
        let a: Int64 = abs(parts.0)
        // let b: Int64 = abs(parts.1)
        let c = Int((a % Int64(31)) % Int64(gs.count))
        debugPrint("a: \(a) count: \(gs.count) c: \(c)")
        let g = gs[c]
        return g
    }
}
