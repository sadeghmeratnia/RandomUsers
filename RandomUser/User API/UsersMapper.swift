//
//  UsersMapper.swift
//  RandomUser
//
//  Created by Sadegh on 12/02/2025.
//

import Foundation

internal final class UsersMapper {
    private struct Root: Decodable {
        let results: [UserDTO]
    }
    
    static func map(_ data: Data, from response: HTTPURLResponse) throws -> [UserDTO] {
        guard response.statusCode == 200,
              let root = try? JSONDecoder().decode(Root.self, from: data)
        else {
            throw RemoteUserLoader.Error.invalidData
        }
        
        return root.results
    }
}
