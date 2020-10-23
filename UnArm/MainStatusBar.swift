//
//  MainStatusBar.swift
//  UnArm
//
//  Created by Tamas Lustyik on 2020. 10. 10..
//

import SwiftUI

struct MainStatusBar: View {
    @ObservedObject var viewModel: AnyViewModel<MainViewState, MainViewInput>

    var body: some View {
        HStack {
            if viewModel.state.isProcessing {
                Text("Processing...")
                    .font(.system(size: 12.0, weight: .regular, design: .default))
                    .foregroundColor(Color(.secondaryLabelColor))
                    .frame(height: 24, alignment: .center)
                Spacer()
                ProgressView(isAnimating: Binding(get: { true }, set: { _ in }), style: .bar, controlSize: .small)
            }
            else {
                Color.clear
                    .frame(width: 20, height: 24)
                Spacer()

                Text(viewModel.state.statusText)
                    .font(.system(size: 12.0, weight: .regular, design: .default))
                    .foregroundColor(Color(.secondaryLabelColor))
                    .frame(height: 24, alignment: .center)

                Spacer()
                ProgressView(isAnimating: Binding(get: { true }, set: { _ in }), style: .spinning, controlSize: .small)
                    .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
            }
        }
    }
}
