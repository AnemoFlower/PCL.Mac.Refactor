//
//  ModrinthAPIClient.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/3/16.
//

import Foundation

public class ModrinthAPIClient {
    public static let shared: ModrinthAPIClient = .init(apiRoot: URL(string: "https://api.modrinth.com")!)
    
    private let apiRoot: URL
    
    private init(apiRoot: URL) {
        self.apiRoot = apiRoot
    }
    
    /// 搜索 Modrinth 项目。
    /// - Parameters:
    ///   - type: 项目类型（`ProjectType`）。
    ///   - query: 搜索关键词。
    ///   - gameVersion: 过滤游戏版本。
    ///   - limit: 返回结果数量上限。
    /// - Returns: 包含搜索结果和分页信息的 `SearchResponse`。
    public func search(
        type: ProjectType,
        _ query: String?,
        forVersion gameVersion: String?,
        limit: Int = 40
    ) async throws -> SearchResponse {
        var facets: [[String]] = [["project_type:\(type)"]]
        if let gameVersion {
            facets.append(["versions:\(gameVersion)"])
        }
        let facetsString: String = String(data: try JSONSerialization.data(withJSONObject: facets), encoding: .utf8)!
        
        let response = try await Requests.get(
            apiRoot.appending(path: "/v2/search"),
            params: [
                "query": query == "" ? nil : query,
                "facets": facetsString,
                "limit": String(describing: limit)
            ]
        )
        return try response.decode(SearchResponse.self)
    }
    
    
    // MARK: - 数据模型
    
    public enum ProjectType: String, Codable {
        case mod, modpack, resourcepack, shader
    }
    
    public struct Project: Decodable {
        public enum Side {
            case client, server
        }
        
        public enum Compatibility: String, Decodable {
            case required, optional, unsupported, unknown
        }
        
        private enum CodingKeys: String, CodingKey {
            case id = "project_id", type = "project_type"
            case clientSide = "client_side", serverSide = "server_side"
            case iconURL = "icon_url"
            case gameVersions = "game_versions"
            
            case slug, title, description, downloads, versions, categories, loaders
        }
        
        public let id: String
        public let slug: String
        public let type: ProjectType
        public let title: String
        public let description: String
        public let iconURL: URL?
        public let downloads: Int
        public let categories: [String]
        public let compatibility: [Side: Compatibility]
        public let versions: [String]?
        public let gameVersions: [String]?
        public let loaders: [String]?
        
        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decode(String.self, forKey: .id)
            self.slug = try container.decode(String.self, forKey: .slug)
            self.type = try container.decode(ProjectType.self, forKey: .type)
            self.title = try container.decode(String.self, forKey: .title)
            self.description = try container.decode(String.self, forKey: .description)
            self.iconURL = try container.decodeIfPresent(String.self, forKey: .iconURL).flatMap(URL.init(string:))
            self.downloads = try container.decode(Int.self, forKey: .downloads)
            self.categories = try container.decode([String].self, forKey: .categories)
            self.compatibility = [
                .client: try container.decodeIfPresent(Compatibility.self, forKey: .clientSide) ?? .unknown,
                .server: try container.decodeIfPresent(Compatibility.self, forKey: .serverSide) ?? .unknown
            ]
            if let gameVersions: [String] = try container.decodeIfPresent([String].self, forKey: .gameVersions) {
                self.gameVersions = gameVersions
                self.versions = try container.decodeIfPresent([String].self, forKey: .versions)
            } else {
                self.gameVersions = try container.decodeIfPresent([String].self, forKey: .versions)
                self.versions = nil
            }
            self.loaders = try container.decodeIfPresent([String].self, forKey: .loaders)
        }
    }
    
    public struct SearchResponse: Decodable {
        private enum CodingKeys: String, CodingKey {
            case hits, offset, limit, totalHits = "total_hits"
        }
        
        public let hits: [Project]
        public let offset: Int
        public let limit: Int
        public let totalHits: Int
    }
}
