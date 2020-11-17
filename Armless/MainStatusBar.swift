//
//  MainStatusBar.swift
//  Armless
//
//  Created by Tamas Lustyik on 2020. 10. 10..
//

import SwiftUI

struct MainStatusBar: View {
    @ObservedObject var viewModel: AnyViewModel<MainViewState, MainViewInput>

    var body: some View {
        HStack {
            if let progress = viewModel.state.processingProgress {
                Text("Processing...")
                    .font(.system(size: 12.0, weight: .regular, design: .default))
                    .foregroundColor(Color(.secondaryLabelColor))
                    .frame(height: 24, alignment: .center)
                    .padding(.leading, 4)
                Spacer()
                ProgressView.bar(progress: Binding(get: { progress.fractionCompleted }, set: { _ in }),
                                 controlSize: .small)
                    .frame(maxWidth: 100)
                    .padding(.trailing, 4)
            }
            else {
                if viewModel.state.isScanning {
                    Color.clear
                        .frame(width: 24, height: 24)
                    Spacer()
                }

                Text(viewModel.state.statusText)
                    .font(.system(size: 12.0, weight: .regular, design: .default))
                    .foregroundColor(Color(.secondaryLabelColor))
                    .frame(height: 24, alignment: .center)

                if viewModel.state.isScanning {
                    Spacer()
                    ProgressView.spinner(controlSize: .small)
                        .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                }
            }
        }
    }
}
