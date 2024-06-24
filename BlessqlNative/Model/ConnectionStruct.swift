//
//  Connection.swift
//  BlessqlNative
//
//  Created by Frederich Blessy on 07/06/24.
//

import Foundation

struct ConnectionStruct: Identifiable, Hashable {
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
    
    static func example() -> ConnectionStruct {
        return ConnectionStruct(name: "bagirata", host: "localhost", username: "root", password: "root", database: "bagirata", createdAt: Calendar.current.date(byAdding: .day, value: 2, to: Date())!)
    }
    
    static func examples() -> [ConnectionStruct] {
        let conn1 = ConnectionStruct(name: "bagirata", host: "localhost", username: "root", password: "root", database: "bagirata", createdAt: Calendar.current.date(byAdding: .day, value: 2, to: Date())!)
        let conn2 = ConnectionStruct(name: "keep", host: "localhost", username: "root", password: "", database: "keep_service", createdAt: Calendar.current.date(byAdding: .day, value: 2, to: Date())!)
        
        return [conn1, conn2]
    }
}
