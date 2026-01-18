//
//  PlayerAvatar.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/18.
//

import SwiftUI
import Core

struct PlayerAvatar: View {
    @StateObject private var viewModel: AccountViewModel = .init()
    @State private var skinImage: CIImage?
    private let account: Account
    
    init(_ account: Account) {
        self.account = account
    }
    
    var body: some View {
        ZStack {
            if let skinImage {
                SkinLayerView(image: skinImage, startX: 8, startY: 16)
                    .frame(width: 8 * 5.4)
                    .shadow(color: Color.black.opacity(0.2), radius: 1)
                SkinLayerView(image: skinImage, startX: 40, startY: 16)
                    .frame(width: 7.99 * 6.1)
            }
        }
        .frame(width: 58, height: 58)
        .task {
            let skinData: Data = await viewModel.skinData(for: account)
            guard let image: CIImage = .init(data: skinData) else {
                err("加载 CIImage 失败")
                return
            }
            await MainActor.run {
                self.skinImage = image
            }
        }
    }
}

private struct SkinLayerView: View {
    private let image: NSImage?
    
    init(image: CIImage, startX: CGFloat, startY: CGFloat) {
        let yOffset: CGFloat = image.extent.height == 32 ? 0 : 32
        let cropped: CIImage = image.cropped(to: CGRect(x: startX, y: startY + yOffset, width: 8, height: 8))
        let context: CIContext = .init()
        guard let cgImage = context.createCGImage(cropped, from: cropped.extent) else {
            warn("创建 CGImage 失败")
            self.image = nil
            return
        }
        self.image = NSImage(cgImage: cgImage, size: image.extent.size)
    }
    
    var body: some View {
        if let image {
            Image(nsImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
        }
    }
}
