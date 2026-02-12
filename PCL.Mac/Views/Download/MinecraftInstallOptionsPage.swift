//
//  MinecraftInstallOptionsPage.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/2/11.
//

import SwiftUI
import Core

struct MinecraftInstallOptionsPage: View {
    @EnvironmentObject private var viewModel: InstanceViewModel
    @State private var name: String = ""
    @State private var loader: MinecraftInstallTask.ModLoader?
    private let version: MinecraftVersion
    
    init(version: MinecraftVersion) {
        self.name = version.id
        self.version = version
    }
    
    var body: some View {
        CardContainer {
            VStack {
                MyCard("", titled: false) {
                    HStack {
                        Image("GrassBlock")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .padding(.trailing, 12)
                        MyTextField(initial: name, immediately: true) { newName in
                            name = newName
                        }
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.bottom, 40)
                ModLoaderCard(.fabric, version, $loader)
                Spacer()
            }
            .padding(EdgeInsets(top: 10, leading: 25, bottom: 25, trailing: 25))
        }
        .overlay(alignment: .bottom) {
            MyExtraTextButton(image: "DownloadPageIcon", imageSize: 20, text: "开始下载") {
                guard let repository = viewModel.currentRepository else {
                    warn("试图安装 \(version)，但没有设置游戏仓库")
                    hint("请先添加一个游戏目录！", type: .critical)
                    return
                }
                
                TaskManager.shared.execute(task: MinecraftInstallTask.create(name: name, version: version, repository: repository, modLoader: loader) { instance in
                    viewModel.switchInstance(to: instance, repository)
                    if AppRouter.shared.getLast() == .tasks {
                        AppRouter.shared.removeLast()
                        if case .minecraftInstallOptions = AppRouter.shared.getLast() {
                            AppRouter.shared.removeLast()
                        }
                    }
                })
                AppRouter.shared.append(.tasks)
            }
            .padding()
        }
    }
}

private struct ModLoaderCard: View {
    @Binding private var currentLoader: MinecraftInstallTask.ModLoader?
    @State private var versions: [Version]?
    @State private var loadState: LoadState = .loading
    private let type: ModLoader
    private let minecraftVersion: MinecraftVersion
    
    init(_ type: ModLoader, _ minecraftVersion: MinecraftVersion, _ currentLoader: Binding<MinecraftInstallTask.ModLoader?>, ) {
        self.type = type
        self.minecraftVersion = minecraftVersion
        self._currentLoader = currentLoader
    }
    
    var body: some View {
        MyCard("\(type)\t\(loadState)", foldable: loadState == .finished, folded: true) {
            if let versions {
                MyList(versions.map { ListItem(image: iconName, name: $0.id, description: $0.stable ? "稳定版" : "测试版") }) { index in
                    currentLoader = .fabric(version: versions[index].id)
                }
            }
        }
        .task(id: type) {
            await loadVersions()
        }
    }
    
    private var iconName: String {
        switch type {
        case .fabric: "Fabric"
        }
    }
    
    private func loadVersions() async {
        do {
            switch type {
            case .fabric:
                let versions: [Version] = try await Requests.get("https://meta.fabricmc.net/v2/versions/loader/\(minecraftVersion)").json().arrayValue
                    .map { .init(id: $0["loader"]["version"].stringValue, stable: $0["loader"]["stable"].boolValue) }
                self.versions = versions
                loadState = versions.isEmpty ? .noUsableVersion : .finished
            }
        } catch {
            err("加载 \(type) 版本列表失败：\(error.localizedDescription)")
            await MainActor.run {
                loadState = .error(message: error.localizedDescription)
            }
        }
    }
    
    private enum LoadState: Equatable, CustomStringConvertible {
        case loading
        case noUsableVersion
        case error(message: String)
        case finished
        
        var description: String {
            switch self {
            case .loading: "加载中"
            case .noUsableVersion: "无可用版本"
            case .error(let message): "加载失败：\(message)"
            case .finished: "加载完成"
            }
        }
    }
    
    private struct Version {
        public let id: String
        public let stable: Bool
    }
}
