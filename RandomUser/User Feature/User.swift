//
//  User.swift
//  RandomUser
//
//  Created by Sadegh on 10/02/2025.
//

import Foundation

public struct User: Equatable {
    let id: UUID
    let name: Name
    let gender: String
    let email: String
    let phone: String
    let mobile: String
    let nationality: String

    init(id: UUID, name: Name, gender: String, email: String, phone: String, mobile: String, nationality: String) {
        self.id = id
        self.name = name
        self.gender = gender
        self.email = email
        self.phone = phone
        self.mobile = mobile
        self.nationality = nationality
    }

    struct Name: Equatable {
        let title, first, last: String
    }
}
