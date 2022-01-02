//
//  CLContentView.swift
//  launcher
//
//  Created by Kai on 11/18/21.
//

import CoreFoundation
import CoreGraphics
import SwiftUI

private let handlerHeight: CGFloat = 5
private let consoleMinGapHeight: CGFloat = 24
private let consoleMinHeight: CGFloat = 44

private struct CLContentHandlerView: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            HStack {
                Spacer()
                Text(" ")
                Spacer()
            }
            Spacer()
        }
        .frame(height: handlerHeight)
        .contentShape(Rectangle())
        .background(Color("ConsoleOutputsForeground"))
    }
}

struct CLContentView: View {
    @EnvironmentObject private var store: CLStore

    var body: some View {
        VStack(spacing: 0) {
            if let p: CLProject = store.loadProject(byID: store.currentProjectID) {
                GeometryReader { g in
                    VStack(spacing: 0) {
                        ScrollView {
                            LazyVStack {
                                ForEach(p.tasks, id: \.id) { task in
                                    CLTaskItemView(task: task)
                                        .environmentObject(store)
                                        .onTapGesture {
                                            store.currentViewingTaskID = task.id
                                        }
                                }
                            }
                            .padding(10)
                        }
                        .frame(height: store.outputTaskViewHeight)

                        CLContentHandlerView()
                            .onHover { inside in
                                inside ? NSCursor.openHand.push() : NSCursor.pop()
                            }
                            .simultaneousGesture(
                                DragGesture()
                                    .onChanged { value in
                                        updateTaskViewHeight(withValue: value, andTotalHeight: g.size.height)
                                    }
                                    .onEnded { value in
                                        updateTaskViewHeight(withValue: value, andTotalHeight: g.size.height, ended: true)
                                    }
                            )

                        CLConsoleView(project: p)
                            .frame(minHeight: consoleMinHeight)
                            .environmentObject(store)
                    }
                    .frame(height: g.size.height)
                }
            } else {
                Text("No projects yet, create or select one.")
                    .font(.system(size: 12, weight: .light, design: .default))
            }
        }
    }

    private func updateTaskViewHeight(withValue value: DragGesture.Value, andTotalHeight height: CGFloat, ended: Bool = false) {
        var updatedTaskViewHeight = max(84, store.outputTaskViewHeight + value.translation.height)
        let delta = height - updatedTaskViewHeight
        if delta < consoleMinHeight + handlerHeight {
            return
        }
        if delta < consoleMinHeight + handlerHeight + consoleMinGapHeight, ended {
            updatedTaskViewHeight = height - consoleMinHeight - handlerHeight
        }
        DispatchQueue.main.async {
            store.outputTaskViewHeight = updatedTaskViewHeight
        }
        if ended {
            DispatchQueue.global(qos: .background).async {
                UserDefaults.standard.set(updatedTaskViewHeight, forKey: store.currentProjectID.uuidString + "-" + String.lastActiveConsoleTaskViewHeightKey)
            }
        }
    }
}

struct CLContentView_Previews: PreviewProvider {
    static var previews: some View {
        CLContentView()
    }
}
