//
//  Task.swift
//  BlessqlNative
//
//  Created by Frederich Blessy on 01/06/24.
//

import Foundation

struct Task: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var isCompleted: Bool
    var dueDate: Date
    var details: String?
    
    init(title: String, isCompleted: Bool = false, dueDate: Date = Date(), details: String? = nil) {
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.details = details
    }
    
    static func example() -> Task {
        Task(title: "Learn Coding", dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())!)
    }
    
    static func examples () -> [Task] {
        [
            Task(title: "Buying stuff for shaburi"),
            Task(title: "Coding bikinota", isCompleted: true),
            Task(title: "Taking note for bugs", details: "dari mana aja"),
        ]
    }
}
