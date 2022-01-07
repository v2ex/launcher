//
//  CLTaskStatusIndicatorView.swift
//  CodeLauncher
//
//  Created by Kai Luo on 1/7/22.
//

import SwiftUI


struct CLTaskStatusIndicatorView: View {
    var status: CLTaskStatus = CLTaskStatus.stopped

    var body: some View {
        VStack {
            switch status {
                case .running:
                    Circle()
                .frame(width: 11, height: 11, alignment: .center)
                .foregroundColor(Color.green)
                case .failed:
                    Circle()
                .frame(width: 11, height: 11, alignment: .center)
                .foregroundColor(Color.red)
                case .stopped:
                    Circle()
                .frame(width: 11, height: 11, alignment: .center)
                .foregroundColor(Color.gray)
            }
        }
    }
}


struct CLTaskStatusIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CLTaskStatusIndicatorView()
            CLTaskStatusIndicatorView(status: .running)
            CLTaskStatusIndicatorView(status: .failed)
        }
    }
}
