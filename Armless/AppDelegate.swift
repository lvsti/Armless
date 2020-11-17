//
//  AppDelegate.swift
//  Armless
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
        window.title = "Mostly ARMless"
        window.titleVisibility = .hidden
        window.setFrameAutosaveName("Main Window")
        window.contentView = NSHostingView(rootView: contentView)
        window.setContentBorderThickness(24.0, for: .minY)

        window.toolbar = NSToolbar()

        let titleView = MainTitle()
        let hostedTitleView = NSHostingView(rootView: titleView)
        hostedTitleView.frame.size.width = 200
        hostedTitleView.translatesAutoresizingMaskIntoConstraints = false

        let titleAccessory = NSTitlebarAccessoryViewController()
        titleAccessory.view = hostedTitleView
        titleAccessory.layoutAttribute = .leading

        window.addTitlebarAccessoryViewController(titleAccessory)

        var toolbarView = MainToolbar(viewModel: AnyViewModel(mainViewModel))
        toolbarView.viewModel = contentView.viewModel
        let hostedToolbarView = NSHostingView(rootView: toolbarView)
        hostedToolbarView.frame.size.width = 200
        hostedToolbarView.translatesAutoresizingMaskIntoConstraints = false

        let toolbarAccessory = NSTitlebarAccessoryViewController()
        toolbarAccessory.view = hostedToolbarView
        toolbarAccessory.layoutAttribute = .trailing

        window.addTitlebarAccessoryViewController(toolbarAccessory)

        window.makeKeyAndOrderFront(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

