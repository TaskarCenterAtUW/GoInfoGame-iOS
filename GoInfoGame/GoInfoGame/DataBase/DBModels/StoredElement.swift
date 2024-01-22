//
//  StoredElement.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 1/22/24.
//

import Foundation
import RealmSwift

// Base class for storing stuff. Not sure what @Persisted means
class StoredElement : Object {
    @Persisted(primaryKey: true) var id: Int = 0
    @Persisted var tags = Map<String,String>()
    @Persisted var version: Int = 0
}
