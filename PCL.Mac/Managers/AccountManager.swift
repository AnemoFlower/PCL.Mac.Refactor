//
//  AccountManager.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/14.
//

import Foundation
import Core

class AccountManager: ObservableObject {
    public static let shared: AccountManager = .init()
    @Published public private(set) var accounts: [Account] = []
    
    public func add(account: Account) {
        accounts.append(account)
    }
    
    private init() {}
}
