//
//  MultiplayerViewModel.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/15.
//

import Foundation
import SwiftScaffolding
import Core

class MultiplayerViewModel: ObservableObject {
    @Published public var state: State = .ready
    private var server: ScaffoldingServer?
    
    /// 创建并启动一个 Scaffolding 联机中心。
    /// - Parameter serverPort: Minecraft 服务器的端口。
    /// - Returns: 房间邀请码。
    public func startHost(serverPort: UInt16) async throws -> String {
        guard state == .ready else {
            err("启动联机中心失败：错误的状态：\(state)")
            throw Error.invalidState
        }
        guard server == nil else {
            err("启动联机中心失败：似乎已有一个联机中心正在运行")
            throw Error.invalidState
        }
        await switchState(to: .creatingRoom)
        let code: String = RoomCode.generate()
        let server: ScaffoldingServer = .init(
            easyTier: EasyTierManager.shared.easyTier,
            roomCode: code,
            playerName: "Test",
            vendor: "PCL.Mac 0.1.1, EasyTier v2.5.0",
            serverPort: serverPort
        )
        do {
            try await server.startListener()
            try server.createRoom()
            await MainActor.run {
                self.server = server
                self.state = .hostReady
            }
            log("启动联机中心成功，房间码：\(server.roomCode)")
        } catch {
            err("启动联机中心失败：\(error.localizedDescription)")
            await switchState(to: .failed(message: "启动联机中心失败：\(error.localizedDescription)"))
            throw Error.startServerFailed(message: error.localizedDescription)
        }
        return code
    }
    
    /// 关闭联机中心。
    public func stopHost() throws {
        guard let server, state == .hostReady else {
            err("关闭联机中心失败：似乎没有联机中心正在运行")
            throw Error.invalidState
        }
        server.stop()
        self.server = nil
        log("关闭联机中心成功")
    }
    
    private func switchState(to state: State) async {
        await MainActor.run {
            self.state = state
        }
    }
    
    public enum State: Equatable {
        case ready
        case failed(message: String)
        
        case searchingMinecraft, creatingRoom, hostReady
        case joiningRoom, memberReady
    }
    
    public enum Error: LocalizedError {
        case invalidState
        case startServerFailed(message: String)
    }
}
