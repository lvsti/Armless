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
                    List(Array(viewModel.state.scanResults.enumerated()), id: \.element.id, selection: selection) { item in
                        let bgView = Color(NSColor.alternatingContentBackgroundColors[item.offset % NSColor.alternatingContentBackgroundColors.count])
                        ScanResultRow(scanResult: item.element)
                            .listRowBackground(bgView.frame(minHeight: 44))
                            .animation(.none)
                    }
                    .animation(.easeOut)
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

struct MainView_Previews: PreviewProvider {
    static var viewModel = MainViewModel()
    static var previews: some View {
        MainView(viewModel: AnyViewModel(viewModel))
    }
}
