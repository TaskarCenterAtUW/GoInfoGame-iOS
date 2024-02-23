//
//  RealmOPMeta.swift
//  GoInfoGame
//
//  Created by Krishna Prakash on 29/11/23.
//

import RealmSwift
//import SwiftOverpassAPI

class RealmOPMeta: Object {
    @objc dynamic var version: Int = 0
    @objc dynamic var timestamp: String = ""
    @objc dynamic var changeset: Int = 0
    @objc dynamic var userId: Int = 0
    @objc dynamic var username: String = ""
}
