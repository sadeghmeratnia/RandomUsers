//
//  User.swift
//  RandomUser
//
//  Created by Sadegh on 10/02/2025.
//

import Foundation

public struct User: Equatable {
    public let id: UUID
    public let name: Name
    public let gender: String
    public let email: String
    public let phone: String
    public let mobile: String
    public let nationality: String

    public init(id: UUID, name: Name, gender: String, email: String, phone: String, mobile: String, nationality: String) {
        self.id = id
        self.name = name
        self.gender = gender
        self.email = email
        self.phone = phone
        self.mobile = mobile
        self.nationality = nationality
    }

    public struct Name: Equatable {
        public let title, first, last: String
        
        public init(title: String, first: String, last: String) {
            self.title = title
            self.first = first
            self.last = last
        }
    }
}
