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
    @Test(.tags(.happyPath))
    func init_doesNotRequestDataFromURL() async {
        let (_, client) = self.makeSUT()

        #expect(await client.requestedURLs.isEmpty)
    }

    @Test(
        .tags(.happyPath),
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

    @Test(.tags(.sadPath))
    func load_deliversErrorOnClientError() async {
        let (sut, client) = self.makeSUT()

        await expect(sut, toCompleteWith: failure(.unknown)) {
            let clientError = NSError(domain: "Test", code: 0)
            await client.complete(with: clientError)
        }
    }

    @Test(.tags(.sadPath), arguments: [199, 201, 300, 400, 404, 500])
    func load_deliversErrorOnNon200HttpStatusCode(code: Int) async {
        let (sut, client) = self.makeSUT()

        await expect(sut, toCompleteWith: failure(.invalidData)) {
            let json = makeResultsJSON([])
            await client.complete(withStatusCode: code, data: json)
        }
    }

    @Test(.tags(.happyPath))
    func load_deliversErrorOn200StatusCodeButInvalidJSON() async throws {
        let (sut, client) = self.makeSUT()

        await expect(sut, toCompleteWith: failure(.invalidData)) {
            let json = Data("Invalid JSON".utf8)
            await client.complete(withStatusCode: 200, data: json)
        }
    }

    @Test(.tags(.happyPath))
    func load_deliversNoItemOn200StatusCodeButEmptyJSON() async throws {
        let (sut, client) = self.makeSUT()

        await expect(sut, toCompleteWith: .success([])) {
            let json = makeResultsJSON([])
            await client.complete(withStatusCode: 200, data: json)
        }
    }

    @Test(.tags(.happyPath))
    func load_deliversUsersOn200StatusCodeWithValidJSON() async throws {
        let (sut, client) = self.makeSUT()

        let (item1, jsonItem1) = makeUserJSON(
            id: UUID(),
            name: "Jack",
            lastName: "Willson",
            title: "Mr",
            gender: "Male",
            email: "jack@willson.com",
            phone: "07123456789",
            mobile: "07123456789",
            nationality: "British")

        let (item2, jsonItem2) = makeUserJSON(
            id: UUID(),
            name: "Jack",
            lastName: "Willson",
            title: "Mr",
            gender: "Male",
            email: "jack@willson.com",
            phone: "07123456789",
            mobile: "07123456789",
            nationality: "British")

        await expect(sut, toCompleteWith: .success([item1, item2])) {
            let json = makeResultsJSON([jsonItem1, jsonItem2])
            await client.complete(withStatusCode: 200, data: json)
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

    private func makeResultsJSON(_ items: [[String: Any]]) -> Data {
        let itemsJSON = ["results": items]
        return try! JSONSerialization.data(withJSONObject: itemsJSON)
    }

    private func makeUserJSON(id: UUID,
                              name: String,
                              lastName: String,
                              title: String,
                              gender: String,
                              email: String,
                              phone: String,
                              mobile: String,
                              nationality: String) -> (model: User, json: [String: Any]) {
        let item = User(
            id: id,
            name: .init(title: title, first: name, last: lastName),
            gender: gender,
            email: email,
            phone: phone,
            mobile: mobile,
            nationality: nationality)

        let nameObjc = ["title": item.name.title, "first": item.name.first, "last": item.name.last] as NSObject

        let jsonItem = [
            "id": item.id.uuidString,
            "gender": item.gender,
            "name": nameObjc,
            "email": item.email,
            "phone": item.phone,
            "cell": item.mobile,
            "nat": item.nationality
        ].compactMapValues { $0 }

        return (item, jsonItem)
    }

    private func expect(
        _ sut: RemoteUserLoader,
        toCompleteWith expectedResult: RemoteUserLoader.Result,
        when action: () async -> Void,
        _ sourceLocation: SourceLocation = #_sourceLocation) async {
        let url = Self.anyURL()

        let task = Task {
            try await sut.load(from: url)
        }

        await Task.yield()
        await action()

        let receivedResult = await task.result

        switch (receivedResult, expectedResult) {
        case let (.success(receivedItems), .success(expectedItems)):
            #expect(receivedItems == expectedItems, sourceLocation: sourceLocation)

        case let (.failure(receivedError), .failure(expectedError)):
            #expect(receivedError as NSError == expectedError as NSError, sourceLocation: sourceLocation)

        default:
            Issue.record("Expected \(expectedResult), got \(receivedResult) instead.", sourceLocation: sourceLocation)
        }
    }

    private func failure(_ error: RemoteUserLoader.Error) -> RemoteUserLoader.Result {
        .failure(error)
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
            self.tasks.map { $0.url }
        }

        func get(from url: URL) async throws -> HTTPClientResponse {
            try await withCheckedThrowingContinuation { continuation in
                self.tasks.append(.init(url: url, completion: continuation))
            }
        }

        func complete(with error: Error, at index: Int = 0) {
            guard self.tasks.indices.contains(index) else { return }
            self.tasks[index].completion.resume(throwing: error)
        }

        func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
            guard self.tasks.indices.contains(index) else { return }
            let response = HTTPURLResponse(
                url: tasks[index].url,
                statusCode: code,
                httpVersion: nil,
                headerFields: nil)!
            self.tasks[index].completion.resume(returning: (data, response))
        }
    }
}
