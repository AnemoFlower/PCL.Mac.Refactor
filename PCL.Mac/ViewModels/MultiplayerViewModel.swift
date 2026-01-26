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
    private var client: ScaffoldingClient?
    private let vendor: String = "PCL.Mac \(Metadata.appVersion), SwiftScaffolding DEV, EasyTier v2.5.0"
    
    /// 创建并启动一个 Scaffolding 联机中心。
    /// - Parameter serverPort: Minecraft 服务器的端口。
    /// - Returns: 房间邀请码。
    public func startHost(serverPort: UInt16) {
        Task {
            do {
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
                    vendor: vendor,
                    serverPort: serverPort
                )
                
                do {
                    try await server.startListener()
                    try server.createRoom { process in
                        if case .hostReady(_) = self.state {
                            if [127 + SIGTERM, 127 + SIGKILL].contains(process.terminationStatus) {
                                log("用户手动退出了 EasyTier 进程")
                                Task {
                                    await self.switchState(to: .failed(message: "错误：EasyTier 进程被杀死。"))
                                }
                            } else {
                                err("EasyTier 进程意外退出")
                                Task {
                                    await self.switchState(to: .failed(message: "错误：EasyTier 发生崩溃。"))
                                }
                            }
                        }
                    }
                    await MainActor.run {
                        self.server = server
                        self.state = .hostReady(roomCode: server.roomCode)
                    }
                    log("启动联机中心成功，房间码：\(server.roomCode)")
                } catch {
                    throw Error.startServerFailed(message: error.localizedDescription)
                }
            } catch {
                err("启动联机中心失败：\(error.localizedDescription)")
                await switchState(to: .failed(message: "启动联机中心失败：\(error.localizedDescription)"))
            }
        }
    }
    
    /// 关闭联机中心。
    public func stopHost() throws {
        guard let server, case .hostReady(_) = state else {
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
        
        case searchingMinecraft, creatingRoom, hostReady(roomCode: String)
        case joiningRoom, memberReady(address: String)
    }
    
    public enum Error: LocalizedError {
        case invalidState
        case startServerFailed(message: String)
        
        public var errorDescription: String? {
            switch self {
            case .invalidState: "错误的状态。"
            case .startServerFailed(let message): message
            }
        }
    }
}
