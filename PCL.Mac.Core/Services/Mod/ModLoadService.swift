//
//  ModLoadService.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/6/7.
//

import Foundation
import ZIPFoundation

public class ModLoadService {
    private let remoteLookupService: ModRemoteLookupService
    private let cache: ModCache
    
    public init(remoteLookupService: ModRemoteLookupService, cache: ModCache) {
        self.remoteLookupService = remoteLookupService
        self.cache = cache
    }
    
    /// 将单个模组文件加载为 `Mod` 结构体。
    /// - Returns: 一个 `Mod`，若无法识别模组则为 `nil`。
    /// - Throws: `LoadError`
    public func load(from fileURL: URL) async throws(LoadError) -> Mod? {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDirectory) else {
            throw .fileNotExists
        }
        guard isDirectory.boolValue == false else { throw .isDirectory }
        
        let sha1: String
        do {
            sha1 = try FileUtils.sha1(of: fileURL)
        } catch {
            throw .readError(underlying: error)
        }
        
        if let cached = cache.mod(forHash: sha1) { return cached }
        
        let remoteInfo: ModRemoteLookupService.RemoteModInfo?
        do {
            remoteInfo = try await remoteLookupService.lookup(hash: sha1)
        } catch {
            err("加载 \(fileURL.lastPathComponent) 的远端模组信息失败：\(error.localizedDescription)")
            remoteInfo = nil
        }
        
        if let mod = try loadModFile(at: fileURL, remoteInfo: remoteInfo) {
            cache.store(mod, forHash: sha1)
            return mod
        }
        return nil
    }
    
    public enum LoadError: LocalizedError {
        case fileNotExists
        case isDirectory
        case readError(underlying: Error)
        case extractError(underlying: Error)
        
        public var errorDescription: String? {
            switch self {
            case .fileNotExists:
                "模组文件不存在。"
            case .isDirectory:
                "期望获得文件，但找到了一个文件夹。"
            case .readError(let underlying):
                "读取文件失败：\(underlying.localizedDescription)"
            case .extractError(let underlying):
                "解压文件失败：\(underlying.localizedDescription)"
            }
        }
    }
    
    
    private func loadModFile(at url: URL, remoteInfo: ModRemoteLookupService.RemoteModInfo?) throws(LoadError) -> Mod? {
        let archive: Archive
        do {
            archive = try .init(url: url, accessMode: .read)
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
        let icon: ResourceIcon? = meta.icon.map { .archiveEntry(path: $0) } ?? remoteInfo?.icon.map { .network(url: $0) }
        
        return .init(
            name: meta.name ?? remoteInfo?.name ?? meta.id,
            version: meta.version,
            description: meta.description ?? remoteInfo?.description,
            icon: icon,
            loaders: loaders,
            sources: (remoteInfo?.source).map { [$0] } ?? []
        )
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
