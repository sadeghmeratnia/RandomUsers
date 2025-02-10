//
//  LoadUserFromRemoteUseCaseTest.swift
//  RandomUserTests
//
//  Created by Sadegh on 10/02/2025.
//

import Testing
import RandomUser
import Foundation

// MARK: - LoadUserFromRemoteUseCaseTest

struct LoadUserFromRemoteUseCaseTest {
    @Test func init_doesNotRequestDataFromURL() {
        let (_, client) = self.makeSUT()

        #expect(client.requestedURLs.isEmpty)
    }

    @Test(
        arguments: [
            [anyURL()],
            [anyURL(), anyURL()],
            [anyURL(), anyURL(), anyURL()]
        ])
    func load_requestsDataFromSeveralURLs(urls: [URL]) async {
        let (sut, client) = self.makeSUT()

        for url in urls {
            _ = await sut.load(from: url)
        }

        #expect(client.requestedURLs == urls)
    }
}

// MARK: - Helpers

extension LoadUserFromRemoteUseCaseTest {
    private func makeSUT() -> (sut: UserLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let loader = UserLoader(client: client)

        return (loader, client)
    }

    private static func anyURL() -> URL {
        URL(string: "any-URL.com")!
    }
}

// MARK: LoadUserFromRemoteUseCaseTest.HTTPClientSpy

extension LoadUserFromRemoteUseCaseTest {
    private class HTTPClientSpy: HTTPClient {
        private struct Task<T> {
            let url: URL
            let completion: (T) -> Void
        }

        private var tasks = [Task<HTTPClientResponse>]()

        var requestedURLs: [URL] {
            self.tasks.map { $0.url }
        }

        func get(from url: URL, completion: @escaping (RandomUser.HTTPClientResponse) -> Void) {
            self.tasks.append(.init(url: url, completion: completion))
        }
    }
}
