//
//  MainView.swift
//  UnArm
//
//  Created by Tamas Lustyik on 2020. 10. 02..
//

import SwiftUI


struct MainView: View, DropDelegate {
    @ObservedObject var viewModel: AnyViewModel<MainViewState, MainViewInput>

    var body: some View {
        VStack {
            if viewModel.state.scanResults.isEmpty {
                Text("Drop files")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            else {
                List(viewModel.state.scanResults) { result in
                    ScanResultRow(scanResult: result)
                }
            }
        }
        .onDrop(of: [kUTTypeFileURL as String], delegate: self)
    }

    func performDrop(info: DropInfo) -> Bool {
        guard !info.itemProviders(for: [kUTTypeFileURL as String]).isEmpty else { return false }
        viewModel.trigger(.didReceiveDrop(info: info))
        return true
    }
}

struct MainToolbar: View {
    @ObservedObject var viewModel: AnyViewModel<MainViewState, MainViewInput>

    var body: some View {
        GeometryReader { geometry in
            Button("DisARM!") {
                viewModel.trigger(.didPressDisarmButton)
            }
            .disabled(viewModel.state.isProcessing)
            .offset(y: geometry.safeAreaInsets.top > 0 ? -geometry.size.height / 2 : 0)
        }
        .frame(height: 38)
    }
}

struct MainView_Previews: PreviewProvider {
    static var viewModel = MainViewModel()
    static var previews: some View {
        MainView(viewModel: AnyViewModel(viewModel))
    }
}
