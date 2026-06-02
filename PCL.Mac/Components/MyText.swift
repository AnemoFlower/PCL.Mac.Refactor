//
//  MyText.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2025/11/10.
//

import SwiftUI

struct MyText: View {
    private let text: AttributedString
    private let size: CGFloat
    private let color: Color
    
    /// 创建一个富文本视图。
    ///
    /// `AttributedString` 没有设置字体的部分会被替换为 `PCL English` 字体。
    /// - Parameters:
    ///   - text: 包含文本内容的 `AttributedString`。
    ///   - size: 文本默认大小。
    ///   - color: 文本默认颜色。
    init(_ text: AttributedString, size: CGFloat = 14, color: Color = .color1) {
        self.text = text
        self.size = size
        self.color = color
    }
    
    /// 创建一个普通文本视图。
    ///
    /// 文本字体为 `PCL English`。
    /// - Parameters:
    ///   - text: 文本内容。
    ///   - size: 文本大小。
    ///   - color: 文本颜色。
    init(_ text: String, size: CGFloat = 14, color: Color = .color1) {
        self.text = AttributedString(text)
        self.size = size
        self.color = color
    }
    
    var body: some View {
        Text(text)
            .font(.custom("PCLEnglish", size: size))
            .foregroundStyle(color)
    }
}
