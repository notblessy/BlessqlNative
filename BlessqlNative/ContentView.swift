//
//  ContentView.swift
//  BlessqlNative
//
//  Created by Frederich Blessy on 01/06/24.
//

import SwiftUI

struct ContentView: View {
    let defaults = UserDefaults.standard
    
    @State private var selection = TaskSection.all
    @State private var allTasks = Task.examples()
    @State private var userCreatedGroups: [TaskGroup] = TaskGroup.examples()
    @State private var search: String = ""
    @State private var conn: String = ""
    
    
    var body: some View {
        NavigationSplitView {
            SidebarView(userCreatedGroups: $userCreatedGroups, selection: $selection)
                .searchable(text: $search)
        } detail: {
            if !conn.isEmpty {
                Text(conn)
            }
//            if search.isEmpty {
//                switch selection {
//                case .all:
//                    TaskListView(title: "All", tasks: $allTasks)
//                case .done:
//                    StaticTaskListView(title: "All", tasks: allTasks.filter({$0.isCompleted}))
//                case .upcoming:
//                    StaticTaskListView(title: "All", tasks: allTasks.filter({!$0.isCompleted}))
//                case .list(let taskGroup):
//                    StaticTaskListView(title: taskGroup.title, tasks: taskGroup.tasks)
//                }
//            } else {
//                StaticTaskListView(title: "All", tasks: allTasks.filter({$0.title.contains(search)}))
//            }
          
        }
        .onAppear {
            if let c = defaults.string(
                forKey: TemporaryStorage.activeConnection
            ) {
               conn = c
            }
        }
    }
}

#Preview {
    ContentView()
}
