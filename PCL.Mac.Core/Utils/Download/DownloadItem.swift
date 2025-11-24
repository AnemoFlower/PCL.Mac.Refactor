//
//  DownloadItem.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/22.
//

import Foundation

public struct DownloadItem {
    public let url: URL
    public let destination: URL
    public let sha1: String?
}

public enum ReplaceMethod {
    case replace, skip, `throw`
}
