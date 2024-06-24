//
//  Connection.swift
//  BlessqlNative
//
//  Created by Frederich Blessy on 11/06/24.
//

import Foundation
import SwiftData

@Model
class Connection {
    let id =  UUID()
    var name: String
    var host: String
    var username: String
    var password: String
    var database: String
    let createdAt: Date
    
    init(name: String, host: String, username: String, password: String, database: String, createdAt: Date) {
        self.name = name
        self.host = host
        self.username = username
        self.password = password
        self.database = database
        self.createdAt = createdAt
    }
}
