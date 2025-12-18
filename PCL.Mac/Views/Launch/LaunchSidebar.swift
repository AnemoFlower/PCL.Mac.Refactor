//
//  LaunchSidebar.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/10.
//

import SwiftUI
import Core

struct LaunchSidebar: Sidebar {
    let width: CGFloat = 240
    
    var body: some View {
        MyText("LaunchSidebar")
        VStack {
            Spacer()
            MyButton("启动游戏") {
                Task.detached {
                    let instance = try MinecraftInstance.load(from: URL(fileURLWithPath: "/tmp/versions/test"))
                    var options: LaunchOptions = .init()
                    options.runningDirectory = URL(fileURLWithPath: "/tmp/versions/test")
                    options.javaURL = URL(fileURLWithPath: "/usr/bin/java")
                    options.manifest = instance.manifest
                    options.memory = 4096
                    let launcher: MinecraftLauncher = .init(options: options)
                    let _ = try launcher.launch()
                }
            }
            .frame(height: 40)
            .padding()
        }
    }
}
