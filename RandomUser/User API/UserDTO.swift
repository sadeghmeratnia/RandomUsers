//
//  UserDTO.swift
//  RandomUser
//
//  Created by Sadegh on 12/02/2025.
//

import Foundation

// MARK: - UserDTO

internal struct UserDTO: Codable {
    var id = UUID()
    let gender: String
    let name: NameDTO
    let email: String
    let phone, cell: String
    let nat: String

    struct NameDTO: Codable {
        let title, first, last: String
    }
}

extension [UserDTO] {
    func toModels() -> [User] {
        map {
            .init(
                id: $0.id,
                name: .init(title: $0.name.title, first: $0.name.first, last: $0.name.last),
                gender: $0.gender,
                email: $0.email,
                phone: $0.phone,
                mobile: $0.cell,
                nationality: $0.nat)
        }
    }
}
