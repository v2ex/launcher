//
//  CLSettingsView.swift
//  Code Launcher
//
//  Created by Kai on 11/24/21.
//

import SwiftUI

struct CLSettingsView: View {
    @EnvironmentObject private var store: CLStore

    var body: some View {
        TabView {
            CLSettingsGeneralView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .tag(0)
                .frame(width: 360, height: 240)
                .environmentObject(store)

            CLSettingsAdvancedView()
                .tabItem {
                    Label("Advanced", systemImage: "cpu")
                }
                .tag(1)
                .frame(width: 360, height: 180)
                .environmentObject(store)
        }
    }
}

struct CLSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        CLSettingsView()
    }
}
