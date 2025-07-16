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
        clientPubKey: String,
        secret: String,
        redirect: Redirect,
        name: String? = nil,
        url: String = "",
        image: String = "",
        scheme: String? = nil
    ) async throws -> Credential {
        let state = redirect.stateProvider()
        let nostrConnectURI = NIP46Builder.createNostrConnectURI(
            clientPubKey: clientPubKey,
            secret: secret,
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
        // Wait for callback delivered through handleOpenURL(_:)
        return try await withCheckedThrowingContinuation { continuation in
            CallbackStore.shared.register(state: state) { result in
                continuation.resume(with: result)
            }
        }
    }

    @discardableResult
    public func handleOpenURL(_ url: URL) -> Bool {
        Logger.debug("Received URL: \(url.absoluteString)")
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            print("❌ Failed to create URLComponents from URL: \(url)")
            return false
        }
        
        print("🔍 URLComponents created successfully")
        print("  Path: \(components.path)")
        print("  Query items: \(components.queryItems?.map { "\($0.name)=\($0.value ?? "nil")" } ?? [])")
        
        guard let callback = CallbackStore.shared.callback(for: components) else {
            print("❌ No callback found for URL components")
            return false
        }
        
        print("✅ Callback found, executing...")
        callback()
        return true
    }
}
#endif 
