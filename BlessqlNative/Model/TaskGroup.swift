//
//  TaskGroup.swift
//  BlessqlNative
//
//  Created by Frederich Blessy on 01/06/24.
//

import Foundation

struct TaskGroup: Identifiable, Hashable {
    let id =  UUID()
    var title: String
    let createdAt: Date
    var tasks: [Task]
    
    init(title: String, tasks: [Task] = []) {
        self.title = title
        self.createdAt = Date()
        self.tasks = tasks
    }
    
    static func example() -> TaskGroup {
        let task1 = Task(title: "Doing some chores")
        let task2 = Task(title: "Edit video camping")
        let task3 = Task(title: "Service outlander")
        
        var group = TaskGroup(title: "Today Personal")
        group.tasks = [task1, task2, task3]
        
        return group
    }
    
    static func examples() -> [TaskGroup] {
        let group1 = TaskGroup.example()
        let group2 = TaskGroup(title: "Tomorrow tasks")
        
        return [group1, group2]
    }
}
