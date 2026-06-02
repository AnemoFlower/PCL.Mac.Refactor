//
//  Component.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/6/2.
//

import SwiftUI
import SWXMLHash
import Core

protocol HomepageComponent {
    associatedtype Body: View
    
    @ViewBuilder
    func makeView() -> Body
    
    static func deserialize(_ config: Homepage.Config, _ element: XMLIndexer) throws -> Self
}

struct HomepageComponentDeserializer {
    let config: Homepage.Config
    
    func deserialize(_ indexer: XMLIndexer) -> (any HomepageComponent)? {
        guard let element = indexer.element else { return nil }
        do {
            return switch element.name.lowercased() {
            case "myhint", "mytip": try MyHintComponent.deserialize(config, indexer)
            default: nil
            }
        } catch {
            err("解析主页控件 \(element.name) 失败：\(error.localizedDescription)")
            return nil
        }
    }
}

struct MyHintComponent: HomepageComponent {
    enum Color: String, XMLAttributeDeserializable {
        case blue, red, yellow
        
        var theme: MyTip.Theme {
            return switch self {
            case .blue: .blue
            case .red: .red
            case .yellow: .yellow
            }
        }
        
        static func deserialize(_ attribute: XMLAttribute) throws -> Color {
            guard let color = Color(rawValue: attribute.text) else {
                throw XMLDeserializationError.attributeDeserializationFailed(type: "Color", attribute: attribute)
            }
            return color
        }
    }
    
    let color: Color
    let content: AttributedString
    
    static func deserialize(_ config: Homepage.Config, _ element: XMLIndexer) throws -> MyHintComponent {
        return try MyHintComponent(
            color: (element.value(ofAttribute: "color")) ?? .blue,
            content: RichText.parse(element, trimText: config.trimText)
        )
    }
    
    func makeView() -> some View {
        MyTip(text: String(content.characters), theme: color.theme)
    }
}

struct RichText {
    let content: AttributedString
    
    static func parse(_ indexer: XMLIndexer, trimText: Bool) throws -> AttributedString {
        return try deserialize(indexer, trimText: trimText).content
    }
    
    static func deserialize(_ indexer: XMLIndexer, trimText: Bool) throws -> RichText {
        let rawContent = try indexer.value() as String
        let content = trimText
        ? rawContent
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .joined(separator: "\n")
        : rawContent
        
        var result = AttributedString()
        
        var currentIndex = content.startIndex
        
        while currentIndex < content.endIndex {
            guard let openBrace = content[currentIndex...].firstIndex(of: "{") else {
                result += .init(content[currentIndex...])
                break
            }
            
            if openBrace > currentIndex {
                result += .init(content[currentIndex..<openBrace])
            }
            
            guard let closeBrace = content[openBrace...].firstIndex(of: "}") else {
                result += .init(content[openBrace...])
                break
            }
            
            let block = content[content.index(after: openBrace)..<closeBrace]
            result += parseBlock(block)
            currentIndex = content.index(after: closeBrace)
        }
        
        return .init(content: result)
    }
    
    private static func parseBlock(_ block: any StringProtocol) -> AttributedString {
        let parts = block.split(separator: ";", maxSplits: 1)
        guard parts.count == 2 else { return .init(block) }
        
        let styles = parts[0].split(separator: ",")
        var result: AttributedString = AttributedString(String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines))
        
        for style in styles {
            let style = String(style)
            switch style {
            case "bold":
                result.font = (result.font ?? .system(size: 14)).bold()
            case "italic":
                result.font = (result.font ?? .system(size: 14)).italic()
            default:
                if style.hasSuffix("px"), let size = Float(style.dropLast(2)) {
                    result.font = .system(size: CGFloat(size))
                } else if style.hasPrefix("#"), style.count == 7, let hex = UInt(style.dropFirst(), radix: 16) {
                    result.foregroundColor = .init(hex)
                }
            }
        }
        
        return result
    }
}
