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
    let style: NSProgressIndicator.Style
    let controlSize: NSControl.ControlSize

    func makeNSView(context: NSViewRepresentableContext<ProgressView>) -> NSProgressIndicator {
        let view = NSProgressIndicator()
        view.style = style
        view.controlSize = controlSize
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
    }
}
