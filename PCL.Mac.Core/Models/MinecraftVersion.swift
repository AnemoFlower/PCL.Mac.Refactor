//
//  MinecraftVersion.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/24.
//

import Foundation

public class MinecraftVersion: Comparable, Equatable, CustomStringConvertible {
    private static var versionList: [String] = []
    public let id: String
    public let index: Int
    
    public init(_ id: String) {
        self.id = id
        self.index = Self.versionList.firstIndex(of: id) ?? 0
    }
    
    public static func == (lhs: MinecraftVersion, rhs: MinecraftVersion) -> Bool {
        return lhs.id == rhs.id
    }
    
    public static func < (lhs: MinecraftVersion, rhs: MinecraftVersion) -> Bool {
        return lhs.index < rhs.index
    }
    
    public lazy var description: String = { id }()
    
    public static func loadVersionList(_ url: URL) throws {
        let content: String = try String(data: Data(contentsOf: url), encoding: .utf8).unwrap()
        versionList = content.split(separator: "\n").map(String.init)
    }
}
