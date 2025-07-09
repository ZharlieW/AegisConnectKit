#if os(iOS)
import Foundation
import UIKit

public final class AegisConnectKit {
    /// Shared singleton instance
    public static let shared = AegisConnectKit()
    private init() {}

    /// Overridable async URL opener, defaulting to UIApplication.shared.open(_:)
    public var openURL: (URL) async -> Bool = { url in
        await UIApplication.shared.open(url)
    }

    /// Initiates NIP-46 authentication by launching Aegis via x-callback-url.
    /// - Parameters:
    ///   - redirect: Redirect configuration containing x-success / x-error schemes.
    ///   - scope: Requested permission scopes.
    ///   - presenter: A view controller that can be used to present fallback UI.
    /// - Returns: Credential on success or throws ``AegisError`` on failure.
    public func connect(
        redirect: Redirect,
        scope: [String],
        from presenter: UIViewController
    ) async throws -> Credential {
        // Generate random state to protect against CSRF
        let state = redirect.stateProvider()
        // Placeholder: Compose a minimal Nostr Connect URI. Real implementation should follow NIP-46 spec.
        let nostrConnectURI = "nostrconnect://dummy?state=\(state)"

        guard let aegisURL = URL.aegisCallbackURL(
            nostrConnectURI: nostrConnectURI,
            redirect: redirect
        ) else {
            throw AegisError.invalidParameter
        }

        Logger.debug("Opening Aegis: \(aegisURL.absoluteString)")

        let didOpen = await openURL(aegisURL)
        if !didOpen {
            throw AegisError.unableToOpenAegis
        }

        // Wait for callback delivered through ``handleOpenURL(_:)``
        return try await withCheckedThrowingContinuation { continuation in
            CallbackStore.shared.register(state: state) { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Initiates authentication with a pre-built NostrConnect URI.
    public func connect(
        nostrConnectURI: String,
        redirect: Redirect,
        scope: [String] = [],
        from presenter: UIViewController
    ) async throws -> Credential {
        let encoded = nostrConnectURI
        guard let aegisURL = URL.aegisCallbackURL(
            nostrConnectURI: encoded,
            redirect: redirect
        ) else {
            throw AegisError.invalidParameter
        }

        Logger.debug("Opening Aegis: \(aegisURL.absoluteString)")
        let didOpen = await openURL(aegisURL)
        if !didOpen {
            throw AegisError.unableToOpenAegis
        }

        // Extract state param from prebuilt URI if present; fall back to redirect.stateProvider()
        let state: String = {
            if let components = URLComponents(string: nostrConnectURI),
               let value = components.queryItems?.first(where: { $0.name == "state" })?.value {
                return value
            }
            return redirect.stateProvider()
        }()

        return try await withCheckedThrowingContinuation { continuation in
            CallbackStore.shared.register(state: state) { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Handles the callback URL received from Aegis (x-success / x-error).
    /// Forward the incoming URL from `SceneDelegate` or `AppDelegate`.
    @discardableResult
    public func handleOpenURL(_ url: URL) -> Bool {
        Logger.debug("Received URL: \(url.absoluteString)")
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let callback = CallbackStore.shared.callback(for: components) else {
            return false
        }
        callback()
        return true
    }
}
#endif 