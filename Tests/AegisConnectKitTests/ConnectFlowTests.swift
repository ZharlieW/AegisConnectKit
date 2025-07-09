import XCTest
@testable import AegisConnectKit
import UIKit

final class ConnectFlowTests: XCTestCase {

    func testConnectSuccess() async throws {
        let kit = AegisConnectKit.shared
        // Stub URL opener: immediately simulate success callback
        kit.openURL = { url in
            let callback = URL(string: "myapp://x-callback-url/nip46AuthSuccess?state=teststate")!
            _ = kit.handleOpenURL(callback)
            return true
        }

        let credential = try await kit.connect(
            redirect: .init(
                source: "myapp",
                successScheme: "myapp://x-callback-url/nip46AuthSuccess",
                errorScheme: "myapp://x-callback-url/nip46AuthError",
                stateProvider: { "teststate" }
            ),
            scope: [],
            from: UIViewController()
        )
        XCTAssertEqual(credential.pubkey, "stub")
    }

    func testUserCancel() async throws {
        let kit = AegisConnectKit.shared
        kit.openURL = { url in
            let callback = URL(string: "myapp://x-callback-url/nip46AuthError?state=teststate&errorCode=USER_CANCEL")!
            _ = kit.handleOpenURL(callback)
            return true
        }

        do {
            _ = try await kit.connect(
                redirect: .init(
                    source: "myapp",
                    successScheme: "myapp://x-callback-url/nip46AuthSuccess",
                    errorScheme: "myapp://x-callback-url/nip46AuthError",
                    stateProvider: { "teststate" }
                ),
                scope: [],
                from: UIViewController()
            )
            XCTFail("Should throw userCancelled")
        } catch let error as AegisError {
            XCTAssertEqual(error, .userCancelled)
        }
    }
} 