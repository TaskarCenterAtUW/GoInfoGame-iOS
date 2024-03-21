//
//  OAuthService.swift
//  GoInfoGame
//
//  Created by Krishna Prakash on 20/11/23.
//

import Foundation
import SafariServices
import UIKit

// MARK: - Protocols
var OSM_API_URL = "https://api06.dev.openstreetmap.org/"

protocol OAuthService {
    func isAuthorized() -> Bool
    func removeAuthorization()
    func requestAccessFromUser(withVC vc: UIViewController, onComplete callback: @escaping (Result<Void, Error>) -> Void)
    func redirectHandler(url: URL, options: [UIApplication.OpenURLOptionsKey: Any])
    func urlRequest(url: URL) -> URLRequest?
    func urlRequest(string: String) -> URLRequest?
    func getUserDetails(callback: @escaping ([String: Any]?) -> Void)
}

protocol OAuthCallbackDelegate: AnyObject {
    func didCompleteAuthorization(result: Result<Void, Error>)
}

protocol OAuthURLProvider {
    var oauthUrl: URL { get }
    var client_id: String { get }
    var serverURL: String { get }
}

protocol AccessTokenProvider {
    func getAccessToken(for code: String)
}


// MARK: - Classes

class OAuth2: OAuthService, OAuthCallbackDelegate, OAuthURLProvider, AccessTokenProvider {
       
    
    // MARK: - Inner Types
    
    private struct OAuthServer {
        let authURL: String
        let apiURL: String
        let client_id: String
    }
    
    // MARK: - Constants
    
    private static let OAUTH_KEYCHAIN_IDENTIFIER = "OAuth_access_token"
    private static let redirect_uri = "goinfogame://oauth/callback"
    private static let scope = "read_prefs write_prefs write_diary write_api write_notes write_redactions openid"
      
    // MARK: - Properties
    
    private let servers: [OAuthServer] = [
        OAuthServer(authURL: "https://www.openstreetmap.org/",
                    apiURL: "https://api.openstreetmap.org/",
                    client_id: "oR9y-ytJ1O1OnM1hnPXc8WHjBwmephYdu3Az0a4rXNU"),
        
        OAuthServer(authURL: "https://master.apis.dev.openstreetmap.org/",
                    apiURL: "https://api06.dev.openstreetmap.org/",
                    client_id: "oR9y-ytJ1O1OnM1hnPXc8WHjBwmephYdu3Az0a4rXNU")
    ]
    
    private var safariVC: SFSafariViewController?
    private var state = ""
    private(set) var authorizationHeader: (name: String, value: String)?
    
    private var authCallback: ((Result<Void, Error>) -> Void)?
    
    // MARK: - Computed Properties
    
    private var server: OAuthServer { servers.first(where: { $0.apiURL == OSM_API_URL }) ?? servers[1] }
    var client_id: String { server.client_id }
    var serverURL: String { server.authURL }
    var oauthUrl: URL { return URL(string: serverURL)!.appendingPathComponent("oauth2") }
    
    // MARK: - Initialization
    
    init() {

    }
    
    // MARK: - Public Methods
    
    func isAuthorized() -> Bool {
        return authorizationHeader != nil
    }
    
    func removeAuthorization() {
        authorizationHeader = nil
    }
    
    func requestAccessFromUser(withVC vc: UIViewController, onComplete callback: @escaping (Result<Void, Error>) -> Void) {
        authCallback = callback
        let currentTimestampMilliseconds = Int64(Date().timeIntervalSince1970 * 1000)
        let uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        state = "\(currentTimestampMilliseconds)-\(uuid)"
        let url = url(withPath: "authorize", with: [
            "client_id": client_id,
            "redirect_uri": Self.redirect_uri,
            "response_type": "code",
            "scope": Self.scope,
            "state": state
        ])
        safariVC = SFSafariViewController(url: url)
        vc.present(safariVC!, animated: true)
//        if let url = URL(string: url.absoluteString) {
//            UIApplication.shared.open(url)
//        }
    }
    
    func redirectHandler(url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) {
        safariVC?.dismiss(animated: true)
        safariVC = nil
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            apiCallback(.failure(OAuthError.badRedirectURL(url.absoluteString)));
            return
        }
        guard
            let code = components.queryItems?.first(where: { $0.name == "code" })?.value,
            let state = components.queryItems?.first(where: { $0.name == "state" })?.value
        else {
            handleError(from: components)
            return
        }
        guard state == self.state else {
            apiCallback(.failure(OAuthError.stateMismatch))
            return
        }
        getAccessToken(for: code)
    }
    
    func urlRequest(url: URL) -> URLRequest? {
        guard let authorizationHeader = authorizationHeader else { return nil }
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = [
            authorizationHeader.name: authorizationHeader.value
        ]
        return request
    }
    
    func urlRequest(string: String) -> URLRequest? {
        guard let url = URL(string: string) else { return nil }
        return urlRequest(url: url)
    }
    
    func getUserDetails(callback: @escaping ([String: Any]?) -> Void) {
            let userDetailsEndpoint = "api/0.6/user/details.json"
            guard let userDetailsURL = URL(string: serverURL + userDetailsEndpoint),
                  let _ = urlRequest(url: userDetailsURL) else {
                callback(nil)
                return
            }

            URLSession.shared.performRequest(url: userDetailsURL) { result in
                DispatchQueue.main.async {
                    switch result {
                    case let .success(data):
                        self.handleUserDetailsResponse(data: data, callback: callback)
                    case let .failure(error):
                        print("Error fetching user details: \(error.localizedDescription)")
                        callback(nil)
                    }
                }
            }
        }

        // MARK: - Private Methods

        private func handleUserDetailsResponse(data: Data, callback: @escaping ([String: Any]?) -> Void) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let user = json["user"] as? [String: Any] {
                    callback(user)
                } else {
                    callback(nil)
                }
            } catch {
                print("Error parsing user details JSON: \(error.localizedDescription)")
                callback(nil)
            }
        }
    
    func apiCallback(_ result: Result<Void, Error>) {
        DispatchQueue.main.async {
            if case .failure = result {
                self.removeAuthorization()
            }
            self.authCallback?(result)
            self.authCallback = nil
        }
    }
    
    // MARK: - Private Methods
    
    private func setAuthorizationToken(token: String) {
        authorizationHeader = (name: "Authorization", value: "Bearer \(token)")
        //TODO: Store token securly in Keychain
        
    }
    
    private func url(withPath path: String, with dict: [String: String]) -> URL {
        var components = URLComponents(string: oauthUrl.appendingPathComponent(path).absoluteString)!
        components.queryItems = dict.map({ k, v in URLQueryItem(name: k, value: v) })
        return components.url!
    }
    
    private func handleError(from components: URLComponents) {
        if let message = components.queryItems?.first(where: { $0.name == "error_description" })?.value {
            let message = message.replacingOccurrences(of: "+", with: " ")
            apiCallback(.failure(OAuthError.errorMessage(message)))
        } else if let message = components.queryItems?.first(where: { $0.name == "error" })?.value {
            apiCallback(.failure(OAuthError.errorMessage(message)))
        } else {
            apiCallback(.failure(OAuthError.errorMessage("Unknown error during redirect")))
        }
    }
    
    func didCompleteAuthorization(result: Result<Void, Error>) {
        
    }
    
    func getAccessToken(for code: String) {
        
    }
}
