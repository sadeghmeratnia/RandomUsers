//
//  HTTPClient.swift
//  RandomUser
//
//  Created by Sadegh on 10/02/2025.
//

import Foundation

public typealias HTTPClientResponse = (Data, HTTPURLResponse)

public protocol HTTPClient {
    func get(from url: URL) async throws -> HTTPClientResponse
}
