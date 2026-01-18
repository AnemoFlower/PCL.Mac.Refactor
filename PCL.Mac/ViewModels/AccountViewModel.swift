//
//  AccountViewModel.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/15.
//

import Foundation
import Combine
import Core
import SwiftyJSON

class AccountViewModel: ObservableObject {
    @Published public private(set) var accounts: [Account] = [] {
        didSet {
            LauncherConfig.shared.accounts = accounts
        }
    }
    @Published public private(set) var currentAccountId: UUID? {
        didSet {
            LauncherConfig.shared.currentAccountId = currentAccountId
        }
    }
    public var currentAccount: Account? {
        if let currentAccountId {
            return accounts.first(where: { $0.id == currentAccountId })
        }
        return nil
    }
    
    public init() {
        self.accounts = LauncherConfig.shared.accounts
        self.currentAccountId = LauncherConfig.shared.currentAccountId
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
        if accounts.contains(where: { $0 is OfflineAccount && $0.profile.name == name }) {
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
        accounts.append(account)
        switchAccount(to: account)
    }
    
    /// 添加一个微软账号。
    /// - Parameter startCompletion: 设备码获取完成回调，此时需要用户打开 URL 并输入授权码。
    /// - Returns: 登录任务。
    public func addMicrosoftAccount(startCompletion: @escaping (MicrosoftAuthService.AuthorizationCode) -> Void) async throws -> MicrosoftAccount {
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
            accounts.append(account)
            switchAccount(to: account)
        }
        return account
    }
    
    /// 切换当前账号。
    public func switchAccount(to account: Account) {
        currentAccountId = account.id
    }
    
    /// 获取账号皮肤数据。
    public func skinData(for account: Account) async -> Data {
        let defaultSkin: Data = .init(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAdVBMVEUAAAAKvLwAzMwmGgokGAgrHg0zJBE/KhW3g2uzeV5SPYn///+qclmbY0mQWT8Af38AaGhVVVWUYD52SzOBUzmPXj5JJRBCHQp3QjVqQDA0JRIoKCg3Nzc/Pz9KSko6MYlBNZtGOqUDenoFiIgElZUApKQAr6/wvakZAAAAAXRSTlMAQObYZgAAAolJREFUeNrt1l1rHucZReFrj/whu5hSCCQtlOTE/f+/Jz4q9Cu0YIhLcFVpVg+FsOCVehi8jmZgWOzZz33DM4CXlum3gH95GgeAzQZVeL4gTm6Cbp4vqFkD8HwBazPY8wWbMq9utu3mNZ5fotVezbzOE3kBEFbaZuc8kb00NTMUbWJp678Xf2GV7RRtx1TDQQ6XBNvsmL2+2vHq1TftmMPIyAWujtN2cl274ua2jpVpZneXEjjo7XW1q53V9ds4ODO5xIuhvGHvfLI3aixauig415uuO2+vl9+cncfsFw25zL650fXn687jqnXuP68/X3+eV3zE7y6u9eB73MlfAcfbTf3yR8CfAX+if8S/H5/EAbAxj5LN48tULvEBOh8V1AageMTXe2YHAOwHbZxrzPkSR3+ffr8TR2JDzE/4Fj8CDgEwDsW+q+9GsR07hhg2CsALBgMo2v5wNxXnQXMeGQVW7gUAyKI2m6KDsJ8Au3++F5RZO+kKNQjQcLLWgjwUjBXLltFgWWMUUlviocBgNoxNGgMjSxiYAA7zgLFo2hgIENiDU8gQCzDOmViGFAsEuBcQSDCothhpJaDRA8E5fHqH2nTbYm5fHLo1V0u3B7DAuheoeScRYabjjjuzs17cHVaTrTXmK78m9swP34d9oK/dfeXSIH2PW/MXwPvxN/bJlxw8zlYAcEyeI6gNgA/O8P8neN8xe1IHP2gTzegjvhUDfuRygmwEs2GE4mkCDIAzm2R4yAuPsIdR9k8AvMc+3L9+2UEjo4WP0FpgP19O0MzCsqxIoMsdDBvYcQyGmO0ZJRoYCKjLJWY0BAhYwGUBCgkh8MRdOKt+ruqMwAB2OcEX94U1TPbYJP0PkyyAI1S6cSIAAAAASUVORK5CYII=")!
        do {
            guard let textures: Data = account.profile.property(forName: "textures") else {
                if !(account is OfflineAccount) {
                    warn("玩家档案中不存在 textures 属性")
                }
                return defaultSkin
            }
            let json: JSON = try .init(data: textures)
            guard let url: URL = json["textures"]["SKIN"]["url"].url else {
                err("解析 textures 属性失败")
                return defaultSkin
            }
            return try await Requests.get(url).data
        } catch {
            err("获取皮肤数据失败：\(error.localizedDescription)")
            return defaultSkin
        }
    }
}
