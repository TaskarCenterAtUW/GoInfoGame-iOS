//
//  QParserExceptions.swift
//  QParser
//
//  Created by Naresh Devalapally on 12/31/23.
//

import Foundation

class ParseException : Error {
    let msg: String
    init(_ msg: String = "") {
        self.msg = msg
    }
}

class IllegalStateException : Error {
    let msg: String
    init(msg: String) {
        self.msg = msg
    }
}
