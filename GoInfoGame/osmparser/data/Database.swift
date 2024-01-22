//
//  Database.swift
//  QParser
//
//  Created by Naresh Devalapally on 1/15/24.
//
// Protocol for Database class to follow
import Foundation

protocol Database {
    func exec(sql:String, args: Array<Any>?)
    
    func rawQuery<T> (sql:String, args:[Any]?, transform:(CursorPosition) throws -> T) throws -> [T]
    
    func queryOne<T> (table:String, columns:[String]?, where: String? , args:[Any]?, groupBy: String?, having:String?, orderBy:String?, transform: (CursorPosition) throws -> T) -> T?
    func query<T> (table:String, columns:[String]?, where: String? , args:[Any]?, groupBy: String?, having:String?, orderBy:String?, limit: String? , distinct: Bool, transform: (CursorPosition) throws -> T)-> [T]
    
    func insert(table: String, values: [String:Any]?, conflictAlgorith: ConflictAlgorithm?) -> Int64
    
    func insertMany(table:String, columnNames:[String], valuesList:[Any]?, confilictAlgorithm: ConflictAlgorithm?) -> [Int64]
    
    func update(table:String, values:[String:Any]?, where:String?, args:[Any]?, conflictAlgorithm: ConflictAlgorithm?) -> Int
    
    func delete(table:String, where: String?, args:[Any]?) -> Int
    
    func transaction<T>(block: () -> T) -> T
}

extension Database {
    func insertOrIgnore(table: String, values:[String:Any]?) -> Int64 {
        insert(table: table, values: values, conflictAlgorith: .IGNORE)
    }
    
    func replace(table: String, values:[String:Any]?) -> Int64 {
        insert(table: table, values: values, conflictAlgorith: .REPLACE)
    }
    
    func insertOrIgnoreMany(table:String, columnNames:[String], valuesList:[Any]?) ->[Int64] {
        insertMany(table: table, columnNames: columnNames, valuesList: valuesList, confilictAlgorithm: .IGNORE)
    }
    
    func replaceMany(table:String, columnNames:[String], valuesList:[Any]?) ->[Int64] {
        insertMany(table: table, columnNames: columnNames, valuesList: valuesList, confilictAlgorithm: .REPLACE)
    }
}

public enum ConflictAlgorithm {
    case ROLLBACK
    case ABORT
    case FAIL
    case IGNORE
    case REPLACE
}

protocol CursorPosition {
    func getShort(columnName:String) -> Int16
    func getInt(columnName: String) -> Int
    func getLong(columnName: String) -> Int64
    func getDouble(columnName: String) -> Double
    func getFloat(columnName: String) -> Float
    func getBlob(columnName: String) -> Data
    func getString(columnName: String) -> String
    func getShortOrNull(columnName: String) -> Int16?
    func getIntOrNull(columnName: String) -> Int?
    func getLongOrNull(columnName: String) -> Int64?
    func getDoubleOrNull(columnName: String) -> Double?
    func getFloatOrNull(columnName: String) -> Float?
    func getBlobOrNull(columnName: String) -> Data?
    func getStringOrNull(columnName: String) -> String?
    
}
