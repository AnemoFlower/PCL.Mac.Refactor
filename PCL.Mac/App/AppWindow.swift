//
//  AppWindow.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2025/11/29.
//

import SwiftUI
import Core

fileprivate let isMacOS26: Bool = ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 26
fileprivate let isMacOS14OrLater: Bool = ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 14

class AppWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    
    init(instanceManager: InstanceManager) {
        super.init(
            contentRect: .init(x: 0, y: 0, width: 1000, height: 550),
            styleMask: [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView],
            backing: .buffered, defer: false
        )
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        
        self.contentView = NSHostingView(rootView: RootView(instanceManager: instanceManager))
        
        self.setFrameAutosaveName("AppWindow")
        self.center()
    }
}
