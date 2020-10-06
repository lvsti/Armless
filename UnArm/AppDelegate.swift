//
//  AppDelegate.swift
//  UnArm
//
//  Created by Tamas Lustyik on 2020. 10. 02..
//

import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!
    var mainViewModel: MainViewModel!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the SwiftUI view that provides the window contents.
        mainViewModel = MainViewModel()
        let contentView = MainView(viewModel: AnyViewModel(mainViewModel))

        // Create the window and set the content view.
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .unifiedTitleAndToolbar, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.center()
        window.title = "DisARM"
        window.titleVisibility = .hidden
        window.setFrameAutosaveName("Main Window")
        window.contentView = NSHostingView(rootView: contentView)

        var toolbarView = MainToolbar(viewModel: AnyViewModel(mainViewModel))
        toolbarView.viewModel = contentView.viewModel
        let hostedToolbarView = NSHostingView(rootView: toolbarView)
        hostedToolbarView.frame.size.width = 100
//        hostedToolbarView.translatesAutoresizingMaskIntoConstraints = false

        let titlebarAccessory = NSTitlebarAccessoryViewController()
        titlebarAccessory.view = hostedToolbarView
        titlebarAccessory.layoutAttribute = .trailing

        window.toolbar = NSToolbar()
        window.addTitlebarAccessoryViewController(titlebarAccessory)

        window.makeKeyAndOrderFront(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

