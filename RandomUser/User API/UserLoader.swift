//
//  UserLoader.swift
//  RandomUser
//
//  Created by Sadegh on 10/02/2025.
//

import Foundation

public final class UserLoader {
    private var client: HTTPClient
    
    public init(client: HTTPClient) {
        self.client = client
    }
    
    public func load(from url: URL) async {
        self.client.get(from: url, completion: { _ in
            
        })
    }
}
