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
// Represents one stored way
class StoredChangeset: Object {
    @Persisted(primaryKey: true) var id: Int = 0 // Internal ID
    // Type of change -> can be node or way
    
    @Persisted var elementId: Int = 0 // The ID of the element
    @Persisted var tags = Map<String,String>()
    @Persisted var changesetId: Int = -1 // Initial value of changeset // To be figured out later as index
    @Persisted var timestamp : String = "" // User time stamp
}
