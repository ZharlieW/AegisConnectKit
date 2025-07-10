#if os(iOS)
import Foundation
import UIKit

@MainActor
public final class AegisConnectKit {
    public static let shared = AegisConnectKit()
    private init() {}

    public var openURL: (URL) async -> Bool = { url in
        await UIApplication.shared.open(url)
    }

    public func connect(
        redirect: Redirect,
        perms: String? = nil,
        name: String? = nil,
        url: String = "",
        image: String = "",
        scheme: String? = nil
    ) async throws -> Credential {
        let state = redirect.stateProvider()
        let (nostrConnectURI, _, _, _) = NIP46Builder.createNostrConnectURI(
            perms: perms,
            name: name,
            url: url,
            image: image,
            scheme: scheme
        )
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
