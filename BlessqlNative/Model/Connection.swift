//
//  Connection.swift
//  BlessqlNative
//
//  Created by Frederich Blessy on 11/06/24.
//

import Foundation
import SwiftData

@Model
class Connection: Codable {
    let id =  UUID()
    var name: String
    var host: String
    var username: String
    var password: String
    var database: String
    let createdAt: Date
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case host
        case username
        case password
        case database
        case createdAt
    }
    
    init(name: String, host: String, username: String, password: String, database: String, createdAt: Date) {
        self.name = name
        self.host = host
        self.username = username
        self.password = password
        self.database = database
        self.createdAt = createdAt
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        host = try container.decode(String.self, forKey: .host)
        username = try container.decode(String.self, forKey: .username)
        password = try container.decode(String.self, forKey: .password)
        database = try container.decode(String.self, forKey: .database)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(host, forKey: .host)
        try container.encode(username, forKey: .username)
        try container.encode(password, forKey: .password)
        try container.encode(database, forKey: .database)
        try container.encode(createdAt, forKey: .createdAt)
    }
    
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    func toStringJSON() -> String? {
        if let jsonData = try? Connection.encoder.encode(self) {
            return String(data: jsonData, encoding: .utf8)
        }
        return nil
    }
        
    static func parseJSON(_ jsonString: String) -> Connection? {
        if let jsonData = jsonString.data(using: .utf8) {
            return try? Connection.decoder.decode(Connection.self, from: jsonData)
        }
        
        return nil
    }
}


