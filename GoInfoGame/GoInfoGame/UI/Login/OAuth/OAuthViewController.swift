//
//  OAuthViewController.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 21/03/24.
//

import SwiftUI
import SafariServices
import osmapi

struct OAuthViewController: UIViewControllerRepresentable {
        
    private struct OAuthServer {
        let authURL: String
        let apiURL: String
        let client_id: String
    }
    
    private let servers: [OAuthServer] = [
        OAuthServer(authURL: "https://www.openstreetmap.org/",
                    apiURL: "https://api.openstreetmap.org/",
                    client_id: "oR9y-ytJ1O1OnM1hnPXc8WHjBwmephYdu3Az0a4rXNU"),
        
        OAuthServer(authURL: "https://master.apis.dev.openstreetmap.org/",
                    apiURL: "https://api06.dev.openstreetmap.org/",
                    client_id: "oR9y-ytJ1O1OnM1hnPXc8WHjBwmephYdu3Az0a4rXNU")
    ]

    private let client_secret = "eRY8q6sI5JDA3FU2iw5awIyXShuGUD6z2hL0YTNjfGg"
    private var server: OAuthServer { servers.first(where: { $0.apiURL == OSM_API_URL }) ?? servers[1] }
    var client_id: String { server.client_id }
    var serverURL: String { server.authURL }
    var oauthUrl: URL { return URL(string: serverURL)!.appendingPathComponent("oauth2") }
    
    private let redirect_uri = "goinfogame://oauth/callback"
    private let scope = "read_prefs write_prefs write_diary write_api write_notes write_redactions openid"
    
    let state = "random"
        
    func makeUIViewController(context: Context) ->  SFSafariViewController {
        let url = url(withPath: "authorize", with: [
            "client_id": client_id,
            "redirect_uri": redirect_uri,
            "response_type": "code",
            "scope": scope,
            "state": state
        ])
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        
    }
    
    func getAccessTokenFor(url: URL, completion: @escaping (String)-> Void) {
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
           // apiCallback(.failure(OAuthError.badRedirectURL(url.absoluteString)));
            //TODO: Handle error
            return
        }
        guard
            let code = components.queryItems?.first(where: { $0.name == "code" })?.value,
            let state = components.queryItems?.first(where: { $0.name == "state" })?.value
        else {
         //   handleError(from: components)
            return
        }
        guard state == self.state else {
           // apiCallback(.failure(OAuthError.stateMismatch))
            //TODO: Handle error
            return
        }
        fetchAccessTokenFor(authCode: code, completion: completion)
    }
    
    func fetchAccessTokenFor(authCode:String, completion: @escaping (String)-> Void) {
        let postingJSON = [
            "client_id": client_id,
            "redirect_uri": redirect_uri,
            "code": "\(authCode)",
            "grant_type": "authorization_code",
            "client_secret": client_secret,
        ]
        
        let postingBody  = query(postingJSON).data(using: .utf8, allowLossyConversion: false)
        
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
        let url: String = "https://master.apis.dev.openstreetmap.org/oauth2/token"
        let request: NSMutableURLRequest = NSMutableURLRequest()
        request.url = NSURL(string: url) as URL?
        request.httpMethod = "POST"
        //add params to request
        request.httpBody = postingBody
        let dataTask = session.dataTask(with: request as URLRequest) { (data: Data?, response:URLResponse?, error: Error?) -> Void in
            if((error) != nil) {
                print(error!.localizedDescription)
            } else {
                print("Succes:")
                do {
                    let parsedData = try JSONSerialization.jsonObject(with: data!, options: []) as! [String:Any]
                    if let theAccessToken = parsedData["access_token"] as? String {
                        let accessToken = theAccessToken
                      _ = KeychainManager.save(key: "accessToken", data: accessToken)
                        completion(accessToken)
                    }
                } catch let error as NSError {
                    print(error)
                }
            }
        }
        dataTask.resume()
        
    }
    
    public func query(_ parameters: [String: String]) -> String {
        var components: [(String, String)] = []
        
        for key in parameters.keys.sorted(by: <) {
            let value = parameters[key]!
            components += [(key, escape(value))]//queryComponents(fromKey: key, value: value)
        }

            return components.map { "\($0)=\($1)" }.joined(separator: "&")
        }
    
    /// Function that uri encodes strings
    ///
    /// - Parameter string: un encoded uri query parameter
    /// - Returns: encoded parameter
    public func escape(_ string: String) -> String {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="

        var allowedCharacterSet = CharacterSet.urlQueryAllowed
        allowedCharacterSet.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")

        var escaped = ""

        //==========================================================================================================
        //
        //  Batching is required for escaping due to an internal bug in iOS 8.1 and 8.2. Encoding more than a few
        //  hundred Chinese characters causes various malloc error crashes. To avoid this issue until iOS 8 is no
        //  longer supported, batching MUST be used for encoding. This introduces roughly a 20% overhead. For more
        //  info, please refer to:
        //
        //      - https://github.com/Alamofire/Alamofire/issues/206
        //
        //==========================================================================================================

        if #available(iOS 8.3, *) {
            escaped = string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? string
        } else {
            let batchSize = 50
            var index = string.startIndex

            while index != string.endIndex {
                let startIndex = index
                let endIndex = string.index(index, offsetBy: batchSize, limitedBy: string.endIndex) ?? string.endIndex
                let range = startIndex..<endIndex

                let substring = string.substring(with: range)

                escaped += substring.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? substring

                index = endIndex
            }
        }

        return escaped
    }
    
    private func url(withPath path: String, with dict: [String: String]) -> URL {
        var components = URLComponents(string: oauthUrl.appendingPathComponent(path).absoluteString)!
        components.queryItems = dict.map({ k, v in URLQueryItem(name: k, value: v) })
        return components.url!
    }
}

extension URL {
    var queryParameters: [String: String]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else {
            return nil
        }
        
        var parameters = [String: String]()
        queryItems.forEach { parameters[$0.name] = $0.value }
        return parameters
    }
}
