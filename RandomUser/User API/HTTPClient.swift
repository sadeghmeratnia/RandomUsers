//
//  HTTPClient.swift
//  RandomUser
//
//  Created by Sadegh on 10/02/2025.
//

import Foundation

public enum HTTPClientResponse {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResponse) -> Void)
}
