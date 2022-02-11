//
//  CLSettingsAdvancedView.swift
//  CodeLauncher
//
//  Created by Kai on 12/3/21.
//

import SwiftUI

struct CLSettingsAdvancedView: View {
    @EnvironmentObject private var store: CLStore

    @State private var isResettingDatabase: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack {
                    Text("Database Option")
                    Spacer()
                }
                
                Spacer()
                
                VStack {
                    Button {
                        isResettingDatabase = true
                    } label: {
                        Text("Reset Database")
                    }

                    Spacer()
                }
            }
            Spacer()
        }
        .padding()
        .alert(isPresented: $isResettingDatabase, content: {
            Alert(title: Text("Reset Database"), message: Text("All projects will be erased, this can not be undo."), primaryButton: Alert.Button.destructive(Text("Reset"), action: {
                CLTaskManager.shared.resetDatabase()
            }), secondaryButton: Alert.Button.cancel(Text("Cancel")))
        })
    }
}

struct CLSettingsAdvancedView_Previews: PreviewProvider {
    static var previews: some View {
        CLSettingsAdvancedView()
    }
}
