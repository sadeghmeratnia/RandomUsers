//
//  UserLoader.swift
//  RandomUser
//
//  Created by Sadegh on 10/02/2025.
//

import Foundation

// MARK: - RemoteUserLoader

public final class RemoteUserLoader {
    private let client: HTTPClient

    public typealias Result = Swift.Result<[User], Error>

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
        case unknown
    }

    public init(client: HTTPClient) {
        self.client = client
    }

    public func load(from url: URL) async throws -> [User] {
        do {
            let result = try await client.get(from: url)
            return try self.map(result.0, from: result.1)
        } catch let error as Error {
            throw error
        } catch {
            throw Error.unknown
        }
    }

    private func map(_ data: Data, from response: HTTPURLResponse) throws -> [User] {
        try UsersMapper.map(data, from: response).toModels()
    }
}
