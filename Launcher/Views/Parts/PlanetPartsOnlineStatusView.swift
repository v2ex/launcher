//
//  PlanetPartsOnlineStatusView.swift
//  Planet
//
//  Created by Kai on 11/18/21.
//

import SwiftUI

struct PlanetPartsOnlineStatusView: View {
    var isOnline: Bool = false

    var body: some View {
        VStack {
            Circle()
                .frame(width: 11, height: 11, alignment: .center)
                .foregroundColor(isOnline ? Color.green : Color.red)
        }
    }
}

struct PlanetPartsOnlineStatusView_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            Text("Daemon Status")
            PlanetPartsOnlineStatusView(isOnline: true)
            Spacer()
        }
        .frame(width: 200, height: 32, alignment: .center)
    }
}
