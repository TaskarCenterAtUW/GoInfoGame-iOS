//
//  OSMElement.swift
//  osmapi
//
//  Created by Lakshmi Shweta Pochiraju on 14/02/24.
//

import Foundation
// A protocol that defines all the properties shared by nodes, ways, and relations
public protocol OSMElement {
    var id: Int { get } // The element's identifier
    var tags: [String: String] { get } // Tags that add additional details
    var isInteresting: Bool? { get } // Does the element have one or more interesting tags?
    var timestamp: Date { get }
    var version : Int { get set }
    var changeset: Int { get set }
    var user: String { get }
    // If the element will be rendered as part of a parent element it does not need to be rendered individually
    var isSkippable: Bool? { get set }
}
