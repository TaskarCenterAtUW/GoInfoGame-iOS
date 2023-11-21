//
//  OAuthManager.swift
//  GoInfoGame
//
//  Created by Krishna Prakash on 20/11/23.
//

import Foundation
import SafariServices
import UIKit

class OAuthManager {

    // MARK: - Properties

    static let shared = OAuthManager()

    private var oAuth: OAuthService = OAuth2()

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    func isAuthorized() -> Bool {
        return oAuth.isAuthorized()
    }

    func removeAuthorization() {
        oAuth.removeAuthorization()
    }

    func requestAccessFromUser(withVC vc: UIViewController, onComplete callback: @escaping (Result<Void, Error>) -> Void) {
        oAuth.requestAccessFromUser(withVC: vc, onComplete: callback)
    }

    func redirectHandler(url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) {
        oAuth.redirectHandler(url: url, options: options)
    }

    func urlRequest(url: URL) -> URLRequest? {
        return oAuth.urlRequest(url: url)
    }

    func urlRequest(string: String) -> URLRequest? {
        return oAuth.urlRequest(string: string)
    }

    func getUserDetails(callback: @escaping ([String: Any]?) -> Void) {
        oAuth.getUserDetails(callback: callback)
    }
}

