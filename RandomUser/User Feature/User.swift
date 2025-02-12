//
//  User.swift
//  RandomUser
//
//  Created by Sadegh on 10/02/2025.
//

import Foundation

public struct User: Codable {
    let name: Name
    let gender: String
    let email: String
    let phone: String
    let mobile: String
    let nationality: String

    init(name: Name, gender: String, email: String, phone: String, mobile: String, nationality: String) {
        self.name = name
        self.gender = gender
        self.email = email
        self.phone = phone
        self.mobile = mobile
        self.nationality = nationality
    }

    struct Name: Codable {
        let title, first, last: String
    }
}
