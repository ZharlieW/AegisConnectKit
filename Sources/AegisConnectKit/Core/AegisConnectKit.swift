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

    /// Convenient static method to start NIP-46 authentication flow
    /// - Parameters:
    ///   - clientPubKey: Client's public key
    ///   - secret: Client's secret
    ///   - scheme: URL scheme for callback (optional, will auto-detect from Info.plist)
    ///   - perms: Permissions string (optional)
    ///   - name: App name (optional)
    ///   - url: App URL (optional)
    ///   - image: App image URL (optional)
    /// - Returns: Credential with callback information
    public static func authenticate(
        clientPubKey: String,
        secret: String,
        scheme: String? = nil,
        perms: String? = nil,
        name: String? = nil,
        url: String = "",
        image: String = ""
    ) async throws -> Credential {
        // Auto-detect scheme from Info.plist if not provided
        let resolvedScheme: String? = scheme ?? {
            if let urlTypes = Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [[String: Any]] {
                for item in urlTypes {
                    if let schemes = item["CFBundleURLSchemes"] as? [String],
                       let first = schemes.first(where: { !$0.isEmpty }) {
                        return first
                    }
                }
            }
            return nil
        }()
        
        guard let schemeValue = resolvedScheme else {
            throw AegisError.invalidParameter
        }
        
        let redirect = Redirect(
            source: schemeValue,
            successScheme: "\(schemeValue)://x-callback-url/nip46AuthSuccess",
            errorScheme: "\(schemeValue)://x-callback-url/nip46AuthError"
        )
        
        return try await shared.connect(
            clientPubKey: clientPubKey,
            secret: secret,
            redirect: redirect,
            perms: perms,
            name: name,
            url: url,
            image: image,
            scheme: schemeValue
        )
    }

    public func connect(
        clientPubKey: String,
        secret: String,
        redirect: Redirect,
        perms: String? = nil,
        name: String? = nil,
        url: String = "",
        image: String = "",
        scheme: String? = nil
    ) async throws -> Credential {
        let state = redirect.stateProvider()
        let nostrConnectURI = NIP46Builder.createNostrConnectURI(
            clientPubKey: clientPubKey,
            secret: secret,
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
        
        // Log the URL being sent to Aegis
        Logger.debug("Opening Aegis: \(aegisURL.absoluteString)")
        
        // Parse and log the x-success parameter being sent
        if let components = URLComponents(url: aegisURL, resolvingAgainstBaseURL: false),
           let xSuccessItem = components.queryItems?.first(where: { $0.name == "x-success" }) {
            // Store this information for later use in callback
            CallbackStore.shared.storeSentXSuccess(xSuccessItem.value)
        }
        
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
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return false
        }
        
        guard let callback = CallbackStore.shared.callback(for: components) else {
            return false
        }
        
        callback()
        return true
    }
}
#endif 
