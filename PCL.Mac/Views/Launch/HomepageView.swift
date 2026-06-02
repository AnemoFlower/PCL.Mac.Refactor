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
                    <homepage author="风花AnemoFlower" summary="主页解析测试">
                        <config
                            trimText="true"
                        />
                        <MyHint>这是一个用于预览控件与测试 XML 主页解析的主页！</MyHint>
                        <MyHint>
                            富文本字面量测试
                            {bold; 粗体} {italic; Italic（斜体，中文由于字体问题不支持斜体qwq）} {bold,italic; Bold &amp; Italic}
                            {#ff0000;R}{#ff7f00;a}{#ffff00;i}{#00ff00;n}{#0000ff;b}{#4b0082;o}{#9400d3;w}
                            {20px; 20px} {16px; 16px} {12px; 12px} {1px; 1px}
                        </MyHint>
                        
                        <MyCard title="可折叠的卡片">
                            未被标签包裹的{bold;文本}
                            <Text>被标签包裹的{bold;文本}</Text>
                            <Text>
                                {;}
                                上面和下面都应该有空行
                                
                                上面和下面都应该有空行
                                {;}
                            </Text>
                        </MyCard>
                        
                        <MyCard title="不可折叠的卡片" foldable="false">
                            该卡片默认展开
                        </MyCard>
                        
                        <MyCard>
                            不可折叠也没有标题的卡片
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
