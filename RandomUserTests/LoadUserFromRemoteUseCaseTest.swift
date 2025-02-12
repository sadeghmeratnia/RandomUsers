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
    @Test func init_doesNotRequestDataFromURL() async {
        let (_, client) = self.makeSUT()

        #expect(await client.requestedURLs.isEmpty)
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
            Task {
                try await sut.load(from: url)
            }
        }

        await Task.yield()

        #expect(await client.requestedURLs == urls)
    }

    @Test func load_deliversErrorOnClientError() async {
        let (sut, client) = self.makeSUT()
        let url = Self.anyURL()
        let expectedError = RemoteUserLoader.Error.connectivity

        let task = Task {
            try await sut.load(from: url)
        }

        await Task.yield()

        await client.complete(with: expectedError)

        do {
            _ = try await task.value
        } catch let error as RemoteUserLoader.Error {
            #expect(error == expectedError)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
    
    @Test(arguments: [199, 201, 300, 400, 404, 500])
    func load_deliversErrorOnNon200HttpStatusCode(code: Int) async {
        let (sut, client) = self.makeSUT()
        let url = Self.anyURL()
        let expectedError = RemoteUserLoader.Error.invalidData
        let json = makeItemJSON([])

        let task = Task {
            try await sut.load(from: url)
        }

        await Task.yield()

        await client.complete(withStatusCode: code, data: json)

        do {
            _ = try await task.value
        } catch let error as RemoteUserLoader.Error {
            #expect(error == expectedError)
        } catch {
            Issue.record("Expected \(expectedError), got \(error) instead.")
        }
    }
    
    @Test func load_deliversErrorOn200StatusCodeButInvalidJSON() async throws {
        let (sut, client) = self.makeSUT()
        let url = Self.anyURL()
        let expectedError = RemoteUserLoader.Error.invalidData
        let json = Data("Invalid JSON".utf8)

        let task = Task {
            _ = try await sut.load(from: url)
        }

        await Task.yield()

        await client.complete(withStatusCode: 200, data: json)

        do {
            _ = try await task.value
        } catch let error as RemoteUserLoader.Error {
            #expect(error == expectedError)
        } catch {
            Issue.record("Expected \(expectedError), got \(error) instead.")
        }
    }
}

// MARK: - Helpers

extension LoadUserFromRemoteUseCaseTest {
    private func makeSUT() -> (sut: RemoteUserLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let loader = RemoteUserLoader(client: client)

        return (loader, client)
    }

    private static func anyURL() -> URL {
        URL(string: "any-URL.com")!
    }
    
    private func makeItemJSON(_ items: [[String: Any]]) -> Data {
        let itemsJSON = ["results": items]
        return try! JSONSerialization.data(withJSONObject: itemsJSON)
    }
}

// MARK: LoadUserFromRemoteUseCaseTest.HTTPClientSpy

extension LoadUserFromRemoteUseCaseTest {
    private actor HTTPClientSpy: HTTPClient {
        private struct Task<T> {
            let url: URL
            let completion: CheckedContinuation<T, Error>
        }
        
        private var tasks = [Task<HTTPClientResponse>]()
        
        var requestedURLs: [URL] {
            tasks.map { $0.url }
        }
        
        func get(from url: URL) async throws -> HTTPClientResponse {
            try await withCheckedThrowingContinuation { continuation in
                self.tasks.append(.init(url: url, completion: continuation))
            }
        }
        
        func complete(with error: Error, at index: Int = 0) {
            guard tasks.indices.contains(index) else { return }
            tasks[index].completion.resume(throwing: error)
        }
        
        func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
            guard tasks.indices.contains(index) else { return }
            let response = HTTPURLResponse(
                url: tasks[index].url,
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )!
            tasks[index].completion.resume(returning: (data, response))
        }
    }
}
