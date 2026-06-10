//
//  ResourceDisplayModel.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/6/7.
//

import Foundation
import AppKit
import Core

struct ModDisplayModel {
    let id: UUID = .init()
    let name: String
    let version: String
    let description: String
    let tags: [String]
    let icon: ListItem.Image
    let fileName: String
    
    init(name: String, version: String, description: String, tags: [String], icon: ListItem.Image?, fileName: String) {
        self.name = name
        self.version = version
        self.description = description
        self.tags = tags
        self.icon = icon ?? .resource(.iconModLogo)
        self.fileName = fileName
    }
    
    init(_ url: URL, _ mod: Mod) {
        let icon: ListItem.Image?
        if let modIcon = mod.icon {
            switch modIcon {
            case .archiveEntry(_, let globalHash):
                if let data = (try? ModCache.shared.icon(forHash: globalHash)),
                   let nsImage = NSImage(data: data) {
                    icon = .nsImage(nsImage)
                } else {
                    icon = nil
                }
            case .network(let url):
                icon = .network(url)
            }
        } else {
            icon = nil
        }
        
        self.init(
            name: mod.name,
            version: mod.version,
            description: mod.description ?? "",
            tags: mod.tags.map(ProjectListItemModel.localizeTag(_:)),
            icon: icon,
            fileName: url.lastPathComponent
        )
    }
}
