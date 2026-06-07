//
//  ModLoadService.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/6/7.
//

import Foundation
import ZIPFoundation

public class ModLoadService {
    private let fileURL: URL
    private let remoteModInfo: RemoteModInfo?
    private let sources: [Mod.Source]
    
    /// 从本地文件加载一个模组。
    /// - Parameter fileURL: 模组文件的 `URL`。
    public init(fileURL: URL) {
        self.fileURL = fileURL
        self.remoteModInfo = nil
        self.sources = []
    }
    
    /// 从来自 Modrinth 的文件加载一个模组。
    /// - Parameters:
    ///   - fileURL: 模组文件的 `URL`。
    ///   - project: 该文件对应的 `ModrinthProject`。
    public init(fileURL: URL, modrinthProject project: ModrinthProject) {
        self.fileURL = fileURL
        self.remoteModInfo = .init(
            name: project.title,
            description: project.description,
            icon: project.iconURL
        )
        self.sources = [.modrinth(projectId: project.id)]
    }
    
    /// 从来自 CurseForge 的文件加载一个模组。
    /// - Parameters:
    ///   - fileURL: 模组文件的 `URL`。
    ///   - project: 该文件对应的 `CurseForgeMod`。
    public init(fileURL: URL, curseforgeMod project: CurseForgeMod) {
        self.fileURL = fileURL
        self.remoteModInfo = .init(
            name: project.name,
            description: project.summary,
            icon: project.logo.thumbnailURL
        )
        self.sources = [.curseforge(id: project.id)]
    }
    
    /// 将模组文件加载为 `Mod` 结构体。
    /// - Returns: 一个 `Mod`，若无法识别模组则为 `nil`。
    /// - Throws: `LoadError`
    public func load() throws(LoadError) -> Mod? {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDirectory) else {
            throw .fileNotExists
        }
        guard isDirectory.boolValue == false else { throw .notADirectory }
        
        let archive: Archive
        do {
            archive = try .init(url: fileURL, accessMode: .read)
        } catch {
            throw .extractError(underlying: error)
        }
        
        var loaders: [ModLoader] = []
        var meta: ModMeta?
        if let fabricMeta = loadModMeta(archive, "fabric.mod.json", loader: loadFabric(from:)) {
            loaders.append(.fabric)
            if meta == nil { meta = fabricMeta }
        }
        
        guard let meta else { return nil }
        return .init(
            name: meta.name ?? remoteModInfo?.name ?? meta.id,
            version: meta.version,
            description: meta.description ?? remoteModInfo?.description ?? "",
            icon: meta.icon.map { .archiveEntry(path: $0) } ?? remoteModInfo?.icon.map { .network(url: $0) },
            loaders: loaders,
            sources: sources
        )
    }
    
    public enum LoadError: LocalizedError {
        case fileNotExists
        case notADirectory
        case extractError(underlying: Error)
        
        public var errorDescription: String? {
            switch self {
            case .fileNotExists:
                "模组文件不存在。"
            case .notADirectory:
                "模组文件是一个文件夹。"
            case .extractError(let underlying):
                "解压文件失败：\(underlying.localizedDescription)"
            }
        }
    }
    
    
    private func loadModMeta(_ archive: Archive, _ path: String, loader: (Data) throws -> ModMeta) -> ModMeta? {
        if let entry = archive[path] {
            do {
                let data = try archive.extract(entry)
                return try loader(data)
            } catch let error as DecodingError {
                err("解析模组元数据失败：\(error)")
            } catch {
                err("解压 \(path) 失败：\(error.localizedDescription)")
                return nil
            }
        }
        return nil
    }
    
    private func loadFabric(from data: Data) throws -> ModMeta {
        let fabricMeta: FabricMeta = try JSONDecoder.shared.decode(FabricMeta.self, from: data)
        return .init(
            id: fabricMeta.id,
            name: fabricMeta.name,
            description: fabricMeta.description,
            version: fabricMeta.version,
            icon: fabricMeta.icon
        )
    }
    
    // MARK: - 数据模型
    
    private struct RemoteModInfo {
        let name: String
        let description: String
        let icon: URL?
    }
    
    private struct ModMeta {
        let id: String
        let name: String?
        let description: String?
        let version: String
        let icon: String?
    }
    
    private struct FabricMeta: Codable {
        let schemaVersion: Int
        let id: String
        let version: String
        let name: String?
        let description: String?
        let icon: String?
    }
}
