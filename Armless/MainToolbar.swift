//
//  MainToolbar.swift
//  Armless
//
//  Created by Tamas Lustyik on 2020. 11. 15..
//

import SwiftUI

struct MainTitle: View {
    var body: some View {
        HStack(alignment: .center) {
            Color.clear
                .frame(width: 0)
            Text((NSApplication.shared.delegate as? AppDelegate)?.window.title ?? "")
                .offset(y: -18)
            Image(nsImage: NSImage(named: "AppIcon")!)
                .resizable()
                .frame(width: 22, height: 22, alignment: .leading)
                .offset(y: -18)
            Spacer()
        }
    }
}

struct MainToolbar: View {
    @ObservedObject var viewModel: AnyViewModel<MainViewState, MainViewInput>

    var body: some View {
        HStack(alignment: .center) {
            Spacer()
                .layoutPriority(1)

            Button(action: {
                viewModel.trigger(.didPressClearListButton)
            }, label: {
                Text("Clear list")
                    .offset(y: 2)
            })
            .offset(y: -18)
            .disabled(!viewModel.state.isClearButtonEnabled)

            Button(action: {
                viewModel.trigger(.didPressStartButton)
            }, label: {
                Text("Snap!")
                    .offset(y: 2)
            })
            .offset(y: -18)
            .disabled(!viewModel.state.isStartButtonEnabled)

            Spacer(minLength: 10)
                .layoutPriority(0)
        }
    }
}
