#if os(iOS)
import Foundation

/// Signed credential returned after successful authentication.
public struct Credential: Codable {
    public let callbackURL: String
    public let fullCallbackURL: String
    public let queryParameters: [String: String]
    
    public init(callbackURL: String, fullCallbackURL: String, queryParameters: [String: String]) {
        self.callbackURL = callbackURL
        self.fullCallbackURL = fullCallbackURL
        self.queryParameters = queryParameters
    }
}

/// Error cases that may occur during the connect flow.
public enum AegisError: Error, LocalizedError {
    case userCancelled
    case invalidParameter
    case unableToOpenAegis
    case verificationFailed
    
    public var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "User cancelled the authentication"
        case .invalidParameter:
            return "Invalid parameter"
        case .unableToOpenAegis:
            return "Unable to open Aegis app. Please make sure Aegis is installed"
        case .verificationFailed:
            return "Authentication verification failed"
        }
    }
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
        guard let queryItems = components.queryItems else {
            return nil
        }
        
        // First try to find state parameter (original approach)
        if let state = queryItems.first(where: { $0.name == "state" })?.value {
            return findAndExecuteCallback(for: state, queryItems: queryItems, fullURL: components.url?.absoluteString ?? "")
        }
        
        // If no state parameter, try to find any callback (Aegis approach)
        lock.lock()
        guard let (state, continuation) = continuations.first else {
            lock.unlock()
            return nil
        }
        continuations[state] = nil
        lock.unlock()

        let isSuccess = components.path.localizedCaseInsensitiveContains("Success")
        
        if isSuccess {
            let credential = parseCredentialFromQueryItems(queryItems, fullURL: components.url?.absoluteString ?? "")
            return { continuation(.success(credential)) }
        } else {
            let errorCode = queryItems.first(where: { $0.name == "errorCode" })?.value
            let error: AegisError = (errorCode == "USER_CANCEL") ? .userCancelled : .verificationFailed
            return { continuation(.failure(error)) }
        }
    }
    
    private func findAndExecuteCallback(for state: String, queryItems: [URLQueryItem], fullURL: String) -> (() -> Void)? {
        lock.lock()
        guard let continuation = continuations[state] else {
            lock.unlock()
            return nil
        }
        continuations[state] = nil
        lock.unlock()
        
        let credential = parseCredentialFromQueryItems(queryItems, fullURL: fullURL)
        return { continuation(.success(credential)) }
    }
    
    private func parseCredentialFromQueryItems(_ queryItems: [URLQueryItem], fullURL: String) -> Credential {
        let queryParams = queryItems.reduce(into: [String: String]()) { result, item in
            result[item.name] = item.value
        }
        
        return Credential(
            callbackURL: "success",
            fullCallbackURL: fullURL,
            queryParameters: queryParams
        )
    }
}
#endif 