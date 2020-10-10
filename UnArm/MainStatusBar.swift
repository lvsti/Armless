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
                Color.clear
                    .frame(width: 20, height: 24)
                Spacer()
            }
            
            Text(statusText)
                .font(.system(size: 12.0, weight: .regular, design: .default))
                .foregroundColor(Color(.secondaryLabelColor))
                .frame(height: 24, alignment: .center)

            if viewModel.state.isProcessing {
                Spacer()
                Spinner(isAnimating: Binding(get: { true }, set: { _ in }), style: .spinning, controlSize: .small)
                    .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
            }
        }
    }

    private var statusText: String {
        guard !viewModel.state.scanResults.isEmpty else { return "No files" }

        let (eligibleCount, originalSize, reducedSize) = viewModel.state.scanResults.reduce((0, Int64(0), Int64(0))) { acc, next in
            guard next.slices.count > 1 else { return acc }
            let savings = next.slices.reduce(Int64(0)) { acc, next in acc + next.value } - next.slices[viewModel.state.sliceTypeForCurrentArch]!
            return (acc.0 + 1, acc.1 + next.originalSize, acc.2 + savings)
        }

        return "Estimated savings: \(Self.sizeFormatter.string(fromByteCount: originalSize - reducedSize)) " +
            "of \(Self.sizeFormatter.string(fromByteCount: originalSize)) in \(eligibleCount) binaries"
    }

    private static let sizeFormatter: ByteCountFormatter = {
        let fmt = ByteCountFormatter()
        fmt.countStyle = .file
        return fmt
    }()
}
