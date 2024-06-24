//
//  BlessqlNativeApp.swift
//  BlessqlNative
//
//  Created by Frederich Blessy on 01/06/24.
//

import SwiftUI
import SwiftData

@main
struct BlessqlNativeApp: App {
    var body: some Scene {
        WindowGroup {
            ConnectionView()
                .padding(.top, -55)
        }
        .modelContainer(for: Connection.self)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandMenu("Task") {
                Button("Add New Task") {
                    
                }
                .keyboardShortcut(KeyEquivalent("r"), modifiers: .command)
            }
            
            CommandGroup(after: .newItem) {
                Button("Add New Group") {
                    
                }
                .keyboardShortcut(KeyEquivalent("a"), modifiers: .command)
            }
        }
    }
}
