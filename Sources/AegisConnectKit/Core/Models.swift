#if os(iOS)
import Foundation

/// Signed credential returned after successful authentication.
public struct Credential: Codable {
    public let pubkey: String
    public let relay: URL
}

/// Error cases that may occur during the connect flow.
public enum AegisError: Error {
    case userCancelled
    case invalidParameter
    case unableToOpenAegis
    case verificationFailed
}

/// Redirect configuration containing x-callback parameters and a custom state provider.
public struct Redirect {
    public let source: String
    public let successScheme: String
    public let errorScheme: String
    public let stateProvider: () -> String

    public init(
        source: String,
        successScheme: String,
        errorScheme: String,
        stateProvider: @escaping () -> String = { UUID().uuidString }
    ) {
        self.source = source
        self.successScheme = successScheme
        self.errorScheme = errorScheme
        self.stateProvider = stateProvider
    }
}

// MARK: - CallbackStore

/// Stores pending continuations keyed by state so that async callers can be resumed on callback.
final class CallbackStore {
    static let shared = CallbackStore()
    private init() {}

    private var continuations: [String: (Result<Credential, Error>) -> Void] = [:]
    private let lock = NSLock()

    func register(state: String, _ continuation: @escaping (Result<Credential, Error>) -> Void) {
        lock.lock()
        continuations[state] = continuation
        lock.unlock()
    }

    func callback(for components: URLComponents) -> (() -> Void)? {
        guard let queryItems = components.queryItems,
              let state = queryItems.first(where: { $0.name == "state" })?.value else {
            return nil
        }

        lock.lock()
        guard let continuation = continuations[state] else {
            lock.unlock()
            return nil
        }
        continuations[state] = nil
        lock.unlock()

        let isSuccess = components.path.localizedCaseInsensitiveContains("Success")
        if isSuccess {
            // TODO: Parse credential fields from query parameters once spec is finalized.
            let credential = Credential(
                pubkey: "stub",
                relay: URL(string: "wss://relay.example.com")!
            )
            return { continuation(.success(credential)) }
        } else {
            let errorCode = queryItems.first(where: { $0.name == "errorCode" })?.value
            let error: AegisError = (errorCode == "USER_CANCEL") ? .userCancelled : .verificationFailed
            return { continuation(.failure(error)) }
        }
    }
}
#endif 