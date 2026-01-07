//
//  LauncherConfig.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/26.
//

import Foundation
import Core

public class LauncherConfig: Codable {
    public static let shared: LauncherConfig = {
        let url: URL = AppURLs.configURL
        if !FileManager.default.fileExists(atPath: url.path) {
            let config: LauncherConfig = .init()
            log("配置文件不存在，正在创建")
            do {
                try save(config, to: url)
            } catch {
                err("保存配置文件失败：\(error.localizedDescription)")
            }
            return config
        }
        do {
            let data: Data = try Data(contentsOf: url)
            return try JSONDecoder.shared.decode(LauncherConfig.self, from: data)
        } catch {
            err("加载配置文件失败：\(error.localizedDescription)")
            return .init()
        }
    }()
    
    public var minecraftRepositories: [MinecraftRepository]
    public var currentRepository: Int?
    public var currentInstance: String?
    
    public init() {
        self.minecraftRepositories = []
    }
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let minecraftRepositories = try container.decodeIfPresent([MinecraftRepository].self, forKey: .minecraftRepositories) {
            self.minecraftRepositories = minecraftRepositories
            if let currentRepository = try container.decodeIfPresent(Int.self, forKey: .currentRepository) {
                self.currentRepository = minecraftRepositories.count > currentRepository ? currentRepository : nil
            } else {
                self.currentRepository = minecraftRepositories.isEmpty ? nil : 0
            }
        } else {
            log("正在设置默认目录")
            var url: URL = FileManager.default.homeDirectoryForCurrentUser.appending(path: "Library/Application Support/minecraft")
            if !FileManager.default.fileExists(atPath: url.path) { // 若官启（与 HMCL）目录不存在，使用未被隐藏且较浅的 ~/minecraft 目录
                url = FileManager.default.homeDirectoryForCurrentUser.appending(path: "minecraft")
            }
            log("默认目录路径：\(url.path)")
            self.minecraftRepositories = [.init(name: "默认目录", url: url)]
            self.currentRepository = 0
            try self.minecraftRepositories[0].load() // 理论上只会在第一次打开启动器时被执行
        }
        
        loadInstance: if let currentRepository = self.currentRepository {
            let repository: MinecraftRepository = self.minecraftRepositories[currentRepository]
            guard let instances = repository.instances else { break loadInstance }
            if let currentInstance = try container.decodeIfPresent(String.self, forKey: .currentInstance) { // 尝试从 JSON 中加载当前实例，若合法会直接跳出整个代码块
                if instances.contains(where: { $0.id == currentInstance }) {
                    self.currentInstance = currentInstance
                    break loadInstance
                } else {
                    warn("currentRepository 中不存在 \(currentInstance)")
                }
            }
            // fallback
            if !instances.isEmpty {
                self.currentInstance = instances.first?.id
            }
        }
    }
    
    public static func save(_ config: LauncherConfig = .shared, to url: URL = AppURLs.configURL) throws {
        let data: Data = try JSONEncoder.shared.encode(config)
        try data.write(to: url)
    }
    
    private enum CodingKeys: String, CodingKey {
        case minecraftRepositories
        case currentRepository
        case currentInstance
    }
}
