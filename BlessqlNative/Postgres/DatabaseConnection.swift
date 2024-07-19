//
//  Connection.swift
//  BlessqlNative
//
//  Created by Frederich Blessy on 23/06/24.
//

import Foundation
import PostgresClientKit

enum DatabaseConnectionError: Error {
    case connectionFailed(Error)
}

func connectPostgres(host: String, database: String, user: String, password: String) -> PostgresClientKit.Connection? {
    do {
        var configuration = PostgresClientKit.ConnectionConfiguration()
        configuration.host = host
        configuration.database = database
        configuration.user = user
        configuration.credential = .md5Password(password: password)
        configuration.ssl = false
        
        let connection = try PostgresClientKit.Connection(configuration: configuration)
        
        return connection
    } catch {
        print("Error connecting to the database: \(error)")
        return nil
    }
}

func performTestConnection(host: String, database: String, user: String, password: String) -> String? {
    do {
        var configuration = PostgresClientKit.ConnectionConfiguration()
        configuration.host = host
        configuration.database = database
        configuration.user = user
        configuration.credential = .md5Password(password: password)
        configuration.ssl = false
        
        let connection = try PostgresClientKit.Connection(configuration: configuration)
        
        defer { connection.close() }
        
        // Execute a simple query to test the connection
        let statement = try connection.prepareStatement(text: "SELECT 1")
        defer { statement.close() }
        
        _ = try statement.execute()
        
        return nil
    } catch let error as PostgresClientKit.PostgresError {
        switch error {
        case .sqlError(notice: let notice):
            return notice.message
        default:
            return "Unknown connection error: \(error)"
        }
    } catch {
        return "Unknown connection error: \(error)"
    }
}
