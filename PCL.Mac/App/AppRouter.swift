//
//  AppRouter.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/9.
//

import SwiftUI

enum AppRoute: Identifiable {
    // 根页面
    case launch, download, multiplayer, settings, other, tasks
    
    // 启动页面的子页面
    case instanceList, instanceSettings
    
    // 下载页面的子页面
    case minecraftDownload, downloadPage2, downloadPage3
    
    var id: String { stringValue }
    
    var stringValue: String {
        switch self {
        default: String(describing: self)
        }
    }
}

class AppRouter: ObservableObject {
    static let shared: AppRouter = .init()
    private static let rootRoutes: [AppRoute] = [.launch, .download, .multiplayer, .settings, .other]
    
    @Published private(set) var path: [AppRoute] = [.launch]
    
    /// 当前页面的主内容（右半部分）
    @ViewBuilder
    var content: some View {
        switch getLast() {
        case .launch:
            LaunchPage()
        case .minecraftDownload:
            MinecraftDownloadPage()
        case .downloadPage2:
            DownloadPage2()
        case .downloadPage3:
            DownloadPage3()
        case .tasks:
            TasksPage()
        default:
            Spacer()
        }
    }
    
    /// 当前页面的侧边栏（左半部分）
    var sidebar: any Sidebar {
        if getLast() == .launch { return LaunchSidebar() }
        if getLast() == .instanceList { return InstanceListSidebar() }
        if getLast() == .instanceSettings { return EmptySidebar() }
        
        if getRoot() == .download { return DownloadSidebar() }
        return EmptySidebar()
    }
    
    /// 当前页面是不是子页面（需要显示返回键和标题，隐藏导航按钮）
    var isSubPage: Bool {
        if Self.rootRoutes.contains(getLast()) { return false }
        if getRoot() == .download { return false } // TODO
        return true
    }
    
    /// 当前子页面的标题
    var title: String {
        switch getLast() {
        case .tasks: "任务列表"
        case .instanceList: "实例列表"
        case .instanceSettings: "实例设置"
        default: "错误：当前页面没有标题，请报告此问题！"
        }
    }
    
    func getLast() -> AppRoute {
        return path[path.count - 1]
    }
    
    func getRoot() -> AppRoute {
        return path[0]
    }
    
    func setRoot(_ newRoot: AppRoute) {
        path = [newRoot]
        // 各根页面的默认子页面
        if newRoot == .download { append(.minecraftDownload) }
    }
    
    func append(_ route: AppRoute) {
        path.append(route)
    }
    
    func removeLast() {
        if path.count > 1 {
            path.removeLast()
        }
    }
    
    private init() {
    }
}
