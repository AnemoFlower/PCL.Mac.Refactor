//
//  AccountViewModel.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/15.
//

import Foundation
import Combine
import Core

class AccountViewModel: ObservableObject {
    @Published public private(set) var accounts: [Account] = []
    private let manager: AccountManager = .shared
    
    public init() {
        manager.$accounts.receive(on: RunLoop.main).assign(to: &$accounts)
    }
    
    /// 检查待添加的离线账号的属性是否合法。
    /// - Parameters:
    ///   - name: 玩家名。
    ///   - uuid: 玩家 `UUID`。
    /// - Returns: 若合法，返回 `nil`，否则返回一个 `LocalizedError`。
    public func checkAttributes(name: String, uuid: String?) -> AccountError? {
        if let uuid, UUIDUtils.uuid(of: uuid) == nil {
            return .invalidUUID
        }
        if manager.accounts.contains(where: { $0 is OfflineAccount && $0.profile.name == name }) {
            return .nameExists
        }
        return nil
    }
    
    /// 添加一个离线账号。
    /// - Parameters:
    ///   - name: 玩家名。
    ///   - uuid: 玩家 `UUID`。
    public func addOfflineAccount(name: String, uuid: String?) throws {
        if let error = checkAttributes(name: name, uuid: uuid) {
            log("离线账号检查不通过：\(error.localizedDescription)")
            throw error
        }
        let account: OfflineAccount = .init(name: name, uuid: try uuid.map(UUIDUtils.uuidThrowing(of:)) ?? UUIDUtils.uuid(ofOfflinePlayer: name))
        manager.add(account: account)
    }
    
    public func addMicrosoftAccount(startCompletion: @escaping (MicrosoftAuthService.AuthorizationCode) -> Void) -> Task<MicrosoftAccount, Error> {
        Task {
            log("开始进行微软登录")
            let service: MicrosoftAuthService = .init()
            let code = try await service.start()
            log("获取设备码成功")
            await MainActor.run {
                startCompletion(code)
            }
            
            guard let pollCount = service.pollCount,
                  let pollInterval = service.pollInterval else {
                err("pollCount 或 pollInterval 未被设置")
                throw MicrosoftAuthService.Error.internalError
            }
            for _ in 0..<pollCount {
                try Task.checkCancellation()
                try await Task.sleep(seconds: Double(pollInterval))
                if try await service.poll() {
                    break
                }
            }
            
            let response = try await service.authenticate()
            let account: MicrosoftAccount = .init(profile: response.profile, accessToken: response.accessToken, refreshToken: response.refreshToken)
            await MainActor.run {
                manager.add(account: account)
            }
            return account
        }
    }
}
