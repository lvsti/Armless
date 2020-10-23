//
//  Spinner.swift
//  UnArm
//
//  Created by Tamas Lustyik on 2020. 10. 10..
//

import AppKit
import SwiftUI

struct ProgressView: NSViewRepresentable {
    @Binding var isAnimating: Bool
    @Binding var progress: Double
    let isIndeterminate: Bool
    let style: NSProgressIndicator.Style
    let controlSize: NSControl.ControlSize

    static func spinner(isAnimating: Binding<Bool> = Binding(get: { true }, set: { _ in }),
                        controlSize: NSControl.ControlSize = .regular) -> ProgressView {
        return ProgressView(isAnimating: isAnimating,
                            progress: Binding(get: { 0.0 }, set: { _ in }),
                            isIndeterminate: true,
                            style: .spinning,
                            controlSize: controlSize)
    }

    static func bar(isAnimating: Binding<Bool> = Binding(get: { true }, set: { _ in }),
                    progress: Binding<Double> = Binding(get: { 0.0 }, set: { _ in }),
                    isIndeterminate: Bool = false,
                    controlSize: NSControl.ControlSize = .regular) -> ProgressView {
        return ProgressView(isAnimating: isAnimating,
                            progress: progress,
                            isIndeterminate: isIndeterminate,
                            style: .bar,
                            controlSize: controlSize)
    }

    func makeNSView(context: NSViewRepresentableContext<ProgressView>) -> NSProgressIndicator {
        let view = NSProgressIndicator()
        view.style = style
        view.controlSize = controlSize
        view.doubleValue = progress
        view.maxValue = 1.0
        view.isIndeterminate = isIndeterminate
        if isAnimating {
            view.startAnimation(nil)
        }
        return view
    }

    func updateNSView(_ view: NSProgressIndicator, context: NSViewRepresentableContext<ProgressView>) {
        if isAnimating {
            view.startAnimation(nil)
        }
        else {
            view.stopAnimation(nil)
        }
        view.doubleValue = progress
    }
}
