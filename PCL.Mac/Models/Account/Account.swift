//
//  Account.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/14.
//

import Foundation
import Core

protocol Account: Codable {
    var profile: PlayerProfileModel { get }
    func accessToken() throws -> String
    func refresh() async throws
}

class OfflineAccount: Account {
    public let profile: PlayerProfileModel
    
    public init(name: String, uuid: UUID) {
        self.profile = .init(name: name, id: uuid, properties: [])
    }
    
    public func accessToken() throws -> String {
        return UUIDUtils.string(of: .init(), withHyphens: false) // 随机 UUID
    }
    
    public func refresh() async throws {}
}
