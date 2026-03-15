//
//  ModrinthAPIClientTests.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/3/16.
//

import Foundation
import Core
import Testing

struct ModrinthAPIClientTests {
    @Test func testSearch() async throws {
        let response: ModrinthAPIClient.SearchResponse = try await ModrinthAPIClient.shared.search(type: .mod, "Tweakeroo", forVersion: nil)
        print("Total hits: \(response.totalHits), limit: \(response.limit)")
        for hit in response.hits {
            print(hit.title)
        }
        
        _ = try await ModrinthAPIClient.shared.search(type: .mod, "Fabric API", forVersion: "1.21.11")
        _ = try await ModrinthAPIClient.shared.search(type: .mod, "", forVersion: nil)
    }
}
