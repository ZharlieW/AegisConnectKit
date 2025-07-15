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

    /// Auto-detect URL scheme from Bundle
    private static func autoDetectURLScheme() -> String? {
        guard let urlTypes = Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [[String: Any]] else {
            return nil
        }
        
        for item in urlTypes {
            if let schemes = item["CFBundleURLSchemes"] as? [String],
               let first = schemes.first(where: { !$0.isEmpty }) {
                return first
            }
        }
        return nil
    }

    /// Validate required parameters
    private static func validateParameters(clientPubKey: String, secret: String) throws {
        if clientPubKey.isEmpty {
            throw AegisError.invalidParameter("clientPubKey cannot be empty")
        }
        if secret.isEmpty {
            throw AegisError.invalidParameter("secret cannot be empty")
        }
        
        // Basic format validation for clientPubKey (should be a valid hex string)
        if !clientPubKey.matches(pattern: "^[0-9a-fA-F]{64}$") {
            throw AegisError.invalidParameter("clientPubKey should be a 64-character hex string")
        }
    }

    /// Convenient static method to start NIP-46 authentication flow with auto-configuration
    /// - Parameters:
    ///   - clientPubKey: Client's public key (64-character hex string)
    ///   - secret: Client's secret
    ///   - scheme: URL scheme for callback (optional, will auto-detect from Info.plist)
    ///   - name: App name (optional, will auto-detect from Bundle)
    ///   - url: App URL (optional)
    ///   - image: App image URL (optional)
    /// - Returns: Credential with callback information
    /// - Throws: AegisError for various error conditions
    public static func authenticate(
        clientPubKey: String,
        secret: String,
        scheme: String? = nil,
        name: String? = nil,
        url: String = "",
        image: String = ""
    ) async throws -> Credential {
        
        // Validate parameters
        try validateParameters(clientPubKey: clientPubKey, secret: secret)
        
        // Auto-detect scheme if not provided
        let resolvedScheme: String? = scheme ?? autoDetectURLScheme()
        
        guard let schemeValue = resolvedScheme else {
            throw AegisError.invalidParameter("No URL scheme found. Please add CFBundleURLSchemes to Info.plist")
        }
        
        // Auto-detect app name if not provided
        let appName = name ?? Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String 
            ?? Bundle.main.infoDictionary?["CFBundleName"] as? String 
            ?? "Unknown App"
        
        let redirect = Redirect(
            source: schemeValue,
            successScheme: "\(schemeValue)://x-callback-url/nip46AuthSuccess",
            errorScheme: "\(schemeValue)://x-callback-url/nip46AuthError"
        )
        
        return try await shared.connect(
            clientPubKey: clientPubKey,
            secret: secret,
            redirect: redirect,
            name: appName,
            url: url,
            image: image,
            scheme: schemeValue
        )
    }

    /// Enhanced connect method with better error handling
    public func connect(
        clientPubKey: String,
        secret: String,
        redirect: Redirect,
        name: String? = nil,
        url: String = "",
        image: String = "",
        scheme: String? = nil
    ) async throws -> Credential {
        
        // Validate redirect configuration
        guard !redirect.source.isEmpty else {
            throw AegisError.invalidParameter("Redirect source cannot be empty")
        }
        
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
            throw AegisError.invalidParameter("Failed to create Aegis callback URL")
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

    /// Enhanced URL handler with better error handling and logging
    @discardableResult
    public func handleOpenURL(_ url: URL) -> Bool {
        Logger.debug("Received URL: \(url.absoluteString)")
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            Logger.debug("Failed to parse URL components")
            return false
        }
        
        guard let callback = CallbackStore.shared.callback(for: components) else {
            Logger.debug("No callback found for URL: \(url.absoluteString)")
            return false
        }
        
        callback()
        return true
    }
}

// MARK: - String Extension for Validation
private extension String {
    func matches(pattern: String) -> Bool {
        return range(of: pattern, options: .regularExpression) != nil
    }
}

// MARK: - SwiftUI App Extension for Auto-Registration
#if canImport(SwiftUI)
import SwiftUI

@available(iOS 14.0, *)
public extension View {
    /// Automatically register Aegis callback handler
    func aegisCallbackHandler() -> some View {
        self.onOpenURL { url in
            AegisConnectKit.shared.handleOpenURL(url)
        }
    }
}

@available(iOS 14.0, *)
public extension App {
    /// Automatically register Aegis callback handler for the entire app
    func aegisCallbackHandler() -> some Scene {
        self.onOpenURL { url in
            AegisConnectKit.shared.handleOpenURL(url)
        }
    }
}
#endif
#endif 
