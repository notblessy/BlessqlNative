//
//  TaskListView.swift
//  BlessqlNative
//
//  Created by Frederich Blessy on 03/06/24.
//

import SwiftUI

struct TaskListView: View {
    let title: String
    
    @Binding var tasks: [Task]
    
    var body: some View {
        List($tasks) { $task in
           TaskView(task: $task)
        }
        .navigationTitle(title)
        .toolbar {
            Button {
                tasks.append(Task(title: "New Task"))
            } label: {
                Label("Add New Task", systemImage: "plus")
            }
        }
    }
}

#Preview {
    TaskListView(title: "All", tasks: .constant(Task.examples()))
}
