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
        VStack(spacing: 0) {
            VStack {
                if viewModel.state.scanResults.isEmpty {
                    Text("Drop files")
                        .font(.title)
                        .foregroundColor(Color(.placeholderTextColor))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                else {
                    let selection = Binding(get: { viewModel.state.selectedIDs },
                                            set: { viewModel.trigger(.didChangeSelection(selectedIDs: $0)) })
                    List(viewModel.state.scanResults, selection: selection) { result in
                        let index = viewModel.state.scanResults.firstIndex(where: { $0.id == result.id })!
                        let bgView = Color(NSColor.alternatingContentBackgroundColors[index % NSColor.alternatingContentBackgroundColors.count])
                        ScanResultRow(scanResult: result)
                            .listRowBackground(bgView.frame(minHeight: 44))
                    }
                    .onDeleteCommand {
                        viewModel.trigger(.didPressDeleteOnList)
                    }
                }
            }
            .onDrop(of: [kUTTypeFileURL as String], delegate: self)
            MainStatusBar(viewModel: viewModel)
        }
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
