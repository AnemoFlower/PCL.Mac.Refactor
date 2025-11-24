//
//  LaunchOptions.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/21.
//

import Foundation

public class LaunchOptions {
    public var isDemo: Bool
    public var windowSize: (Int, Int)?
    
    public init(isDemo: Bool, windowSize: (Int, Int)? = nil) {
        self.isDemo = isDemo
        self.windowSize = windowSize
    }
}
