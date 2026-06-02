//
//  HomepageService.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/6/2.
//

import Foundation
import SWXMLHash

class HomepageService {
    public func load(from source: Source) throws(HomepageLoadError) -> Homepage {
        let data: Data
        switch source {
        case .local(let url):
            do {
                data = try .init(contentsOf: url)
            } catch {
                throw .fileReadError(underlying: error)
            }
        case .network(let url):
            fatalError("not implemented")
        case .data(let providedData):
            data = providedData
        }
        
        guard let content = String(data: data, encoding: .utf8) else {
            throw .stringDecodeError(length: data.count)
        }
        
        do {
            let rootIndexer = XMLHash.parse(content)
            return try rootIndexer["homepage"].value() as Homepage
        } catch {
            throw .deserializeError(underlying: error)
        }
    }
    
    public enum HomepageLoadError: LocalizedError {
        case fileReadError(underlying: Error)
        case stringDecodeError(length: Int)
        case deserializeError(underlying: Error)
        
        public var errorDescription: String? {
            switch self {
            case .fileReadError(let underlying):
                "读取文件失败：\(underlying.localizedDescription)"
            case .stringDecodeError(let length):
                "解码字符串失败（\(length) 个字节）"
            case .deserializeError(let underlying):
                "解析 XML 主页失败：\(underlying.localizedDescription)"
            }
        }
    }
    
    public enum Source {
        case local(URL)
        case network(URL)
        case data(Data)
    }
}
