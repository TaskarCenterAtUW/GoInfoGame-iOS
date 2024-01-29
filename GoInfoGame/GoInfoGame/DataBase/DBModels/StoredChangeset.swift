//
//  StoredChangeset.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 1/29/24.
//
// Defines the changes applied to a single node/way elements
import Foundation

import RealmSwift
import osmparser

enum StoredElementEnum: String, PersistableEnum {
    case node
    case way
    case unknown
}

// Represents one stored way
class StoredChangeset: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString // Internal ID
    // Type of change -> can be node or way
    @Persisted var elementType : StoredElementEnum = .unknown
    @Persisted var elementId: String = "" // The ID of the element
    @Persisted var tags = Map<String,String>()
    @Persisted var changesetId: Int = -1 // Initial value of changeset // To be figured out later as index
    @Persisted var timestamp : String = "" // User time stamp
}
