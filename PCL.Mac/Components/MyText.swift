//
//  MyText.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2025/11/10.
//

import SwiftUI

struct MyText: View {
    private let text: AttributedString
    
    /// 创建一个富文本视图。
    ///
    /// `AttributedString` 没有设置字体或 `foregroundColor` 的部分将使用下方提供的参数。
    /// - Parameters:
    ///   - text: 包含文本内容的 `AttributedString`。
    ///   - size: 文本默认大小。
    ///   - color: 文本默认颜色。
    init(_ text: AttributedString, size: CGFloat = 14, color: Color = .color1) {
        let fallbackFont: Font = .system(size: size)
        var processedText = text
        for run in text.runs {
            let range = run.range
            if run.font == nil {
                processedText[range].font = fallbackFont
            }
            if run.foregroundColor == nil {
                processedText[range].foregroundColor = color
            }
        }
        self.text = processedText
    }
    
    /// 创建一个普通文本视图。
    ///
    /// 文本字体为 `PCL English`。
    /// - Parameters:
    ///   - text: 文本内容。
    ///   - size: 文本大小。
    ///   - color: 文本颜色。
    init(_ text: String, size: CGFloat = 14, color: Color = .color1) {
        var attributedText = AttributedString(text)
        attributedText.font = .custom("PCLEnglish", size: size)
        attributedText.foregroundColor = color
        self.text = attributedText
    }
    
    var body: some View {
        Text(text)
    }
}
