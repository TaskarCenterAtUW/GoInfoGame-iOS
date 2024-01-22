////
////  SqliteDatabase.swift
////  QParser
////
////  Created by Naresh Devalapally on 1/15/24.
////
//
//import SQLite3
//
//import Foundation
//
//enum SQLiteError: Error {
//    case openFailed(msg: String)
//    case prepareFailed(msg: String)
//    case executeFailed(msg: String)
//    case bindFailed(msg: String)
//}
//
//// self implementation of sqlite database
//class SqliteDatabase: Database {
//    var db: OpaquePointer?
//    
//    init(path: String ) throws {
//        guard sqlite3_open(path, &db) == SQLITE_OK else{
//            throw SQLiteError.openFailed(msg: "Failed to open database at \(path)")
//        }
//    }
//    
//    func exec(sql: String, args: Array<Any>?) {
//        
//    }
//    
//    func rawQuery<T>(sql: String, args: [Any]?, transform: (CursorPosition) throws -> T) throws -> [T] {
//        <#code#>
//    }
//    
//    func queryOne<T>(table: String, columns: [String]?, where: String?, args: [Any]?, groupBy: String?, having: String?, orderBy: String?, transform: (CursorPosition) throws -> T) -> T? {
//        <#code#>
//    }
//    
//    func query<T>(table: String, columns: [String]?, where: String?, args: [Any]?, groupBy: String?, having: String?, orderBy: String?, limit: String?, distinct: Bool, transform: (CursorPosition) throws -> T) -> [T] {
//        <#code#>
//    }
//    
//    func insert(table: String, values: [String : Any]?, conflictAlgorith: ConflictAlgorithm?) -> Int64 {
//        <#code#>
//    }
//    
//    func insertMany(table: String, columnNames: [String], valuesList: [Any]?, confilictAlgorithm: ConflictAlgorithm?) -> [Int64] {
//        <#code#>
//    }
//    
//    func update(table: String, values: [String : Any]?, where: String?, args: [Any]?, conflictAlgorithm: ConflictAlgorithm?) -> Int {
//        <#code#>
//    }
//    
//    func delete(table: String, where: String?, args: [Any]?) -> Int {
//        <#code#>
//    }
//    
//    func transaction<T>(block: () -> T) -> T {
//        <#code#>
//    }
//    
//    
//}
