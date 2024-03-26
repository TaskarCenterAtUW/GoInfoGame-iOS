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
    func fetchAccessTokenFor(authCode: String)
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
//
//class OAuth2: OAuthService, OAuthURLProvider, AccessTokenProvider {
//       
//    
//    // MARK: - Inner Types
//    
//    private struct OAuthServer {
//        let authURL: String
//        let apiURL: String
//        let client_id: String
//    }
//    
//    // MARK: - Constants
//    
//    private static let redirect_uri = "goinfogame://oauth/callback"
//    private static let scope = "read_prefs write_prefs write_diary write_api write_notes write_redactions openid"
//      
//    // MARK: - Properties
//    
//    private let servers: [OAuthServer] = [
//        OAuthServer(authURL: "https://www.openstreetmap.org/",
//                    apiURL: "https://api.openstreetmap.org/",
//                    client_id: "oR9y-ytJ1O1OnM1hnPXc8WHjBwmephYdu3Az0a4rXNU"),
//        
//        OAuthServer(authURL: "https://master.apis.dev.openstreetmap.org/",
//                    apiURL: "https://api06.dev.openstreetmap.org/",
//                    client_id: "oR9y-ytJ1O1OnM1hnPXc8WHjBwmephYdu3Az0a4rXNU")
//    ]
//    
//    private var safariVC: SFSafariViewController?
//    private var state = ""
//    private(set) var authorizationHeader: (name: String, value: String)?
//    
//    private var authCallback: ((Result<Void, Error>) -> Void)?
//    
//    // MARK: - Computed Properties
//    
//    private var server: OAuthServer { servers.first(where: { $0.apiURL == OSM_API_URL }) ?? servers[1] }
//    var client_id: String { server.client_id }
//    var serverURL: String { server.authURL }
//    var oauthUrl: URL { return URL(string: serverURL)!.appendingPathComponent("oauth2") }
//    
//    // MARK: - Initialization
//    
//    init() {
//
//    }
//    
//    // MARK: - Public Methods
//    
//    func isAuthorized() -> Bool {
//        return authorizationHeader != nil
//    }
//    
//    func removeAuthorization() {
//        authorizationHeader = nil
//    }
//    
//    func requestAccessFromUser(withVC vc: UIViewController, onComplete callback: @escaping (Result<Void, Error>) -> Void) {
//        authCallback = callback
//        let currentTimestampMilliseconds = Int64(Date().timeIntervalSince1970 * 1000)
//        let uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "")
//        state = "\(currentTimestampMilliseconds)-\(uuid)"
//        let url = url(withPath: "authorize", with: [
//            "client_id": client_id,
//            "redirect_uri": Self.redirect_uri,
//            "response_type": "code",
//            "scope": Self.scope,
//            "state": state
//        ])
//        safariVC = SFSafariViewController(url: url)
//        vc.present(safariVC!, animated: true)
////        if let url = URL(string: url.absoluteString) {
////            UIApplication.shared.open(url)
////        }
//    }
//    
//    func redirectHandler(url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) {
//        safariVC?.dismiss(animated: true)
//        safariVC = nil
//        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
//            apiCallback(.failure(OAuthError.badRedirectURL(url.absoluteString)));
//            return
//        }
//        guard
//            let code = components.queryItems?.first(where: { $0.name == "code" })?.value,
//            let state = components.queryItems?.first(where: { $0.name == "state" })?.value
//        else {
//            handleError(from: components)
//            return
//        }
//        guard state == self.state else {
//            apiCallback(.failure(OAuthError.stateMismatch))
//            return
//        }
//        getAccessToken(for: code)
//    }
//    
//    func fetchAccessTokenFor(authCode:String) {
//            let postingJSON = [
//                "client_id": "oR9y-ytJ1O1OnM1hnPXc8WHjBwmephYdu3Az0a4rXNU",
//                "redirect_uri": "goinfogame://oauth/callback",
//                "code": "\(authCode)",
//                "grant_type": "authorization_code",
//                "client_secret": "eRY8q6sI5JDA3FU2iw5awIyXShuGUD6z2hL0YTNjfGg",
//            ]
//        
//            let postingBody  = query(postingJSON).data(using: .utf8, allowLossyConversion: false)
//            
//            let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
//            let url: String = "https://master.apis.dev.openstreetmap.org/oauth2/token"//?client_id=oR9y-ytJ1O1OnM1hnPXc8WHjBwmephYdu3Az0a4rXNU&redirect_uri=goinfogame://oauth/callback&code=\(code)&grant_type=authorization_code&client_secret=eRY8q6sI5JDA3FU2iw5awIyXShuGUD6z2hL0YTNjfGg" //"https://master.apis.dev.openstreetmap.org/oauth2/token"
//            let request: NSMutableURLRequest = NSMutableURLRequest()
//            request.url = NSURL(string: url) as URL?
//            request.httpMethod = "POST"
//            //add params to request
//            request.httpBody = postingBody
//            let dataTask = session.dataTask(with: request as URLRequest) { (data: Data?, response:URLResponse?, error: Error?) -> Void in
//                if((error) != nil) {
//                    print(error!.localizedDescription)
//                } else {
//                    print("Succes:")
//                    do {
//
//                        let parsedData = try JSONSerialization.jsonObject(with: data!, options: []) as! [String:Any]
//                        if let theAccessToken = parsedData["access_token"] as? String {
//                            let accessToken = theAccessToken
//                            print(accessToken)
//                            self.setAuthorizationToken(token: accessToken)
//                           // NotificationCenter.default.post(name: NSNotification.Name.AuthNotification.didLogin, object: theAccessToken)
//                        }
//                    } catch let error as NSError {
//                        print(error)
//                        
//                        
//                    }
//
//                }
//            }
//            dataTask.resume()
//
//        }
//    
//    
//    public func query(_ parameters: [String: String]) -> String {
//            var components: [(String, String)] = []
//
//            for key in parameters.keys.sorted(by: <) {
//                let value = parameters[key]!
//                components += [(key, escape(value))]//queryComponents(fromKey: key, value: value)
//            }
//
//            return components.map { "\($0)=\($1)" }.joined(separator: "&")
//        }
//
//        /// Function that uri encodes strings
//        ///
//        /// - Parameter string: un encoded uri query parameter
//        /// - Returns: encoded parameter
//        public func escape(_ string: String) -> String {
//            let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
//            let subDelimitersToEncode = "!$&'()*+,;="
//
//            var allowedCharacterSet = CharacterSet.urlQueryAllowed
//            allowedCharacterSet.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
//
//            var escaped = ""
//
//            //==========================================================================================================
//            //
//            //  Batching is required for escaping due to an internal bug in iOS 8.1 and 8.2. Encoding more than a few
//            //  hundred Chinese characters causes various malloc error crashes. To avoid this issue until iOS 8 is no
//            //  longer supported, batching MUST be used for encoding. This introduces roughly a 20% overhead. For more
//            //  info, please refer to:
//            //
//            //      - https://github.com/Alamofire/Alamofire/issues/206
//            //
//            //==========================================================================================================
//
//            if #available(iOS 8.3, *) {
//                escaped = string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? string
//            } else {
//                let batchSize = 50
//                var index = string.startIndex
//
//                while index != string.endIndex {
//                    let startIndex = index
//                    let endIndex = string.index(index, offsetBy: batchSize, limitedBy: string.endIndex) ?? string.endIndex
//                    let range = startIndex..<endIndex
//
//                    let substring = string.substring(with: range)
//
//                    escaped += substring.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? substring
//
//                    index = endIndex
//                }
//            }
//
//            return escaped
//        }
//    
//    
//    func urlRequest(url: URL) -> URLRequest? {
//        guard let authorizationHeader = authorizationHeader else { return nil }
//        var request = URLRequest(url: url)
//        request.allHTTPHeaderFields = [
//            authorizationHeader.name: authorizationHeader.value
//        ]
//        return request
//    }
//    
//    func urlRequest(string: String) -> URLRequest? {
//        guard let url = URL(string: string) else { return nil }
//        return urlRequest(url: url)
//    }
//    
//    func getUserDetails(callback: @escaping ([String: Any]?) -> Void) {
//            let userDetailsEndpoint = "api/0.6/user/details.json"
//            guard let userDetailsURL = URL(string: serverURL + userDetailsEndpoint),
//                  let _ = urlRequest(url: userDetailsURL) else {
//                callback(nil)
//                return
//            }
//
//            URLSession.shared.performRequest(url: userDetailsURL) { result in
//                DispatchQueue.main.async {
//                    switch result {
//                    case let .success(data):
//                        self.handleUserDetailsResponse(data: data, callback: callback)
//                    case let .failure(error):
//                        print("Error fetching user details: \(error.localizedDescription)")
//                        callback(nil)
//                    }
//                }
//            }
//        }
//
//        // MARK: - Private Methods
//
//        private func handleUserDetailsResponse(data: Data, callback: @escaping ([String: Any]?) -> Void) {
//            do {
//                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
//                   let user = json["user"] as? [String: Any] {
//                    callback(user)
//                } else {
//                    callback(nil)
//                }
//            } catch {
//                print("Error parsing user details JSON: \(error.localizedDescription)")
//                callback(nil)
//            }
//        }
//    
//    func apiCallback(_ result: Result<Void, Error>) {
//        DispatchQueue.main.async {
//            if case .failure = result {
//                self.removeAuthorization()
//            }
//            self.authCallback?(result)
//            self.authCallback = nil
//        }
//    }
//    
//    // MARK: - Private Methods
//    
//    private func setAuthorizationToken(token: String) {
//        authorizationHeader = (name: "Authorization", value: "Bearer \(token)")
//        //TODO: Store token securly in Keychain
//        
//    }
//    
//    private func url(withPath path: String, with dict: [String: String]) -> URL {
//        var components = URLComponents(string: oauthUrl.appendingPathComponent(path).absoluteString)!
//        components.queryItems = dict.map({ k, v in URLQueryItem(name: k, value: v) })
//        return components.url!
//    }
//    
//    private func handleError(from components: URLComponents) {
//        if let message = components.queryItems?.first(where: { $0.name == "error_description" })?.value {
//            let message = message.replacingOccurrences(of: "+", with: " ")
//            apiCallback(.failure(OAuthError.errorMessage(message)))
//        } else if let message = components.queryItems?.first(where: { $0.name == "error" })?.value {
//            apiCallback(.failure(OAuthError.errorMessage(message)))
//        } else {
//            apiCallback(.failure(OAuthError.errorMessage("Unknown error during redirect")))
//        }
//    }
//    
//    func getAccessToken(for code: String) {
//        fetchAccessTokenFor(authCode: code)
//    }
//}
