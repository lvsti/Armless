//
//  Spinner.swift
//  UnArm
//
//  Created by Tamas Lustyik on 2020. 10. 10..
//

import AppKit
import SwiftUI

struct Spinner: NSViewRepresentable {
    @Binding var isAnimating: Bool
    let style: NSProgressIndicator.Style
    let controlSize: NSControl.ControlSize

    func makeNSView(context: NSViewRepresentableContext<Spinner>) -> NSProgressIndicator {
        let view = NSProgressIndicator()
        view.style = style
        view.controlSize = controlSize
        if isAnimating {
            view.startAnimation(nil)
        }
        return view
    }

    func updateNSView(_ view: NSProgressIndicator, context: NSViewRepresentableContext<Spinner>) {
        if isAnimating {
            view.startAnimation(nil)
        }
        else {
            view.stopAnimation(nil)
        }
    }
}
