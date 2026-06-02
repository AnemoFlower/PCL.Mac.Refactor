//
//  HomepageView.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/6/2.
//

import SwiftUI
import Core

struct HomepageView: View {
    @StateObject private var viewModel: HomepageViewModel = .init()
    
    var body: some View {
        CardContainer {
            if let homepage = viewModel.homepage {
                ForEach(Array(homepage.components.enumerated()), id: \.offset) { _, component in
                    AnyView(component.makeView())
                }
            } else {
                MyTip(text: "正在加载主页……", theme: .blue)
            }
        }
        .task {
            do {
                let demoHomepage = """
                    <?xml version="1.0"?>
                    <homepage author="风花AnemoFlower" description="主页解析测试">
                        <config
                            trimText="true"
                        />
                        <MyHint>
                            富文本字面量测试
                            {bold; 粗体} {italic; Italic（斜体，中文由于字体问题不支持斜体qwq）} {bold,italic; Bold &amp; Italic}
                            {#ff0000;R}{#ff7f00;a}{#ffff00;i}{#00ff00;n}{#0000ff;b}{#4b0082;o}{#9400d3;w}
                            {20px; 20px} {16px; 16px} {12px; 12px} {1px; 1px}
                        </MyHint>
                        
                        <MyCard title="可折叠的卡片">
                            <Text>文本</Text>
                        </MyCard>
                    </homepage>
                    """
                try await viewModel.load(from: .data(demoHomepage.data(using: .utf8)!))
            } catch {
                err("加载主页失败：\(error.localizedDescription)")
                hint("加载主页失败：\(error.localizedDescription)", type: .critical)
            }
        }
    }
}
