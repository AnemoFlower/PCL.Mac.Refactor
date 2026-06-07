//
//  ModCache.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/6/7.
//

import Foundation

public class ModCache {
    private let cacheFileURL: URL
    private var cacheMap: [String: Mod]
    
    public init(cacheFileURL: URL) {
        self.cacheFileURL = cacheFileURL
        if FileManager.default.fileExists(atPath: cacheFileURL.path) {
            do {
                let data = try Data(contentsOf: cacheFileURL)
                self.cacheMap = try JSONDecoder.shared.decode([String: Mod].self, from: data)
            } catch {
                err("缓存文件加载失败：\(error.localizedDescription)")
                try? FileManager.default.removeItem(at: cacheFileURL)
                self.cacheMap = [:]
            }
        } else {
            self.cacheMap = [:]
        }
    }
    
    public func mod(forHash hash: String) -> Mod? { cacheMap[hash] }
    
    public func store(_ mod: Mod, forHash hash: String) { cacheMap[hash] = mod }
    
    public func save() throws {
        let data = try JSONEncoder.shared.encode(cacheMap)
        try data.write(to: cacheFileURL)
    }
}
